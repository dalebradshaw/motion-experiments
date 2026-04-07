import Foundation
import Metal
import FxPlug
import os.log

private let lmLog = OSLog(subsystem: "com.dalebradshaw.LightingModels", category: "plugin")

// MARK: - Shader index constants (matches Metal switch statement)

let kShaderBlinn:       Int32 = 0
let kShaderPhong:       Int32 = 1
let kShaderGooch:       Int32 = 2
let kShaderEdgeFuzz:    Int32 = 3
let kShaderGlossyWet:   Int32 = 4
let kShaderHemisphere:  Int32 = 5
let kShaderLambSkin:    Int32 = 6
let kShaderLUTSkin:     Int32 = 7
let kShaderThinFilm:    Int32 = 8
let kShaderEnvMap:      Int32 = 9
let kShaderVelvet:      Int32 = 10

// MARK: - Parameter IDs (flat; each class only uses its own)

// Blinn
let kBlinnLightColor: UInt32 = 1

// Phong
let kPhongLightColor:   UInt32 = 1
let kPhongAmbientColor: UInt32 = 2
let kPhongShininess:    UInt32 = 3
let kPhongSpecular:     UInt32 = 4

// Gooch
let kGoochWarmColor:  UInt32 = 1
let kGoochCoolColor:  UInt32 = 2
let kGoochDiffWarm:   UInt32 = 3
let kGoochDiffCool:   UInt32 = 4

// EdgeFuzz
let kEdgeLightColor:   UInt32 = 1
let kEdgeEdgeColor:    UInt32 = 2
let kEdgeSurfaceColor: UInt32 = 3
let kEdgeAmbientColor: UInt32 = 4
let kEdgeSpecularity:  UInt32 = 5
let kEdgeFuzziness:    UInt32 = 6
let kEdgeFade:         UInt32 = 7

// GlossyWet
let kGlossSpecColor: UInt32 = 1
let kGlossDiffColor: UInt32 = 2
let kGlossAmbColor:  UInt32 = 3
let kGlossSpecExp:   UInt32 = 4
let kGlossSpec:      UInt32 = 5
let kGlossMax:       UInt32 = 6
let kGlossMin:       UInt32 = 7
let kGlossDrop:      UInt32 = 8

// Hemisphere
let kHemiSkyColor:    UInt32 = 1
let kHemiGroundColor: UInt32 = 2

// LambSkin
let kLambAmbientColor: UInt32 = 1
let kLambDiffuseColor: UInt32 = 2
let kLambSubColor:     UInt32 = 3
let kLambRolloff:      UInt32 = 4

// LUTSkin
let kLUTDiffuseColor:  UInt32 = 1
let kLUTSpecularColor: UInt32 = 2
let kLUTSkinImage:     UInt32 = 3

// ThinFilm
let kThinFilmDepth:    UInt32 = 1
let kThinFringeImage:  UInt32 = 2

// EnvMap
let kEnvImage: UInt32 = 1
let kEnvRatio: UInt32 = 2

// Velvet
let kVelvetUnderColor: UInt32 = 1
let kVelvetRolloff:    UInt32 = 2

// MARK: - Plugin State (shared across all shaders — Metal reads only the fields it needs)

struct LightingPluginState {
    var shaderIndex: Int32
    var hasAuxTexture: Int32

    var lightR: Float; var lightG: Float; var lightB: Float
    var shininess: Float; var specular: Float
    var ambR: Float; var ambG: Float; var ambB: Float
    var warmR: Float; var warmG: Float; var warmB: Float
    var coolR: Float; var coolG: Float; var coolB: Float
    var diffWarm: Float; var diffCool: Float
    var edgeSpecularity: Float; var edgeFuzziness: Float; var edgeFade: Float
    var edgeColorR: Float; var edgeColorG: Float; var edgeColorB: Float
    var surfaceColorR: Float; var surfaceColorG: Float; var surfaceColorB: Float
    var ambientColorR: Float; var ambientColorG: Float; var ambientColorB: Float
    var glossSpecExp: Float; var glossSpec: Float
    var glossMax: Float; var glossMin: Float; var glossDrop: Float
    var specColorR: Float; var specColorG: Float; var specColorB: Float
    var diffColorR: Float; var diffColorG: Float; var diffColorB: Float
    var glossAmbR: Float; var glossAmbG: Float; var glossAmbB: Float
    var lambRolloff: Float
    var lambAmbR: Float; var lambAmbG: Float; var lambAmbB: Float
    var lambDiffR: Float; var lambDiffG: Float; var lambDiffB: Float
    var lambSubR: Float; var lambSubG: Float; var lambSubB: Float
    var lutDiffR: Float; var lutDiffG: Float; var lutDiffB: Float
    var lutSpecR: Float; var lutSpecG: Float; var lutSpecB: Float
    var filmDepth: Float
    var envRatio: Float
    var velvetRolloff: Float
    var velvetUnderR: Float; var velvetUnderG: Float; var velvetUnderB: Float
}

// MARK: - Base class (shared render + scheduleInputs logic)

class LightingBasePlugIn: NSObject, FxTileableEffect {

    let _apiManager: PROAPIAccessing

    required init?(apiManager: PROAPIAccessing) {
        _apiManager = apiManager
        super.init()
    }

    // Subclasses override these two:
    var shaderIndex: Int32 { fatalError("override shaderIndex") }
    /// Return nil if this shader has no image well; return the paramID if it does.
    var imageWellParamID: UInt32? { return nil }

    // MARK: API helpers

    func creationAPI() -> FxParameterCreationAPI_v5 {
        return _apiManager.api(for: FxParameterCreationAPI_v5.self) as! FxParameterCreationAPI_v5
    }
    func retrievalAPI() -> FxParameterRetrievalAPI_v6? {
        return _apiManager.api(for: FxParameterRetrievalAPI_v6.self) as? FxParameterRetrievalAPI_v6
    }
    func retrievalAPIv7() -> FxParameterRetrievalAPI_v7? {
        return _apiManager.api(for: FxParameterRetrievalAPI_v7.self) as? FxParameterRetrievalAPI_v7
    }

    func addColor(_ p: FxParameterCreationAPI_v5, name: String, id: UInt32,
                  r: Double, g: Double, b: Double) {
        p.addColorParameter(withName: name, parameterID: id,
                            defaultRed: r, defaultGreen: g, defaultBlue: b,
                            parameterFlags: FxParameterFlags(kFxParameterFlag_DEFAULT))
    }
    func addSlider(_ p: FxParameterCreationAPI_v5, name: String, id: UInt32,
                   def: Double, min: Double, max: Double,
                   sMin: Double, sMax: Double, delta: Double) {
        p.addFloatSlider(withName: name, parameterID: id,
                         defaultValue: def, parameterMin: min, parameterMax: max,
                         sliderMin: sMin, sliderMax: sMax, delta: delta,
                         parameterFlags: FxParameterFlags(kFxParameterFlag_DEFAULT))
    }

    // MARK: FxTileableEffect — addParameters (subclasses override)

    func addParameters() throws {
        // subclasses implement
    }

    // MARK: Properties

    func properties(_ properties: AutoreleasingUnsafeMutablePointer<NSDictionary>?) throws {
        // Match Apple's FxPictureInPicture example exactly — only these two keys.
        // kFxPropertyKey_IsThreadSafe was removed in FxPlug 4.2.8 SDK (release notes).
        // kFxPropertyKey_VariesWhenParamsAreStatic is not used by Apple's image well examples.
        let props: NSDictionary = [
            kFxPropertyKey_MayRemapTime:              NSNumber(booleanLiteral: false),
            kFxPropertyKey_PixelTransformSupport:     NSNumber(value: kFxPixelTransform_ScaleTranslate),
        ]
        properties?.pointee = props
    }

    // MARK: scheduleInputs

    func scheduleInputs(_ inputImageRequests: AutoreleasingUnsafeMutablePointer<NSArray?>?,
                        withPluginState pluginState: Data?,
                        atTime renderTime: CMTime,
                        error outError: NSError?) -> Bool {
        os_log(.default, log: lmLog,
               "scheduleInputs: shaderIndex=%{public}d wellParamID=%{public}@ time=%.3f",
               shaderIndex,
               imageWellParamID.map { String($0) } ?? "nil",
               CMTimeGetSeconds(renderTime))

        let clipReq = FxImageTileRequest(source: kFxImageTileRequestSourceEffectClip,
                                         time: renderTime,
                                         includeFilters: true,
                                         parameterID: 0)
        os_log(.default, log: lmLog, "clipReq=%{public}@", clipReq == nil ? "nil" : "OK")
        var requests: [FxImageTileRequest] = [clipReq!]

        if let wellID = imageWellParamID {
            let wellReq = FxImageTileRequest(source: kFxImageTileRequestSourceParameter,
                                             time: renderTime,
                                             includeFilters: true,
                                             parameterID: wellID)
            os_log(.default, log: lmLog, "wellReq paramID=%{public}u = %{public}@",
                   wellID, wellReq == nil ? "nil" : "OK")
            if let req = wellReq {
                requests.append(req)
                os_log(.default, log: lmLog, "appended wellReq, total=%{public}d", requests.count)
            } else {
                os_log(.error, log: lmLog, "wellReq was nil — skipping (empty well)")
            }
        }
        inputImageRequests?.pointee = requests as NSArray
        os_log(.default, log: lmLog, "returning %{public}d requests", requests.count)
        return true
    }

    // MARK: pluginState — subclasses override to populate their fields

    func pluginState(_ pluginState: AutoreleasingUnsafeMutablePointer<NSData>?,
                     at renderTime: CMTime,
                     quality qualityLevel: UInt) throws {
        // Determine whether an image is actually connected to the well.
        // FxParameterRetrievalAPI_v7.imageSize(_:fromParameter:atTime:error:) returns YES
        // only when a clip/image is assigned; returns NO (and sets error) when the well is empty.
        var auxConnected: Int32 = 0
        if let wellID = imageWellParamID,
           let rv7 = retrievalAPIv7() {
            var sz = CGSize.zero
            let connected = (try? rv7.imageSize(&sz, fromParameter: wellID, at: renderTime)) != nil
            auxConnected = connected ? 1 : 0
            NSLog("[LM] pluginState: wellID=%u connected=%d size=%.0fx%.0f", wellID, auxConnected, sz.width, sz.height)
            os_log(.default, log: lmLog,
                   "pluginState: wellID=%{public}u connected=%{public}d size=%{public}.0fx%{public}.0f",
                   wellID, auxConnected, sz.width, sz.height)
        }

        var state = LightingPluginState(
            shaderIndex: shaderIndex,
            hasAuxTexture: auxConnected,
            lightR: 1, lightG: 1, lightB: 1,
            shininess: 32, specular: 0.5,
            ambR: 0, ambG: 0, ambB: 0,
            warmR: 0.8, warmG: 0.4, warmB: 0,
            coolR: 0, coolG: 0.2, coolB: 0.6,
            diffWarm: 0.45, diffCool: 0.45,
            edgeSpecularity: 10, edgeFuzziness: 3, edgeFade: 0.5,
            edgeColorR: 0, edgeColorG: 0, edgeColorB: 0,
            surfaceColorR: 0.7, surfaceColorG: 0.7, surfaceColorB: 0.7,
            ambientColorR: 0.1, ambientColorG: 0.1, ambientColorB: 0.1,
            glossSpecExp: 64, glossSpec: 0.8,
            glossMax: 0.95, glossMin: 0.5, glossDrop: 0.1,
            specColorR: 1, specColorG: 1, specColorB: 1,
            diffColorR: 0.5, diffColorG: 0.5, diffColorB: 0.5,
            glossAmbR: 0.05, glossAmbG: 0.05, glossAmbB: 0.05,
            lambRolloff: 0.3,
            lambAmbR: 0.05, lambAmbG: 0.05, lambAmbB: 0.05,
            lambDiffR: 0.8,  lambDiffG: 0.6,  lambDiffB: 0.5,
            lambSubR: 0.8,   lambSubG: 0.2,   lambSubB: 0.1,
            lutDiffR: 0.9, lutDiffG: 0.7, lutDiffB: 0.6,
            lutSpecR: 0.8, lutSpecG: 0.7, lutSpecB: 0.6,
            filmDepth: 1.0,
            envRatio: 0.5,
            velvetRolloff: 0.3,
            velvetUnderR: 0.3, velvetUnderG: 0.1, velvetUnderB: 0.1
        )
        populateState(&state, retrieval: retrievalAPI(), at: renderTime)
        pluginState?.pointee = NSData(bytes: &state, length: MemoryLayout<LightingPluginState>.size)
    }

    /// Subclasses override to read their params into the state struct.
    func populateState(_ state: inout LightingPluginState,
                       retrieval r: FxParameterRetrievalAPI_v6?,
                       at time: CMTime) {
        // base does nothing; subclasses fill in their fields
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

        var state = stateData.withUnsafeBytes {
            $0.bindMemory(to: LightingPluginState.self).baseAddress!.pointee
        }
        if state.hasAuxTexture == 1 && sourceImages.count < 2 {
            state.hasAuxTexture = 0
        }

        let deviceCache  = MetalDeviceCache.deviceCache
        let pixelFormat  = MetalDeviceCache.fxMTLPixelFormat(for: destinationImage)
        let registryID   = sourceImages[0].deviceRegistryID
        guard let commandQueue = deviceCache.commandQueue(with: registryID, pixelFormat: pixelFormat) else { return }

        let commandBuffer = commandQueue.makeCommandBuffer()!
        commandBuffer.label = "LightingModels Command Buffer"
        commandBuffer.enqueue()

        guard let inputDevice = deviceCache.device(with: registryID) else {
            commandBuffer.commit(); return
        }
        let inputTexture  = sourceImages[0].metalTexture(for: inputDevice)!
        let outputTexture = destinationImage.metalTexture(
            for: deviceCache.device(with: destinationImage.deviceRegistryID)!)!

        var auxTexture: MTLTexture? = nil
        if state.hasAuxTexture == 1, sourceImages.count >= 2 {
            auxTexture = sourceImages[1].metalTexture(for: inputDevice)
        }

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

        guard let pipelineState = deviceCache.pipelineState(with: registryID,
                                                             pixelFormat: pixelFormat,
                                                             shaderIndex: Int(state.shaderIndex)) else {
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
        if let aux = auxTexture {
            commandEncoder.setFragmentTexture(aux, index: Int(LM_BTI_AuxImage.rawValue))
        }

        var uniforms = LightingUniforms(
            shaderIndex:    state.shaderIndex,
            hasAuxTexture:  state.hasAuxTexture,
            lightR: state.lightR, lightG: state.lightG, lightB: state.lightB,
            shininess: state.shininess, specular: state.specular,
            ambR: state.ambR, ambG: state.ambG, ambB: state.ambB,
            warmR: state.warmR, warmG: state.warmG, warmB: state.warmB,
            coolR: state.coolR, coolG: state.coolG, coolB: state.coolB,
            diffWarm: state.diffWarm, diffCool: state.diffCool,
            edgeSpecularity: state.edgeSpecularity,
            edgeFuzziness:   state.edgeFuzziness,
            edgeFade:        state.edgeFade,
            edgeColorR: state.edgeColorR, edgeColorG: state.edgeColorG, edgeColorB: state.edgeColorB,
            surfaceColorR: state.surfaceColorR, surfaceColorG: state.surfaceColorG, surfaceColorB: state.surfaceColorB,
            ambientColorR: state.ambientColorR, ambientColorG: state.ambientColorG, ambientColorB: state.ambientColorB,
            glossSpecExp: state.glossSpecExp, glossSpec: state.glossSpec,
            glossMax: state.glossMax, glossMin: state.glossMin, glossDrop: state.glossDrop,
            specColorR: state.specColorR, specColorG: state.specColorG, specColorB: state.specColorB,
            diffColorR: state.diffColorR, diffColorG: state.diffColorG, diffColorB: state.diffColorB,
            glossAmbR:  state.glossAmbR,  glossAmbG:  state.glossAmbG,  glossAmbB:  state.glossAmbB,
            lambRolloff: state.lambRolloff,
            lambAmbR: state.lambAmbR, lambAmbG: state.lambAmbG, lambAmbB: state.lambAmbB,
            lambDiffR: state.lambDiffR, lambDiffG: state.lambDiffG, lambDiffB: state.lambDiffB,
            lambSubR: state.lambSubR, lambSubG: state.lambSubG, lambSubB: state.lambSubB,
            lutDiffR: state.lutDiffR, lutDiffG: state.lutDiffG, lutDiffB: state.lutDiffB,
            lutSpecR: state.lutSpecR, lutSpecG: state.lutSpecG, lutSpecB: state.lutSpecB,
            filmDepth: state.filmDepth,
            envRatio:  state.envRatio,
            velvetRolloff: state.velvetRolloff,
            velvetUnderR: state.velvetUnderR, velvetUnderG: state.velvetUnderG, velvetUnderB: state.velvetUnderB
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

// MARK: - Helpers for reading params

private func rgb(_ r: FxParameterRetrievalAPI_v6, _ id: UInt32, _ time: CMTime) -> (Float, Float, Float) {
    var red = 0.0, green = 0.0, blue = 0.0
    r.getRedValue(&red, greenValue: &green, blueValue: &blue, fromParameter: id, at: time)
    return (Float(red), Float(green), Float(blue))
}
private func flt(_ r: FxParameterRetrievalAPI_v6, _ id: UInt32, _ time: CMTime) -> Float {
    var v = 0.0; r.getFloatValue(&v, fromParameter: id, at: time); return Float(v)
}

// MARK: - 11 Concrete Shader Classes

// ── Blinn ────────────────────────────────────────────────────────────────────

@objc(BlinnPlugIn)
class BlinnPlugIn: LightingBasePlugIn {
    override var shaderIndex: Int32 { kShaderBlinn }

    override func addParameters() throws {
        let p = creationAPI()
        addColor(p, name: "Light Color", id: kBlinnLightColor, r: 1, g: 1, b: 1)
    }

    override func populateState(_ state: inout LightingPluginState,
                                retrieval r: FxParameterRetrievalAPI_v6?,
                                at time: CMTime) {
        guard let r else { return }
        let c = rgb(r, kBlinnLightColor, time)
        state.lightR = c.0; state.lightG = c.1; state.lightB = c.2
    }
}

// ── Phong ─────────────────────────────────────────────────────────────────────

@objc(PhongPlugIn)
class PhongPlugIn: LightingBasePlugIn {
    override var shaderIndex: Int32 { kShaderPhong }

    override func addParameters() throws {
        let p = creationAPI()
        addColor(p, name: "Light Color",   id: kPhongLightColor,   r: 1,   g: 1,   b: 1)
        addColor(p, name: "Ambient Color", id: kPhongAmbientColor, r: 0.1, g: 0.1, b: 0.1)
        addSlider(p, name: "Shininess", id: kPhongShininess,
                  def: 32, min: 1, max: 256, sMin: 1, sMax: 128, delta: 1)
        addSlider(p, name: "Specular", id: kPhongSpecular,
                  def: 0.5, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
    }

    override func populateState(_ state: inout LightingPluginState,
                                retrieval r: FxParameterRetrievalAPI_v6?,
                                at time: CMTime) {
        guard let r else { return }
        let light = rgb(r, kPhongLightColor, time)
        let amb   = rgb(r, kPhongAmbientColor, time)
        state.lightR = light.0; state.lightG = light.1; state.lightB = light.2
        state.ambR   = amb.0;   state.ambG   = amb.1;   state.ambB   = amb.2
        state.shininess = flt(r, kPhongShininess, time)
        state.specular  = flt(r, kPhongSpecular,  time)
    }
}

// ── Gooch ─────────────────────────────────────────────────────────────────────

@objc(GoochPlugIn)
class GoochPlugIn: LightingBasePlugIn {
    override var shaderIndex: Int32 { kShaderGooch }

    override func addParameters() throws {
        let p = creationAPI()
        addColor(p, name: "Warm Color", id: kGoochWarmColor, r: 0.8, g: 0.4, b: 0.0)
        addColor(p, name: "Cool Color", id: kGoochCoolColor, r: 0.0, g: 0.2, b: 0.6)
        addSlider(p, name: "Diffuse Warm", id: kGoochDiffWarm,
                  def: 0.45, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
        addSlider(p, name: "Diffuse Cool", id: kGoochDiffCool,
                  def: 0.45, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
    }

    override func populateState(_ state: inout LightingPluginState,
                                retrieval r: FxParameterRetrievalAPI_v6?,
                                at time: CMTime) {
        guard let r else { return }
        let warm = rgb(r, kGoochWarmColor, time)
        let cool = rgb(r, kGoochCoolColor, time)
        state.warmR = warm.0; state.warmG = warm.1; state.warmB = warm.2
        state.coolR = cool.0; state.coolG = cool.1; state.coolB = cool.2
        state.diffWarm = flt(r, kGoochDiffWarm, time)
        state.diffCool = flt(r, kGoochDiffCool, time)
    }
}

// ── EdgeFuzz ──────────────────────────────────────────────────────────────────

@objc(EdgeFuzzPlugIn)
class EdgeFuzzPlugIn: LightingBasePlugIn {
    override var shaderIndex: Int32 { kShaderEdgeFuzz }

    override func addParameters() throws {
        let p = creationAPI()
        addColor(p, name: "Light Color",   id: kEdgeLightColor,   r: 1,   g: 1,   b: 1)
        addColor(p, name: "Edge Color",    id: kEdgeEdgeColor,    r: 0,   g: 0,   b: 0)
        addColor(p, name: "Surface Color", id: kEdgeSurfaceColor, r: 0.7, g: 0.7, b: 0.7)
        addColor(p, name: "Ambient Color", id: kEdgeAmbientColor, r: 0.1, g: 0.1, b: 0.1)
        addSlider(p, name: "Specularity", id: kEdgeSpecularity,
                  def: 10, min: 0, max: 100, sMin: 0, sMax: 50, delta: 0.5)
        addSlider(p, name: "Fuzziness", id: kEdgeFuzziness,
                  def: 3, min: 0.1, max: 20, sMin: 0.1, sMax: 10, delta: 0.1)
        addSlider(p, name: "Edge Fade", id: kEdgeFade,
                  def: 0.5, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
    }

    override func populateState(_ state: inout LightingPluginState,
                                retrieval r: FxParameterRetrievalAPI_v6?,
                                at time: CMTime) {
        guard let r else { return }
        let light = rgb(r, kEdgeLightColor, time)
        let edge  = rgb(r, kEdgeEdgeColor,  time)
        let surf  = rgb(r, kEdgeSurfaceColor, time)
        let amb   = rgb(r, kEdgeAmbientColor, time)
        state.lightR = light.0; state.lightG = light.1; state.lightB = light.2
        state.edgeColorR = edge.0; state.edgeColorG = edge.1; state.edgeColorB = edge.2
        state.surfaceColorR = surf.0; state.surfaceColorG = surf.1; state.surfaceColorB = surf.2
        state.ambientColorR = amb.0; state.ambientColorG = amb.1; state.ambientColorB = amb.2
        state.edgeSpecularity = flt(r, kEdgeSpecularity, time)
        state.edgeFuzziness   = flt(r, kEdgeFuzziness,   time)
        state.edgeFade        = flt(r, kEdgeFade,        time)
    }
}

// ── GlossyWet ─────────────────────────────────────────────────────────────────

@objc(GlossyWetPlugIn)
class GlossyWetPlugIn: LightingBasePlugIn {
    override var shaderIndex: Int32 { kShaderGlossyWet }

    override func addParameters() throws {
        let p = creationAPI()
        addColor(p, name: "Specular Color", id: kGlossSpecColor, r: 1,    g: 1,    b: 1)
        addColor(p, name: "Diffuse Color",  id: kGlossDiffColor, r: 0.5,  g: 0.5,  b: 0.5)
        addColor(p, name: "Ambient Color",  id: kGlossAmbColor,  r: 0.05, g: 0.05, b: 0.05)
        addSlider(p, name: "Specular Exponent", id: kGlossSpecExp,
                  def: 64, min: 1, max: 512, sMin: 1, sMax: 256, delta: 1)
        addSlider(p, name: "Specularity", id: kGlossSpec,
                  def: 0.8, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
        addSlider(p, name: "Gloss Max",  id: kGlossMax,
                  def: 0.95, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
        addSlider(p, name: "Gloss Min",  id: kGlossMin,
                  def: 0.5,  min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
        addSlider(p, name: "Gloss Drop", id: kGlossDrop,
                  def: 0.1,  min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
    }

    override func populateState(_ state: inout LightingPluginState,
                                retrieval r: FxParameterRetrievalAPI_v6?,
                                at time: CMTime) {
        guard let r else { return }
        let spec = rgb(r, kGlossSpecColor, time)
        let diff = rgb(r, kGlossDiffColor, time)
        let amb  = rgb(r, kGlossAmbColor,  time)
        state.specColorR = spec.0; state.specColorG = spec.1; state.specColorB = spec.2
        state.diffColorR = diff.0; state.diffColorG = diff.1; state.diffColorB = diff.2
        state.glossAmbR  = amb.0;  state.glossAmbG  = amb.1;  state.glossAmbB  = amb.2
        state.glossSpecExp = flt(r, kGlossSpecExp, time)
        state.glossSpec    = flt(r, kGlossSpec,    time)
        state.glossMax     = flt(r, kGlossMax,     time)
        state.glossMin     = flt(r, kGlossMin,     time)
        state.glossDrop    = flt(r, kGlossDrop,    time)
    }
}

// ── Hemisphere ────────────────────────────────────────────────────────────────

@objc(HemispherePlugIn)
class HemispherePlugIn: LightingBasePlugIn {
    override var shaderIndex: Int32 { kShaderHemisphere }

    override func addParameters() throws {
        let p = creationAPI()
        addColor(p, name: "Sky Color",    id: kHemiSkyColor,    r: 0.4, g: 0.6, b: 1.0)
        addColor(p, name: "Ground Color", id: kHemiGroundColor, r: 0.2, g: 0.15, b: 0.1)
    }

    override func populateState(_ state: inout LightingPluginState,
                                retrieval r: FxParameterRetrievalAPI_v6?,
                                at time: CMTime) {
        guard let r else { return }
        let sky    = rgb(r, kHemiSkyColor,    time)
        let ground = rgb(r, kHemiGroundColor, time)
        // Hemisphere packs sky→light, ground→amb
        state.lightR = sky.0;    state.lightG = sky.1;    state.lightB = sky.2
        state.ambR   = ground.0; state.ambG   = ground.1; state.ambB   = ground.2
    }
}

// ── LambSkin ──────────────────────────────────────────────────────────────────

@objc(LambSkinPlugIn)
class LambSkinPlugIn: LightingBasePlugIn {
    override var shaderIndex: Int32 { kShaderLambSkin }

    override func addParameters() throws {
        let p = creationAPI()
        addColor(p, name: "Ambient Color",    id: kLambAmbientColor, r: 0.05, g: 0.05, b: 0.05)
        addColor(p, name: "Diffuse Color",    id: kLambDiffuseColor, r: 0.8,  g: 0.6,  b: 0.5)
        addColor(p, name: "Subsurface Color", id: kLambSubColor,     r: 0.8,  g: 0.2,  b: 0.1)
        addSlider(p, name: "Rolloff", id: kLambRolloff,
                  def: 0.3, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
    }

    override func populateState(_ state: inout LightingPluginState,
                                retrieval r: FxParameterRetrievalAPI_v6?,
                                at time: CMTime) {
        guard let r else { return }
        let amb  = rgb(r, kLambAmbientColor, time)
        let diff = rgb(r, kLambDiffuseColor, time)
        let sub  = rgb(r, kLambSubColor,     time)
        state.lambAmbR  = amb.0;  state.lambAmbG  = amb.1;  state.lambAmbB  = amb.2
        state.lambDiffR = diff.0; state.lambDiffG = diff.1; state.lambDiffB = diff.2
        state.lambSubR  = sub.0;  state.lambSubG  = sub.1;  state.lambSubB  = sub.2
        state.lambRolloff = flt(r, kLambRolloff, time)
    }
}

// ── LUTSkin ───────────────────────────────────────────────────────────────────

@objc(LUTSkinPlugIn)
class LUTSkinPlugIn: LightingBasePlugIn {
    override var shaderIndex: Int32   { kShaderLUTSkin }
    override var imageWellParamID: UInt32? { kLUTSkinImage }

    override func addParameters() throws {
        let p = creationAPI()
        addColor(p, name: "Diffuse Color",  id: kLUTDiffuseColor,  r: 0.9, g: 0.7, b: 0.6)
        addColor(p, name: "Specular Color", id: kLUTSpecularColor, r: 0.8, g: 0.7, b: 0.6)
        os_log(.default, log: lmLog, "LUTSkin: adding image reference 'Skin LUT' paramID=%{public}u flags=DEFAULT", kLUTSkinImage)
        p.addImageReference(withName: "Skin LUT", parameterID: kLUTSkinImage,
                            parameterFlags: FxParameterFlags(kFxParameterFlag_DEFAULT))
        os_log(.default, log: lmLog, "LUTSkin: addParameters complete")
    }

    override func populateState(_ state: inout LightingPluginState,
                                retrieval r: FxParameterRetrievalAPI_v6?,
                                at time: CMTime) {
        guard let r else { return }
        let diff = rgb(r, kLUTDiffuseColor,  time)
        let spec = rgb(r, kLUTSpecularColor, time)
        state.lutDiffR = diff.0; state.lutDiffG = diff.1; state.lutDiffB = diff.2
        state.lutSpecR = spec.0; state.lutSpecG = spec.1; state.lutSpecB = spec.2
    }
}

// ── ThinFilm ──────────────────────────────────────────────────────────────────

@objc(ThinFilmPlugIn)
class ThinFilmPlugIn: LightingBasePlugIn {
    override var shaderIndex: Int32   { kShaderThinFilm }
    override var imageWellParamID: UInt32? { kThinFringeImage }

    override func addParameters() throws {
        let p = creationAPI()
        addSlider(p, name: "Film Depth", id: kThinFilmDepth,
                  def: 1.0, min: 0, max: 5, sMin: 0, sMax: 3, delta: 0.05)
        p.addImageReference(withName: "Fringe Map", parameterID: kThinFringeImage,
                            parameterFlags: FxParameterFlags(kFxParameterFlag_DEFAULT))
    }

    override func populateState(_ state: inout LightingPluginState,
                                retrieval r: FxParameterRetrievalAPI_v6?,
                                at time: CMTime) {
        guard let r else { return }
        state.filmDepth = flt(r, kThinFilmDepth, time)
    }
}

// ── EnvMap ────────────────────────────────────────────────────────────────────

@objc(EnvMapPlugIn)
class EnvMapPlugIn: LightingBasePlugIn {
    override var shaderIndex: Int32   { kShaderEnvMap }
    override var imageWellParamID: UInt32? { kEnvImage }

    override func addParameters() throws {
        let p = creationAPI()
        p.addImageReference(withName: "Environment", parameterID: kEnvImage,
                            parameterFlags: FxParameterFlags(kFxParameterFlag_DEFAULT))
        addSlider(p, name: "Mix Ratio", id: kEnvRatio,
                  def: 0.5, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
    }

    override func populateState(_ state: inout LightingPluginState,
                                retrieval r: FxParameterRetrievalAPI_v6?,
                                at time: CMTime) {
        guard let r else { return }
        state.envRatio = flt(r, kEnvRatio, time)
    }
}

// ── Velvet ────────────────────────────────────────────────────────────────────

@objc(VelvetPlugIn)
class VelvetPlugIn: LightingBasePlugIn {
    override var shaderIndex: Int32 { kShaderVelvet }

    override func addParameters() throws {
        let p = creationAPI()
        addColor(p, name: "Under Color", id: kVelvetUnderColor, r: 0.3, g: 0.1, b: 0.1)
        addSlider(p, name: "Rolloff", id: kVelvetRolloff,
                  def: 0.3, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
    }

    override func populateState(_ state: inout LightingPluginState,
                                retrieval r: FxParameterRetrievalAPI_v6?,
                                at time: CMTime) {
        guard let r else { return }
        let under = rgb(r, kVelvetUnderColor, time)
        state.velvetUnderR = under.0; state.velvetUnderG = under.1; state.velvetUnderB = under.2
        state.velvetRolloff = flt(r, kVelvetRolloff, time)
    }
}
