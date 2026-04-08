import Foundation
import RealityKit
import SwiftUI
import AppKit

// MARK: - Shader model enum

enum LightingModel: String, CaseIterable, Identifiable {
    case blinn       = "Blinn"
    case phong       = "Phong"
    case gooch       = "Gooch"
    case edgefuzz    = "EdgeFuzz"
    case glossywet   = "GlossyWet"
    case hemisphere  = "Hemisphere"
    case lambskin    = "LambSkin"
    case lutskin     = "LUTSkin"
    case thinfilm    = "ThinFilm"
    case envmap      = "EnvMap"
    case velvet      = "Velvet"

    var id: String { rawValue }

    var functionName: String {
        switch self {
        case .blinn:      return "shader_blinn"
        case .phong:      return "shader_phong"
        case .gooch:      return "shader_gooch"
        case .edgefuzz:   return "shader_edgefuzz"
        case .glossywet:  return "shader_glossywet"
        case .hemisphere: return "shader_hemisphere"
        case .lambskin:   return "shader_lambskin"
        case .lutskin:    return "shader_lutskin"
        case .thinfilm:   return "shader_thinfilm"
        case .envmap:     return "shader_envmap"
        case .velvet:     return "shader_velvet"
        }
    }

    /// Whether this shader uses an auxiliary image texture
    var usesAuxImage: Bool {
        switch self {
        case .lutskin, .thinfilm, .envmap: return true
        default: return false
        }
    }
}

// MARK: - Per-shader parameter state

struct ShaderParams: Equatable {
    // Shared color controls (mapped to custom_parameter and material_constants)
    var color1: SIMD3<Float>    // primary light / warm / sky / diff color
    var color2: SIMD3<Float>    // secondary ambient / cool / ground color
    var float1: Float           // shininess / rolloff / filmDepth / etc.
    var float2: Float           // specular / diffCool / glossSpec / envRatio / etc.
    var float3: Float           // glossDrop / edgeFuzziness / etc.
    var auxImageURL: URL?       // optional aux texture (LUTSkin / ThinFilm / EnvMap)

    init(color1: SIMD3<Float>, color2: SIMD3<Float>,
         float1: Float, float2: Float, float3: Float, auxImageURL: URL? = nil) {
        self.color1 = color1
        self.color2 = color2
        self.float1 = float1
        self.float2 = float2
        self.float3 = float3
        self.auxImageURL = auxImageURL
    }

    static func defaults(for model: LightingModel) -> ShaderParams {
        switch model {
        case .blinn:
            return ShaderParams(color1: [1, 0.9, 0.7], color2: [0,0,0], float1: 0, float2: 0, float3: 0)
        case .phong:
            return ShaderParams(color1: [1, 0.9, 0.7], color2: [0.1, 0.1, 0.2], float1: 32, float2: 0.5, float3: 0)
        case .gooch:
            return ShaderParams(color1: [0.8, 0.6, 0.2], color2: [0.2, 0.3, 0.8], float1: 0.4, float2: 0.4, float3: 0)
        case .edgefuzz:
            return ShaderParams(color1: [1, 1, 1], color2: [0.2, 0.5, 0.9], float1: 12, float2: 2.0, float3: 0.8)
        case .glossywet:
            return ShaderParams(color1: [1, 1, 1], color2: [0.4, 0.6, 0.8], float1: 64, float2: 0.8, float3: 0.2)
        case .hemisphere:
            return ShaderParams(color1: [0.4, 0.6, 1.0], color2: [0.3, 0.2, 0.1], float1: 0, float2: 0, float3: 0)
        case .lambskin:
            return ShaderParams(color1: [0.8, 0.5, 0.4], color2: [0.1, 0.05, 0.05], float1: 0.5, float2: 0, float3: 0)
        case .lutskin:
            return ShaderParams(color1: [0.9, 0.7, 0.6], color2: [1, 1, 1], float1: 0, float2: 0, float3: 0)
        case .thinfilm:
            return ShaderParams(color1: [0,0,0], color2: [0,0,0], float1: 0.5, float2: 0, float3: 0)
        case .envmap:
            return ShaderParams(color1: [1, 0.95, 0.8], color2: [0,0,0], float1: 0, float2: 0.6, float3: 0)
        case .velvet:
            return ShaderParams(color1: [0.6, 0.1, 0.8], color2: [0,0,0], float1: 0.5, float2: 0, float3: 0)
        }
    }
}

// MARK: - Material factory

@MainActor
final class MaterialFactory {
    static let shared = MaterialFactory()

    private let library: MTLLibrary

    /// Cache of base CustomMaterial per shader model.
    /// Creating CustomMaterial(from:surfaceShader:) compiles a new pipeline — expensive.
    /// We do it once per shader, then clone + mutate params for updates.
    private var baseCache: [LightingModel: CustomMaterial] = [:]

    private init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("No Metal device")
        }
        // Use the bundle's default.metallib compiled from our .metal sources
        guard let lib = device.makeDefaultLibrary() else {
            fatalError("Failed to load default Metal library — check that LightingShaders.metal compiled")
        }
        library = lib
    }

    /// Synchronous material build — clones cached base, packs params. No texture loading.
    func materialSync(for model: LightingModel, params: ShaderParams) throws -> CustomMaterial {
        var mat = try cachedBase(for: model)
        packParams(params: params, to: &mat, model: model, auxTex: nil)
        return mat
    }

    /// Async material build — clones cached base, loads aux texture if needed.
    func material(for model: LightingModel, params: ShaderParams) async throws -> CustomMaterial {
        var mat = try cachedBase(for: model)
        var auxTex: CustomMaterial.Texture? = nil
        if let url = params.auxImageURL {
            let resource = try TextureResource.load(contentsOf: url)
            auxTex = CustomMaterial.Texture(resource)
        }
        packParams(params: params, to: &mat, model: model, auxTex: auxTex)
        return mat
    }

    /// Returns a copy of the cached base material for the given shader.
    /// The base is created once (compiling the pipeline), then struct-copied on subsequent calls.
    private func cachedBase(for model: LightingModel) throws -> CustomMaterial {
        if let cached = baseCache[model] {
            return cached  // struct copy — no pipeline recompilation
        }
        let surfaceShader = CustomMaterial.SurfaceShader(
            named: model.functionName,
            in: library
        )
        let base = try CustomMaterial(from: PhysicallyBasedMaterial(), surfaceShader: surfaceShader)
        baseCache[model] = base
        return base
    }

    private func packParams(params: ShaderParams, to mat: inout CustomMaterial, model: LightingModel, auxTex: CustomMaterial.Texture?) {
        // Pack into custom_parameter (float4) and material_constants
        switch model {
        case .blinn:
            mat.custom.value = SIMD4(params.color1.x, params.color1.y, params.color1.z, 0)

        case .phong:
            mat.custom.value = SIMD4(params.color1.x, params.color1.y, params.color1.z, params.float1)
            mat.baseColor.tint = .init(red: CGFloat(params.color2.x),
                                       green: CGFloat(params.color2.y),
                                       blue: CGFloat(params.color2.z), alpha: 1)
            mat.roughness.scale = params.float2

        case .gooch:
            mat.custom.value = SIMD4(params.color1.x, params.color1.y, params.color1.z, params.float1)
            mat.baseColor.tint = .init(red: CGFloat(params.color2.x),
                                       green: CGFloat(params.color2.y),
                                       blue: CGFloat(params.color2.z), alpha: 1)
            mat.roughness.scale = params.float2

        case .edgefuzz:
            mat.custom.value = SIMD4(params.float1, params.float2, params.float3, 0)
            mat.baseColor.tint = .init(red: CGFloat(params.color1.x),
                                       green: CGFloat(params.color1.y),
                                       blue: CGFloat(params.color1.z), alpha: 1)
            mat.emissiveColor.color = .init(red: CGFloat(params.color2.x),
                                            green: CGFloat(params.color2.y),
                                            blue: CGFloat(params.color2.z), alpha: 1)

        case .glossywet:
            mat.custom.value = SIMD4(params.float1, params.float2, params.float3, 0)
            mat.baseColor.tint = .init(red: CGFloat(params.color1.x),
                                       green: CGFloat(params.color1.y),
                                       blue: CGFloat(params.color1.z), alpha: 1)
            mat.emissiveColor.color = .init(red: CGFloat(params.color2.x),
                                            green: CGFloat(params.color2.y),
                                            blue: CGFloat(params.color2.z), alpha: 1)
            mat.roughness.scale = 0.9       // glossMax
            mat.metallic.scale  = 0.1       // glossMin

        case .hemisphere:
            mat.custom.value = SIMD4(params.color1.x, params.color1.y, params.color1.z, 0)
            mat.baseColor.tint = .init(red: CGFloat(params.color2.x),
                                       green: CGFloat(params.color2.y),
                                       blue: CGFloat(params.color2.z), alpha: 1)

        case .lambskin:
            mat.custom.value = SIMD4(params.float1, params.color1.x, params.color1.y, params.color1.z)
            mat.baseColor.tint = .init(red: CGFloat(params.color2.x),
                                       green: CGFloat(params.color2.y),
                                       blue: CGFloat(params.color2.z), alpha: 1)

        case .lutskin:
            // custom.x/y/z = diff color, custom.texture = LUT image
            mat.custom.value = SIMD4(params.color1.x, params.color1.y, params.color1.z, 0)
            mat.baseColor.tint = .init(red: CGFloat(params.color2.x),
                                       green: CGFloat(params.color2.y),
                                       blue: CGFloat(params.color2.z), alpha: 1)
            mat.custom.texture = auxTex

        case .thinfilm:
            // custom.x = filmDepth, custom.texture = fringe map
            mat.custom.value = SIMD4(params.float1, 0, 0, 0)
            mat.custom.texture = auxTex

        case .envmap:
            // custom.x/y/z = light color, custom.w = envRatio, custom.texture = env image
            mat.custom.value = SIMD4(params.color1.x, params.color1.y, params.color1.z, params.float2)
            mat.custom.texture = auxTex

        case .velvet:
            mat.custom.value = SIMD4(params.float1, params.color1.x, params.color1.y, params.color1.z)
        }
    }
}
