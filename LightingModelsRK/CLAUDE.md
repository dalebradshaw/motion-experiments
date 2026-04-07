# LightingModelsRK — RealityKit Lighting Models Demo

Port of 11 Metal lighting shaders from the shelved FxPlug plugin (`~/motion-experiments/LightingModels/`)
to RealityKit using `CustomMaterial` with Metal Shading Language.

## Build

```bash
xcodebuild -workspace "$HOME/motion-experiments/LightingModelsRK/LightingModelsRK.xcworkspace" \
  -scheme LightingModelsRK -configuration Debug \
  -destination "platform=macOS,arch=arm64" build
```

App bundle: `~/Library/Developer/Xcode/DerivedData/LightingModelsRK-hcvlxvayildfedfaqiadpmhkegwb/Build/Products/Debug/LightingModelsRK.app`

## Constraints

- **No Xcode GUI** — all dev via CLI (xcodebuild)
- **macOS 15.0** deployment target (Config/Shared.xcconfig)
- **No AR/ARKit, no Reality Composer Pro, no visionOS**
- Use `CustomMaterial` (not `ShaderGraphMaterial`) for direct Metal MSL port
- Metal `.metal` files must live in the app target folder (`LightingModelsRK/`)
- Build env: macOS 26.2 Tahoe (25C58), Xcode 26.3 (17C519), Swift 6.2.4

## Project Structure

```
LightingModelsRK/
  LightingModelsRK.xcworkspace/           ← USE THIS for all builds
  LightingModelsRK.xcodeproj/
  Config/Shared.xcconfig                  ← deployment target 15.0
  LightingModelsRK/                       ← App target
    LightingModelsRKApp.swift             ← entry point (minimal)
    LightingShaders.metal                 ← all 11 shaders (~383 lines)
    Assets.xcassets/
  LightingModelsRKPackage/                ← SPM package (feature code)
    Package.swift
    Sources/LightingModelsRKFeature/
      ContentView.swift                   ← SceneCoordinator + all UI (~585 lines)
      MaterialFactory.swift               ← LightingModel enum, ShaderParams, MaterialFactory (~232 lines)
```

## Architecture

### ContentView.swift
1. `MeshShape` enum — `.torus` (default), `.sphere`, `.box`, `.cylinder`
2. `ContentView` — `@State selectedModel`, `params`, `modelURL`, `selectedShape`; passes to `SceneView` + `ControlPanel`; `onChange` resets params on model change
3. `SceneCoordinator: ObservableObject, @MainActor` — holds `root`, `pivot`, `meshEntity`; `setup()` builds scene graph; `update()` diffs `MaterialKey` and applies `CustomMaterial`; `rotate()` for orbit; `swapMesh()` for USDZ; `generateTorus()` procedural mesh
4. `MaterialKey: Equatable` — captures all shader+param+URL state for deduplication
5. `SceneView` — `RealityView` make/update; `DragGesture` for orbit
6. `ControlPanel`, `ShaderParamsView`, `ColorRow`, `SliderRow`, `ImagePickerRow` — UI controls
7. Shape picker (segmented) — torus, sphere, box, cylinder

### MaterialFactory.swift
- `baseCache: [LightingModel: CustomMaterial]` — pipeline compiled once per shader, struct-copied on reuse
- `cachedBase(for:)` — creates `CustomMaterial(from: PhysicallyBasedMaterial(), surfaceShader:)` on first call
- `materialSync(for:params:)` — clones cached base + packs params, no async
- `material(for:params:)` — async version that also loads aux textures
- `packParams()` — maps `ShaderParams` to `custom.value`, `baseColor.tint`, `emissiveColor.color`, `roughness.scale`, `metallic.scale`, `custom.texture`

## RealityKit API Notes (macOS 15+)

- `RealityView` `make:` closure on macOS: `(inout RealityViewCameraContent) async -> Void` — the content type is `RealityViewCameraContent`, NOT `RealityViewContent` (doesn't exist on macOS)
- `RealityView.update:` fires **only when the view's `let` inputs change** (passed from parent), NOT when `@State` inside the view changes
- Light API: `entity.components.set(DirectionalLightComponent(...))` and `entity.components.set(PointLightComponent(...))`. `HasDirectionalLight`/`HasPointLight` do not exist on macOS
- `CustomMaterial` texture slot: `mat.custom.texture = CustomMaterial.Texture(resource)` in Swift → `params.textures().custom()` in Metal
- `TextureResource.load(contentsOf: url)` is `async throws`
- `MTLDevice.makeDefaultLibrary()` uses `Bundle.main` — works since MaterialFactory runs in app process

## The Black Viewport Bug — RESOLVED

The sphere was rendering black when `CustomMaterial` was applied during updates.

**Root cause (two issues):**
1. **Wrong base material:** `CustomMaterial(from: UnlitMaterial(), surfaceShader:)` — shaders set PBR properties (`set_base_color`, `set_roughness`, `set_metallic`) which are meaningless on unlit base. **Fix:** Changed to `CustomMaterial(from: PhysicallyBasedMaterial(), surfaceShader:)`.
2. **Pipeline recompilation on every update:** `makeBase()` created a brand-new `CustomMaterial` (with new `SurfaceShader` handle) on every parameter change, triggering Metal pipeline recompilation → black frame. **Fix:** Added `baseCache: [LightingModel: CustomMaterial]` — pipeline-compiled base created once per model, struct-copied for param mutation.

## os.log on macOS

- `log.debug()` NOT persisted — only visible in real-time `log stream`
- `log.error()` persisted — but interpolation values show as `<private>`
- zsh `log` builtin shadows `/usr/bin/log` — always use full path
- Pattern: `/usr/bin/log show --last 30s --process LightingModelsRK --style compact`

## 11 Shaders

| Index | Name | Controls |
|-------|------|----------|
| 0 | Blinn | Light Color |
| 1 | Phong | Light Color, Ambient Color, Shininess, Specular |
| 2 | Gooch | Warm Color, Cool Color, Diffuse Warm, Diffuse Cool |
| 3 | EdgeFuzz | Light Color, Edge Color, Surface Color, Ambient Color, Specularity, Fuzziness, Edge Fade |
| 4 | GlossyWet | Specular Color, Diffuse Color, Ambient Color, Spec Exponent, Specularity, Gloss Max/Min/Drop |
| 5 | Hemisphere | Sky Color, Ground Color |
| 6 | LambSkin | Ambient Color, Diffuse Color, Subsurface Color, Rolloff |
| 7 | LUTSkin | Diffuse Color, Specular Color, Skin LUT image |
| 8 | ThinFilm | Film Depth, Fringe Map image |
| 9 | EnvMap | Environment image, Mix Ratio |
| 10 | Velvet | Under Color, Rolloff |

## Mesh Primitives

| Shape | Implementation |
|-------|---------------|
| Torus (default) | Custom procedural `MeshDescriptor` — 64 ring × 32 tube segments |
| Sphere | `MeshResource.generateSphere(radius: 0.35)` |
| Box | `MeshResource.generateBox(size: 0.5, cornerRadius: 0.03)` |
| Cylinder | `MeshResource.generateCylinder(height: 0.5, radius: 0.25)` |
| USDZ | User-loaded via open panel |

## Status

### Verified Working
- Scene graph architecture — torus renders with `CustomMaterial`
- **Blinn shader** visually verified via screenshot (lit sphere, correct highlights)
- All 11 Metal shaders compile clean
- MaterialFactory caching + sync/async paths
- Orbit gesture
- USDZ loading
- Shape picker (torus, sphere, box, cylinder)
- UI controls (model picker, color pickers, sliders, image pickers)
- Shader switching works — initial visual check looks good between shaders
- Image loading for texture-based shaders looks good

### Not Yet Visually Verified
- All 11 individual shaders rendering correctly (only Blinn screenshot-verified)
- Parameter changes don't cause black screen (code fix in place, not screenshot-verified)

## Source Reference
Original FxPlug shaders: `~/motion-experiments/LightingModels/Plugin/LightingModels.metal`
Original SceneKit GLSL: `dalebradshaw/scenekit-lighting-models`
