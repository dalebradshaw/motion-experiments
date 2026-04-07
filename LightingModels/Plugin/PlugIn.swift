import Foundation
import Metal
import FxPlug

// MARK: - Shader IDs

enum ShaderID: Int {
    case blinn            = 0
    case phong            = 1
    case gooch            = 2
    case edgeFuzz         = 3
    case glossyWet        = 4
    case hemisphere       = 5
    case lambSkin         = 6
    case lutSkin          = 7
    case thinFilm         = 8
    case envMap           = 9
    case velvet           = 10
}

// Parameter IDs — must be in [1, 9998], grouped by 100 per shader
//
//  1–9    global
//  101–   Blinn
//  201–   Phong
//  301–   Gooch
//  401–   EdgeFuzz
//  501–   GlossyWet
//  601–   Hemisphere
//  701–   LambSkin
//  801–   LUTSkin
//  901–   ThinFilm
//  1001–  EnvMap
//  1101–  Velvet

let kParamShaderSelect: UInt32 = 1

// Blinn
let kParamBlinnLightR: UInt32     = 101
let kParamBlinnLightG: UInt32     = 102
let kParamBlinnLightB: UInt32     = 103

// Phong
let kParamPhongShininess: UInt32  = 201
let kParamPhongSpecular: UInt32   = 202
let kParamPhongAmbR: UInt32       = 203
let kParamPhongAmbG: UInt32       = 204
let kParamPhongAmbB: UInt32       = 205

// Gooch
let kParamGoochWarmR: UInt32      = 301
let kParamGoochWarmG: UInt32      = 302
let kParamGoochWarmB: UInt32      = 303
let kParamGoochCoolR: UInt32      = 304
let kParamGoochCoolG: UInt32      = 305
let kParamGoochCoolB: UInt32      = 306
let kParamGoochDiffWarm: UInt32   = 307
let kParamGoochDiffCool: UInt32   = 308

// EdgeFuzz
let kParamEdgeSpecularity: UInt32 = 401
let kParamEdgeFuzziness: UInt32   = 402
let kParamEdgeFadeAmt: UInt32     = 403

// GlossyWet
let kParamGlossSpecExp: UInt32    = 501
let kParamGlossSpec: UInt32       = 502
let kParamGlossMax: UInt32        = 503
let kParamGlossMin: UInt32        = 504
let kParamGlossDrop: UInt32       = 505

// Hemisphere (no extra params beyond light pos which is implicit)

// LambSkin
let kParamLambRolloff: UInt32     = 701

// LUTSkin (no float params — needs texture, handled as passthrough)

// ThinFilm
let kParamThinFilmDepth: UInt32   = 901

// EnvMap
let kParamEnvRatio: UInt32        = 1001

// Velvet
let kParamVelvetRolloff: UInt32   = 1101

// MARK: - Plug-in State (passed render thread → CPU)

struct LightingPluginState {
    var shaderIndex: Int32
    // Light
    var lightR: Float; var lightG: Float; var lightB: Float
    // Blinn
    // (uses light color above)
    // Phong
    var shininess: Float; var specular: Float
    var ambR: Float; var ambG: Float; var ambB: Float
    // Gooch
    var warmR: Float; var warmG: Float; var warmB: Float
    var coolR: Float; var coolG: Float; var coolB: Float
    var diffWarm: Float; var diffCool: Float
    // EdgeFuzz
    var edgeSpecularity: Float; var edgeFuzziness: Float; var edgeFade: Float
    // GlossyWet
    var glossSpecExp: Float; var glossSpec: Float
    var glossMax: Float; var glossMin: Float; var glossDrop: Float
    // LambSkin
    var lambRolloff: Float
    // ThinFilm
    var filmDepth: Float
    // EnvMap
    var envRatio: Float
    // Velvet
    var velvetRolloff: Float
}

// MARK: - Plugin

@objc(LightingModelsPlugIn)
class LightingModelsPlugIn: NSObject, FxTileableEffect {

    let _apiManager: PROAPIAccessing

    required init?(apiManager: PROAPIAccessing) {
        _apiManager = apiManager
    }

    // MARK: Parameters

    func addParameters() throws {
        let p = _apiManager.api(for: FxParameterCreationAPI_v5.self) as! FxParameterCreationAPI_v5

        let def = FxParameterFlags(kFxParameterFlag_DEFAULT)

        // Shader selector
        let shaderNames = ["Blinn", "Phong Point Light", "Gooch", "Edge Fuzz",
                           "Glossy Wet Highlight", "Hemisphere", "Lamb Skin",
                           "LUT Skin", "Thin Film", "Environment Map", "Velvet"]
        p.addPopupMenu(withName: "Shader Model", parameterID: kParamShaderSelect,
                       defaultValue: 1,
                       menuEntries: shaderNames,
                       parameterFlags: def)

        // ---- Light color (shared) ----
        p.addFloatSlider(withName: "Light R", parameterID: kParamBlinnLightR,
                         defaultValue: 1.0, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
        p.addFloatSlider(withName: "Light G", parameterID: kParamBlinnLightG,
                         defaultValue: 1.0, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
        p.addFloatSlider(withName: "Light B", parameterID: kParamBlinnLightB,
                         defaultValue: 1.0, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)

        // ---- Phong ----
        p.addFloatSlider(withName: "Shininess", parameterID: kParamPhongShininess,
                         defaultValue: 32.0, parameterMin: 1, parameterMax: 256,
                         sliderMin: 1, sliderMax: 128, delta: 1, parameterFlags: def)
        p.addFloatSlider(withName: "Specular", parameterID: kParamPhongSpecular,
                         defaultValue: 0.5, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
        p.addFloatSlider(withName: "Ambient R", parameterID: kParamPhongAmbR,
                         defaultValue: 0.1, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
        p.addFloatSlider(withName: "Ambient G", parameterID: kParamPhongAmbG,
                         defaultValue: 0.1, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
        p.addFloatSlider(withName: "Ambient B", parameterID: kParamPhongAmbB,
                         defaultValue: 0.1, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)

        // ---- Gooch ----
        p.addFloatSlider(withName: "Warm R", parameterID: kParamGoochWarmR,
                         defaultValue: 0.8, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
        p.addFloatSlider(withName: "Warm G", parameterID: kParamGoochWarmG,
                         defaultValue: 0.4, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
        p.addFloatSlider(withName: "Warm B", parameterID: kParamGoochWarmB,
                         defaultValue: 0.0, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
        p.addFloatSlider(withName: "Cool R", parameterID: kParamGoochCoolR,
                         defaultValue: 0.0, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
        p.addFloatSlider(withName: "Cool G", parameterID: kParamGoochCoolG,
                         defaultValue: 0.2, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
        p.addFloatSlider(withName: "Cool B", parameterID: kParamGoochCoolB,
                         defaultValue: 0.6, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
        p.addFloatSlider(withName: "Diffuse Warm", parameterID: kParamGoochDiffWarm,
                         defaultValue: 0.45, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
        p.addFloatSlider(withName: "Diffuse Cool", parameterID: kParamGoochDiffCool,
                         defaultValue: 0.45, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)

        // ---- EdgeFuzz ----
        p.addFloatSlider(withName: "Edge Specularity", parameterID: kParamEdgeSpecularity,
                         defaultValue: 10.0, parameterMin: 0, parameterMax: 100,
                         sliderMin: 0, sliderMax: 50, delta: 0.5, parameterFlags: def)
        p.addFloatSlider(withName: "Fuzziness", parameterID: kParamEdgeFuzziness,
                         defaultValue: 3.0, parameterMin: 0.1, parameterMax: 20,
                         sliderMin: 0.1, sliderMax: 10, delta: 0.1, parameterFlags: def)
        p.addFloatSlider(withName: "Edge Fade", parameterID: kParamEdgeFadeAmt,
                         defaultValue: 0.5, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)

        // ---- GlossyWet ----
        p.addFloatSlider(withName: "Specular Exponent", parameterID: kParamGlossSpecExp,
                         defaultValue: 64.0, parameterMin: 1, parameterMax: 512,
                         sliderMin: 1, sliderMax: 256, delta: 1, parameterFlags: def)
        p.addFloatSlider(withName: "Specularity", parameterID: kParamGlossSpec,
                         defaultValue: 0.8, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
        p.addFloatSlider(withName: "Gloss Max", parameterID: kParamGlossMax,
                         defaultValue: 0.95, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
        p.addFloatSlider(withName: "Gloss Min", parameterID: kParamGlossMin,
                         defaultValue: 0.5, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
        p.addFloatSlider(withName: "Gloss Drop", parameterID: kParamGlossDrop,
                         defaultValue: 0.1, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)

        // ---- LambSkin ----
        p.addFloatSlider(withName: "Lamb Rolloff", parameterID: kParamLambRolloff,
                         defaultValue: 0.3, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)

        // ---- ThinFilm ----
        p.addFloatSlider(withName: "Film Depth", parameterID: kParamThinFilmDepth,
                         defaultValue: 1.0, parameterMin: 0, parameterMax: 5,
                         sliderMin: 0, sliderMax: 3, delta: 0.05, parameterFlags: def)

        // ---- EnvMap ----
        p.addFloatSlider(withName: "Env Mix Ratio", parameterID: kParamEnvRatio,
                         defaultValue: 0.5, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)

        // ---- Velvet ----
        p.addFloatSlider(withName: "Velvet Rolloff", parameterID: kParamVelvetRolloff,
                         defaultValue: 0.3, parameterMin: 0, parameterMax: 1,
                         sliderMin: 0, sliderMax: 1, delta: 0.01, parameterFlags: def)
    }

    // MARK: Properties

    func properties(_ properties: AutoreleasingUnsafeMutablePointer<NSDictionary>?) throws {
        let props: NSDictionary = [
            kFxPropertyKey_IsThreadSafe:             NSNumber(booleanLiteral: true),
            kFxPropertyKey_MayRemapTime:             NSNumber(booleanLiteral: false),
            kFxPropertyKey_PixelTransformSupport:    NSNumber(value: kFxPixelTransform_ScaleTranslate),
            kFxPropertyKey_VariesWhenParamsAreStatic: NSNumber(booleanLiteral: false)
        ]
        properties?.pointee = props
    }

    // MARK: Plugin State snapshot (main thread → render thread)

    func pluginState(_ pluginState: AutoreleasingUnsafeMutablePointer<NSData>?,
                     at renderTime: CMTime,
                     quality qualityLevel: UInt) throws {
        let r = _apiManager.api(for: FxParameterRetrievalAPI_v6.self) as! FxParameterRetrievalAPI_v6

        func getFloat(_ id: UInt32) -> Float {
            var v = 0.0; r.getFloatValue(&v, fromParameter: id, at: renderTime); return Float(v)
        }
        func getInt(_ id: UInt32) -> Int32 {
            var v: Int32 = 0; r.getIntValue(&v, fromParameter: id, at: renderTime); return v
        }

        var state = LightingPluginState(
            shaderIndex:     getInt(kParamShaderSelect) - 1,  // popup is 1-based
            lightR:          getFloat(kParamBlinnLightR),
            lightG:          getFloat(kParamBlinnLightG),
            lightB:          getFloat(kParamBlinnLightB),
            shininess:       getFloat(kParamPhongShininess),
            specular:        getFloat(kParamPhongSpecular),
            ambR:            getFloat(kParamPhongAmbR),
            ambG:            getFloat(kParamPhongAmbG),
            ambB:            getFloat(kParamPhongAmbB),
            warmR:           getFloat(kParamGoochWarmR),
            warmG:           getFloat(kParamGoochWarmG),
            warmB:           getFloat(kParamGoochWarmB),
            coolR:           getFloat(kParamGoochCoolR),
            coolG:           getFloat(kParamGoochCoolG),
            coolB:           getFloat(kParamGoochCoolB),
            diffWarm:        getFloat(kParamGoochDiffWarm),
            diffCool:        getFloat(kParamGoochDiffCool),
            edgeSpecularity: getFloat(kParamEdgeSpecularity),
            edgeFuzziness:   getFloat(kParamEdgeFuzziness),
            edgeFade:        getFloat(kParamEdgeFadeAmt),
            glossSpecExp:    getFloat(kParamGlossSpecExp),
            glossSpec:       getFloat(kParamGlossSpec),
            glossMax:        getFloat(kParamGlossMax),
            glossMin:        getFloat(kParamGlossMin),
            glossDrop:       getFloat(kParamGlossDrop),
            lambRolloff:     getFloat(kParamLambRolloff),
            filmDepth:       getFloat(kParamThinFilmDepth),
            envRatio:        getFloat(kParamEnvRatio),
            velvetRolloff:   getFloat(kParamVelvetRolloff)
        )
        pluginState?.pointee = NSData(bytes: &state, length: MemoryLayout<LightingPluginState>.size)
    }

    // MARK: Tile sizing

    func destinationImageRect(_ destinationImageRect: UnsafeMutablePointer<FxRect>,
                               sourceImages: [FxImageTile],
                               destinationImage: FxImageTile,
                               pluginState: Data?,
                               at renderTime: CMTime) throws {
        destinationImageRect.pointee = sourceImages[0].imagePixelBounds
    }

    func sourceTileRect(_ sourceTileRect: UnsafeMutablePointer<FxRect>,
                        sourceImageIndex: UInt,
                        sourceImages: [FxImageTile],
                        destinationTileRect: FxRect,
                        destinationImage: FxImageTile,
                        pluginState: Data?,
                        at renderTime: CMTime) throws {
        sourceTileRect.pointee = destinationTileRect
    }

    // MARK: Render

    func renderDestinationImage(_ destinationImage: FxImageTile,
                                 sourceImages: [FxImageTile],
                                 pluginState: Data?,
                                 at renderTime: CMTime) throws {
        guard let stateData = pluginState,
              stateData.count >= MemoryLayout<LightingPluginState>.size else { return }

        let state = stateData.withUnsafeBytes {
            $0.bindMemory(to: LightingPluginState.self).baseAddress!.pointee
        }

        let deviceCache   = MetalDeviceCache.deviceCache
        let pixelFormat   = MetalDeviceCache.fxMTLPixelFormat(for: destinationImage)
        let registryID    = sourceImages[0].deviceRegistryID
        guard let commandQueue = deviceCache.commandQueue(with: registryID, pixelFormat: pixelFormat) else { return }

        let commandBuffer = commandQueue.makeCommandBuffer()!
        commandBuffer.label = "LightingModels Command Buffer"
        commandBuffer.enqueue()

        let inputTexture  = sourceImages[0].metalTexture(for: deviceCache.device(with: registryID))!
        let outputTexture = destinationImage.metalTexture(for: deviceCache.device(with: destinationImage.deviceRegistryID))!

        let colorAttachment = MTLRenderPassColorAttachmentDescriptor()
        colorAttachment.texture    = outputTexture
        colorAttachment.clearColor = MTLClearColorMake(0, 0, 0, 1)
        colorAttachment.loadAction = .clear
        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0] = colorAttachment

        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)!

        let outputWidth  = destinationImage.tilePixelBounds.right  - destinationImage.tilePixelBounds.left
        let outputHeight = destinationImage.tilePixelBounds.top    - destinationImage.tilePixelBounds.bottom

        var vertices = [
            Vertex2D(position: vector_float2( Float(outputWidth)/2,  -Float(outputHeight)/2), textureCoordinate: vector_float2(1, 1)),
            Vertex2D(position: vector_float2(-Float(outputWidth)/2,  -Float(outputHeight)/2), textureCoordinate: vector_float2(0, 1)),
            Vertex2D(position: vector_float2( Float(outputWidth)/2,   Float(outputHeight)/2), textureCoordinate: vector_float2(1, 0)),
            Vertex2D(position: vector_float2(-Float(outputWidth)/2,   Float(outputHeight)/2), textureCoordinate: vector_float2(0, 0))
        ]

        commandEncoder.setViewport(MTLViewport(originX: 0, originY: 0,
                                               width: Double(outputWidth), height: Double(outputHeight),
                                               znear: -1, zfar: 1))

        guard let pipelineState = deviceCache.pipelineState(with: registryID, pixelFormat: pixelFormat, shaderIndex: Int(state.shaderIndex)) else {
            commandEncoder.endEncoding(); commandBuffer.commit(); return
        }
        commandEncoder.setRenderPipelineState(pipelineState)

        commandEncoder.setVertexBytes(&vertices,
                                      length: MemoryLayout<Vertex2D>.size * 4,
                                      index: Int(LM_BVI_Vertices.rawValue))
        var vpSize = simd_uint2(UInt32(outputWidth), UInt32(outputHeight))
        commandEncoder.setVertexBytes(&vpSize,
                                      length: MemoryLayout.size(ofValue: vpSize),
                                      index: Int(LM_BVI_ViewportSize.rawValue))

        commandEncoder.setFragmentTexture(inputTexture, index: Int(LM_BTI_InputImage.rawValue))

        var uniforms = LightingUniforms(
            shaderIndex:     state.shaderIndex,
            lightR: state.lightR, lightG: state.lightG, lightB: state.lightB,
            shininess: state.shininess, specular: state.specular,
            ambR: state.ambR, ambG: state.ambG, ambB: state.ambB,
            warmR: state.warmR, warmG: state.warmG, warmB: state.warmB,
            coolR: state.coolR, coolG: state.coolG, coolB: state.coolB,
            diffWarm: state.diffWarm, diffCool: state.diffCool,
            edgeSpecularity: state.edgeSpecularity, edgeFuzziness: state.edgeFuzziness, edgeFade: state.edgeFade,
            glossSpecExp: state.glossSpecExp, glossSpec: state.glossSpec,
            glossMax: state.glossMax, glossMin: state.glossMin, glossDrop: state.glossDrop,
            lambRolloff: state.lambRolloff,
            filmDepth: state.filmDepth,
            envRatio: state.envRatio,
            velvetRolloff: state.velvetRolloff
        )
        commandEncoder.setFragmentBytes(&uniforms,
                                        length: MemoryLayout<LightingUniforms>.size,
                                        index: Int(LM_BFI_Uniforms.rawValue))

        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        deviceCache.returnCommandQueueToCache(commandQueue: commandQueue)
    }
}
