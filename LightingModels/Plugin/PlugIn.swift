import Foundation
import Metal
import FxPlug
import os.log

private let lmLog = OSLog(subsystem: "com.dalebradshaw.LightingModels", category: "Plugin")

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

// MARK: - Parameter IDs
//
//  1       global shader selector
//  100–    Blinn group
//  200–    Phong group
//  300–    Gooch group
//  400–    EdgeFuzz group
//  500–    GlossyWet group
//  600–    Hemisphere group
//  700–    LambSkin group
//  800–    LUTSkin group
//  900–    ThinFilm group
//  1000–   EnvMap group
//  1100–   Velvet group

let kParamShaderSelect: UInt32 = 1

// Groups (sub-group IDs)
let kGroupBlinn:      UInt32 = 100
let kGroupPhong:      UInt32 = 200
let kGroupGooch:      UInt32 = 300
let kGroupEdgeFuzz:   UInt32 = 400
let kGroupGlossyWet:  UInt32 = 500
let kGroupHemisphere: UInt32 = 600
let kGroupLambSkin:   UInt32 = 700
let kGroupLUTSkin:    UInt32 = 800
let kGroupThinFilm:   UInt32 = 900
let kGroupEnvMap:     UInt32 = 1000
let kGroupVelvet:     UInt32 = 1100

// Blinn
let kParamBlinnLightColor: UInt32 = 101

// Phong
let kParamPhongLightColor:   UInt32 = 201
let kParamPhongShininess:    UInt32 = 202
let kParamPhongSpecular:     UInt32 = 203
let kParamPhongAmbientColor: UInt32 = 204

// Gooch
let kParamGoochWarmColor:  UInt32 = 301
let kParamGoochCoolColor:  UInt32 = 302
let kParamGoochDiffWarm:   UInt32 = 303
let kParamGoochDiffCool:   UInt32 = 304

// EdgeFuzz
let kParamEdgeLightColor:   UInt32 = 401
let kParamEdgeEdgeColor:    UInt32 = 402
let kParamEdgeSurfaceColor: UInt32 = 403
let kParamEdgeAmbientColor: UInt32 = 404
let kParamEdgeSpecularity:  UInt32 = 405
let kParamEdgeFuzziness:    UInt32 = 406
let kParamEdgeFade:         UInt32 = 407

// GlossyWet
let kParamGlossSpecColor:   UInt32 = 501
let kParamGlossDiffColor:   UInt32 = 502
let kParamGlossAmbColor:    UInt32 = 503
let kParamGlossSpecExp:     UInt32 = 504
let kParamGlossSpec:        UInt32 = 505
let kParamGlossMax:         UInt32 = 506
let kParamGlossMin:         UInt32 = 507
let kParamGlossDrop:        UInt32 = 508

// Hemisphere
let kParamHemiSkyColor:    UInt32 = 601
let kParamHemiGroundColor: UInt32 = 602

// LambSkin
let kParamLambAmbientColor: UInt32 = 701
let kParamLambDiffuseColor: UInt32 = 702
let kParamLambSubColor:     UInt32 = 703
let kParamLambRolloff:      UInt32 = 704

// LUTSkin
let kParamLUTDiffuseColor:  UInt32 = 801
let kParamLUTSpecularColor: UInt32 = 802
let kParamLUTSkinImage:     UInt32 = 803   // image well → SkinLUT

// ThinFilm
let kParamThinFilmDepth:    UInt32 = 901
let kParamThinFringeImage:  UInt32 = 902   // image well → FringeMap

// EnvMap
let kParamEnvImage:         UInt32 = 1001  // image well → Environment texture
let kParamEnvRatio:         UInt32 = 1002

// Velvet
let kParamVelvetUnderColor: UInt32 = 1101
let kParamVelvetRolloff:    UInt32 = 1102

// Shaders that supply an image well (need scheduleInputs)
let kImageWellParams: [Int: UInt32] = [7: kParamLUTSkinImage, 8: kParamThinFringeImage, 9: kParamEnvImage]

// MARK: - Plugin State

struct LightingPluginState {
    var shaderIndex: Int32
    var hasAuxTexture: Int32

    // Blinn / Phong / Hemisphere / EnvMap / EdgeFuzz — shared light color
    var lightR: Float; var lightG: Float; var lightB: Float

    // Phong
    var shininess: Float; var specular: Float
    var ambR: Float; var ambG: Float; var ambB: Float

    // Gooch
    var warmR: Float; var warmG: Float; var warmB: Float
    var coolR: Float; var coolG: Float; var coolB: Float
    var diffWarm: Float; var diffCool: Float

    // EdgeFuzz
    var edgeSpecularity: Float; var edgeFuzziness: Float; var edgeFade: Float
    var edgeColorR: Float; var edgeColorG: Float; var edgeColorB: Float
    var surfaceColorR: Float; var surfaceColorG: Float; var surfaceColorB: Float
    var ambientColorR: Float; var ambientColorG: Float; var ambientColorB: Float

    // GlossyWet
    var glossSpecExp: Float; var glossSpec: Float
    var glossMax: Float; var glossMin: Float; var glossDrop: Float
    var specColorR: Float; var specColorG: Float; var specColorB: Float
    var diffColorR: Float; var diffColorG: Float; var diffColorB: Float
    var glossAmbR: Float; var glossAmbG: Float; var glossAmbB: Float

    // LambSkin
    var lambRolloff: Float
    var lambAmbR: Float; var lambAmbG: Float; var lambAmbB: Float
    var lambDiffR: Float; var lambDiffG: Float; var lambDiffB: Float
    var lambSubR: Float; var lambSubG: Float; var lambSubB: Float

    // LUTSkin
    var lutDiffR: Float; var lutDiffG: Float; var lutDiffB: Float
    var lutSpecR: Float; var lutSpecG: Float; var lutSpecB: Float

    // ThinFilm
    var filmDepth: Float

    // EnvMap
    var envRatio: Float

    // Velvet
    var velvetRolloff: Float
    var velvetUnderR: Float; var velvetUnderG: Float; var velvetUnderB: Float
}

// MARK: - Plugin

@objc(LightingModelsPlugIn)
class LightingModelsPlugIn: NSObject, FxTileableEffect {

    let _apiManager: PROAPIAccessing

    required init?(apiManager: PROAPIAccessing) {
        _apiManager = apiManager
    }

    // MARK: Helpers

    private func creationAPI() -> FxParameterCreationAPI_v5 {
        return _apiManager.api(for: FxParameterCreationAPI_v5.self) as! FxParameterCreationAPI_v5
    }
    private func retrievalAPI() -> FxParameterRetrievalAPI_v6? {
        return _apiManager.api(for: FxParameterRetrievalAPI_v6.self) as? FxParameterRetrievalAPI_v6
    }

    private func addColor(_ p: FxParameterCreationAPI_v5,
                          name: String, id: UInt32,
                          r: Double, g: Double, b: Double) {
        p.addColorParameter(withName: name, parameterID: id,
                            defaultRed: r, defaultGreen: g, defaultBlue: b,
                            parameterFlags: FxParameterFlags(kFxParameterFlag_DEFAULT))
    }

    private func addSlider(_ p: FxParameterCreationAPI_v5,
                           name: String, id: UInt32,
                           def: Double, min: Double, max: Double,
                           sMin: Double, sMax: Double, delta: Double) {
        p.addFloatSlider(withName: name, parameterID: id,
                         defaultValue: def, parameterMin: min, parameterMax: max,
                         sliderMin: sMin, sliderMax: sMax, delta: delta,
                         parameterFlags: FxParameterFlags(kFxParameterFlag_DEFAULT))
    }

    // MARK: Parameters

    func addParameters() throws {
        let p = creationAPI()
        let show    = FxParameterFlags(kFxParameterFlag_DEFAULT)
        let notAnim = FxParameterFlags(kFxParameterFlag_NOT_ANIMATABLE)

        // ── Shader selector ──────────────────────────────────────────────
        let shaderNames = ["Blinn", "Phong Point Light", "Gooch", "Edge Fuzz",
                           "Glossy Wet Highlight", "Hemisphere", "Lamb Skin",
                           "LUT Skin", "Thin Film", "Environment Map", "Velvet"]
        p.addPopupMenu(withName: "Shader Model", parameterID: kParamShaderSelect,
                       defaultValue: 1, menuEntries: shaderNames,
                       parameterFlags: FxParameterFlags(kFxParameterFlag_NOT_ANIMATABLE))

        // ── Blinn ─────────────────────────────────────────────────────────
        p.startParameterSubGroup("Blinn", parameterID: kGroupBlinn, parameterFlags: show)
            addColor(p, name: "Light Color", id: kParamBlinnLightColor, r: 1, g: 1, b: 1)
        p.endParameterSubGroup()

        // ── Phong ────────────────────────────────────────────────────────
        p.startParameterSubGroup("Phong", parameterID: kGroupPhong, parameterFlags: show)
            addColor(p, name: "Light Color",   id: kParamPhongLightColor,   r: 1,   g: 1,   b: 1)
            addColor(p, name: "Ambient Color", id: kParamPhongAmbientColor, r: 0.1, g: 0.1, b: 0.1)
            addSlider(p, name: "Shininess", id: kParamPhongShininess,
                      def: 32, min: 1, max: 256, sMin: 1, sMax: 128, delta: 1)
            addSlider(p, name: "Specular", id: kParamPhongSpecular,
                      def: 0.5, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
        p.endParameterSubGroup()

        // ── Gooch ────────────────────────────────────────────────────────
        p.startParameterSubGroup("Gooch", parameterID: kGroupGooch, parameterFlags: show)
            addColor(p, name: "Warm Color", id: kParamGoochWarmColor, r: 0.8, g: 0.4, b: 0.0)
            addColor(p, name: "Cool Color", id: kParamGoochCoolColor, r: 0.0, g: 0.2, b: 0.6)
            addSlider(p, name: "Diffuse Warm", id: kParamGoochDiffWarm,
                      def: 0.45, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
            addSlider(p, name: "Diffuse Cool", id: kParamGoochDiffCool,
                      def: 0.45, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
        p.endParameterSubGroup()

        // ── EdgeFuzz ─────────────────────────────────────────────────────
        p.startParameterSubGroup("Edge Fuzz", parameterID: kGroupEdgeFuzz, parameterFlags: show)
            addColor(p, name: "Light Color",   id: kParamEdgeLightColor,   r: 1,   g: 1,   b: 1)
            addColor(p, name: "Edge Color",    id: kParamEdgeEdgeColor,    r: 0,   g: 0,   b: 0)
            addColor(p, name: "Surface Color", id: kParamEdgeSurfaceColor, r: 0.7, g: 0.7, b: 0.7)
            addColor(p, name: "Ambient Color", id: kParamEdgeAmbientColor, r: 0.1, g: 0.1, b: 0.1)
            addSlider(p, name: "Specularity", id: kParamEdgeSpecularity,
                      def: 10, min: 0, max: 100, sMin: 0, sMax: 50, delta: 0.5)
            addSlider(p, name: "Fuzziness", id: kParamEdgeFuzziness,
                      def: 3, min: 0.1, max: 20, sMin: 0.1, sMax: 10, delta: 0.1)
            addSlider(p, name: "Edge Fade", id: kParamEdgeFade,
                      def: 0.5, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
        p.endParameterSubGroup()

        // ── GlossyWet ────────────────────────────────────────────────────
        p.startParameterSubGroup("Glossy Wet", parameterID: kGroupGlossyWet, parameterFlags: show)
            addColor(p, name: "Specular Color", id: kParamGlossSpecColor, r: 1,    g: 1,    b: 1)
            addColor(p, name: "Diffuse Color",  id: kParamGlossDiffColor, r: 0.5,  g: 0.5,  b: 0.5)
            addColor(p, name: "Ambient Color",  id: kParamGlossAmbColor,  r: 0.05, g: 0.05, b: 0.05)
            addSlider(p, name: "Specular Exponent", id: kParamGlossSpecExp,
                      def: 64, min: 1, max: 512, sMin: 1, sMax: 256, delta: 1)
            addSlider(p, name: "Specularity", id: kParamGlossSpec,
                      def: 0.8, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
            addSlider(p, name: "Gloss Max", id: kParamGlossMax,
                      def: 0.95, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
            addSlider(p, name: "Gloss Min", id: kParamGlossMin,
                      def: 0.5, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
            addSlider(p, name: "Gloss Drop", id: kParamGlossDrop,
                      def: 0.1, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
        p.endParameterSubGroup()

        // ── Hemisphere ───────────────────────────────────────────────────
        p.startParameterSubGroup("Hemisphere", parameterID: kGroupHemisphere, parameterFlags: show)
            addColor(p, name: "Sky Color",    id: kParamHemiSkyColor,    r: 0.4, g: 0.6, b: 1.0)
            addColor(p, name: "Ground Color", id: kParamHemiGroundColor, r: 0.2, g: 0.15, b: 0.1)
        p.endParameterSubGroup()

        // ── LambSkin ─────────────────────────────────────────────────────
        p.startParameterSubGroup("Lamb Skin", parameterID: kGroupLambSkin, parameterFlags: show)
            addColor(p, name: "Ambient Color",   id: kParamLambAmbientColor, r: 0.05, g: 0.05, b: 0.05)
            addColor(p, name: "Diffuse Color",   id: kParamLambDiffuseColor, r: 0.8,  g: 0.6,  b: 0.5)
            addColor(p, name: "Subsurface Color",id: kParamLambSubColor,     r: 0.8,  g: 0.2,  b: 0.1)
            addSlider(p, name: "Rolloff", id: kParamLambRolloff,
                      def: 0.3, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
        p.endParameterSubGroup()

        // ── LUTSkin ──────────────────────────────────────────────────────
        p.startParameterSubGroup("LUT Skin", parameterID: kGroupLUTSkin, parameterFlags: show)
            addColor(p, name: "Diffuse Color",  id: kParamLUTDiffuseColor,  r: 0.9, g: 0.7, b: 0.6)
            addColor(p, name: "Specular Color", id: kParamLUTSpecularColor, r: 0.8, g: 0.7, b: 0.6)
            p.addImageReference(withName: "Skin LUT", parameterID: kParamLUTSkinImage,
                                parameterFlags: notAnim)
        p.endParameterSubGroup()

        // ── ThinFilm ─────────────────────────────────────────────────────
        p.startParameterSubGroup("Thin Film", parameterID: kGroupThinFilm, parameterFlags: show)
            addSlider(p, name: "Film Depth", id: kParamThinFilmDepth,
                      def: 1.0, min: 0, max: 5, sMin: 0, sMax: 3, delta: 0.05)
            p.addImageReference(withName: "Fringe Map", parameterID: kParamThinFringeImage,
                                parameterFlags: notAnim)
        p.endParameterSubGroup()

        // ── EnvMap ───────────────────────────────────────────────────────
        p.startParameterSubGroup("Environment Map", parameterID: kGroupEnvMap, parameterFlags: show)
            p.addImageReference(withName: "Environment", parameterID: kParamEnvImage,
                                parameterFlags: notAnim)
            addSlider(p, name: "Mix Ratio", id: kParamEnvRatio,
                      def: 0.5, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
        p.endParameterSubGroup()

        // ── Velvet ───────────────────────────────────────────────────────
        p.startParameterSubGroup("Velvet", parameterID: kGroupVelvet, parameterFlags: show)
            addColor(p, name: "Under Color", id: kParamVelvetUnderColor, r: 0.3, g: 0.1, b: 0.1)
            addSlider(p, name: "Rolloff", id: kParamVelvetRolloff,
                      def: 0.3, min: 0, max: 1, sMin: 0, sMax: 1, delta: 0.01)
        p.endParameterSubGroup()
    }

    // MARK: Properties

    func properties(_ properties: AutoreleasingUnsafeMutablePointer<NSDictionary>?) throws {
        let props: NSDictionary = [
            kFxPropertyKey_IsThreadSafe:              NSNumber(booleanLiteral: true),
            kFxPropertyKey_MayRemapTime:              NSNumber(booleanLiteral: false),
            kFxPropertyKey_PixelTransformSupport:     NSNumber(value: kFxPixelTransform_ScaleTranslate),
            kFxPropertyKey_VariesWhenParamsAreStatic: NSNumber(booleanLiteral: true)
        ]
        properties?.pointee = props
    }

    // MARK: scheduleInputs — declare image-well textures as additional sources

    func scheduleInputs(_ inputImageRequests: AutoreleasingUnsafeMutablePointer<NSArray?>?,
                        withPluginState pluginState: Data?,
                        atTime renderTime: CMTime,
                        error outError: NSError?) -> Bool {
        // Always include source clip
        var requests: [FxImageTileRequest] = [
            FxImageTileRequest(source: kFxImageTileRequestSourceEffectClip,
                               time: renderTime,
                               includeFilters: true,
                               parameterID: 0)!
        ]

        // If shader uses an image well, schedule it too
        if let stateData = pluginState,
           stateData.count >= MemoryLayout<LightingPluginState>.size {
            let state = stateData.withUnsafeBytes {
                $0.bindMemory(to: LightingPluginState.self).baseAddress!.pointee
            }
            if let wellParamID = kImageWellParams[Int(state.shaderIndex)],
               let req = FxImageTileRequest(source: kFxImageTileRequestSourceParameter,
                                            time: renderTime,
                                            includeFilters: false,
                                            parameterID: wellParamID) {
                requests.append(req)
            }
        }
        inputImageRequests?.pointee = requests as NSArray
        return true
    }

    // MARK: Plugin State snapshot

    func pluginState(_ pluginState: AutoreleasingUnsafeMutablePointer<NSData>?,
                     at renderTime: CMTime,
                     quality qualityLevel: UInt) throws {
        guard let r = retrievalAPI() else { return }

        func f(_ id: UInt32) -> Float {
            var v = 0.0; r.getFloatValue(&v, fromParameter: id, at: renderTime); return Float(v)
        }
        func i(_ id: UInt32) -> Int32 {
            var v: Int32 = 0; r.getIntValue(&v, fromParameter: id, at: renderTime); return v
        }
        func rgb(_ id: UInt32) -> (Float, Float, Float) {
            var red = 0.0, green = 0.0, blue = 0.0
            r.getRedValue(&red, greenValue: &green, blueValue: &blue, fromParameter: id, at: renderTime)
            return (Float(red), Float(green), Float(blue))
        }

        let shaderIdx = i(kParamShaderSelect) - 1  // popup 1-based → 0-based

        let blinnLight = rgb(kParamBlinnLightColor)
        let phongLight = rgb(kParamPhongLightColor)
        let phongAmb   = rgb(kParamPhongAmbientColor)
        let goochWarm  = rgb(kParamGoochWarmColor)
        let goochCool  = rgb(kParamGoochCoolColor)
        let edgeLight  = rgb(kParamEdgeLightColor)
        let edgeEdge   = rgb(kParamEdgeEdgeColor)
        let edgeSurf   = rgb(kParamEdgeSurfaceColor)
        let edgeAmb    = rgb(kParamEdgeAmbientColor)
        let glossSpec  = rgb(kParamGlossSpecColor)
        let glossDiff  = rgb(kParamGlossDiffColor)
        let glossAmb   = rgb(kParamGlossAmbColor)
        let lambAmb    = rgb(kParamLambAmbientColor)
        let lambDiff   = rgb(kParamLambDiffuseColor)
        let lambSub    = rgb(kParamLambSubColor)
        let lutDiff    = rgb(kParamLUTDiffuseColor)
        let lutSpec    = rgb(kParamLUTSpecularColor)
        let velvetUnder = rgb(kParamVelvetUnderColor)
        let hemiSky    = rgb(kParamHemiSkyColor)

        // Hemisphere uses sky+ground color; pack sky into light and ground into amb
        let hemiGround = rgb(kParamHemiGroundColor)

        // Choose the right light color based on active shader
        var lightR: Float; var lightG: Float; var lightB: Float
        var ambR: Float;   var ambG: Float;   var ambB: Float
        switch Int(shaderIdx) {
        case ShaderID.blinn.rawValue, ShaderID.envMap.rawValue:
            (lightR, lightG, lightB) = blinnLight
            (ambR, ambG, ambB)       = (0, 0, 0)
        case ShaderID.phong.rawValue:
            (lightR, lightG, lightB) = phongLight
            (ambR, ambG, ambB)       = phongAmb
        case ShaderID.hemisphere.rawValue:
            (lightR, lightG, lightB) = hemiSky
            (ambR, ambG, ambB)       = hemiGround
        case ShaderID.edgeFuzz.rawValue:
            (lightR, lightG, lightB) = edgeLight
            (ambR, ambG, ambB)       = edgeAmb
        default:
            (lightR, lightG, lightB) = (1, 1, 1)
            (ambR, ambG, ambB)       = (0, 0, 0)
        }

        // Does this shader have an image well parameter scheduled?
        let hasAux: Int32 = kImageWellParams[Int(shaderIdx)] != nil ? 1 : 0

        var state = LightingPluginState(
            shaderIndex: shaderIdx,
            hasAuxTexture: hasAux,

            lightR: lightR, lightG: lightG, lightB: lightB,

            shininess: f(kParamPhongShininess),
            specular:  f(kParamPhongSpecular),
            ambR: ambR, ambG: ambG, ambB: ambB,

            warmR: goochWarm.0, warmG: goochWarm.1, warmB: goochWarm.2,
            coolR: goochCool.0, coolG: goochCool.1, coolB: goochCool.2,
            diffWarm: f(kParamGoochDiffWarm),
            diffCool: f(kParamGoochDiffCool),

            edgeSpecularity: f(kParamEdgeSpecularity),
            edgeFuzziness:   f(kParamEdgeFuzziness),
            edgeFade:        f(kParamEdgeFade),
            edgeColorR: edgeEdge.0, edgeColorG: edgeEdge.1, edgeColorB: edgeEdge.2,
            surfaceColorR: edgeSurf.0, surfaceColorG: edgeSurf.1, surfaceColorB: edgeSurf.2,
            ambientColorR: edgeAmb.0, ambientColorG: edgeAmb.1, ambientColorB: edgeAmb.2,

            glossSpecExp: f(kParamGlossSpecExp),
            glossSpec:    f(kParamGlossSpec),
            glossMax:     f(kParamGlossMax),
            glossMin:     f(kParamGlossMin),
            glossDrop:    f(kParamGlossDrop),
            specColorR: glossSpec.0, specColorG: glossSpec.1, specColorB: glossSpec.2,
            diffColorR: glossDiff.0, diffColorG: glossDiff.1, diffColorB: glossDiff.2,
            glossAmbR:  glossAmb.0,  glossAmbG:  glossAmb.1,  glossAmbB:  glossAmb.2,

            lambRolloff: f(kParamLambRolloff),
            lambAmbR: lambAmb.0,  lambAmbG: lambAmb.1,  lambAmbB: lambAmb.2,
            lambDiffR: lambDiff.0, lambDiffG: lambDiff.1, lambDiffB: lambDiff.2,
            lambSubR: lambSub.0,  lambSubG: lambSub.1,  lambSubB: lambSub.2,

            lutDiffR: lutDiff.0, lutDiffG: lutDiff.1, lutDiffB: lutDiff.2,
            lutSpecR: lutSpec.0, lutSpecG: lutSpec.1, lutSpecB: lutSpec.2,

            filmDepth: f(kParamThinFilmDepth),
            envRatio:  f(kParamEnvRatio),
            velvetRolloff: f(kParamVelvetRolloff),
            velvetUnderR: velvetUnder.0, velvetUnderG: velvetUnder.1, velvetUnderB: velvetUnder.2
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

        var state = stateData.withUnsafeBytes {
            $0.bindMemory(to: LightingPluginState.self).baseAddress!.pointee
        }

        // If we expected an aux texture but didn't get one, clear the flag
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
        let outputTexture = destinationImage.metalTexture(for: deviceCache.device(with: destinationImage.deviceRegistryID)!)!

        // Optional aux texture (image well)
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
