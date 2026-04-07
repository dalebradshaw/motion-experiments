import SwiftUI
import RealityKit
import AppKit
import os.log

private let log = Logger(subsystem: "com.dalebradshaw.LightingModelsRK", category: "Scene")

// MARK: - Mesh shape enum

enum MeshShape: String, CaseIterable, Identifiable {
    case torus    = "Torus"
    case sphere   = "Sphere"
    case box      = "Box"
    case cylinder = "Cylinder"

    var id: String { rawValue }
}

// MARK: - Main ContentView

public struct ContentView: View {
    @State private var selectedModel: LightingModel = .blinn
    @State private var params: ShaderParams = ShaderParams.defaults(for: .blinn)
    @State private var modelURL: URL? = nil
    @State private var selectedShape: MeshShape = .torus

    public init() {}

    public var body: some View {
        HSplitView {
            SceneView(selectedModel: selectedModel, params: params,
                      modelURL: modelURL, shape: selectedShape)
                .frame(minWidth: 400, minHeight: 400)

            ControlPanel(
                selectedModel: $selectedModel,
                params: $params,
                modelURL: $modelURL,
                selectedShape: $selectedShape
            )
            .frame(width: 300)
            .padding()
        }
        .frame(minWidth: 720, minHeight: 450)
        .onChange(of: selectedModel) { _, newModel in
            params = ShaderParams.defaults(for: newModel)
        }
    }
}

// MARK: - Scene coordinator (stable across re-renders)

@MainActor
final class SceneCoordinator: ObservableObject {
    // Published so the view can show error messages
    @Published var errorMessage: String? = nil

    // Scene graph — set once in setup(), never replaced
    let root      = Entity()
    let pivot     = Entity()   // rotated by orbit gesture
    var meshEntity: ModelEntity? = nil

    // Track last-applied state so we can skip redundant rebuilds
    private var lastKey: MaterialKey? = nil
    private var materialTask: Task<Void, Never>? = nil

    func setup() {
        log.error("[Coord] setup() called")
        // Pivot sits inside root; mesh sits inside pivot
        root.addChild(pivot)

        let entity = makePrimitive(.torus)
        pivot.addChild(entity)
        meshEntity = entity

        // Key light
        let dirLight = Entity()
        dirLight.components.set(DirectionalLightComponent(color: .white, intensity: 4000))
        dirLight.orientation = simd_quatf(angle: -.pi / 4, axis: [1, 0, 0])
        root.addChild(dirLight)

        // Fill light
        let fillLight = Entity()
        fillLight.components.set(DirectionalLightComponent(
            color: .init(red: 0.4, green: 0.5, blue: 0.8, alpha: 1), intensity: 800))
        fillLight.orientation = simd_quatf(angle: .pi / 6, axis: [0, 1, 0])
        root.addChild(fillLight)

        // Point light
        let ptLight = Entity()
        ptLight.components.set(PointLightComponent(color: .white, intensity: 3000, attenuationRadius: 5))
        ptLight.position = [0, 1.5, 1]
        root.addChild(ptLight)
    }

    /// Called whenever selectedModel, params, modelURL, or shape changes.
    /// Material is applied synchronously when possible; only goes async for texture/mesh loads.
    func update(model: LightingModel, params: ShaderParams, modelURL: URL?, shape: MeshShape) {
        let key = MaterialKey(model: model, params: params, modelURL: modelURL, shape: shape)
        guard key != lastKey else { return }
        let oldKey = lastKey
        lastKey = key

        let needsMeshSwap = meshNeedsSwap(for: modelURL) || (oldKey?.shape != shape && modelURL == nil)
        let needsAsyncTexture = model.usesAuxImage && params.auxImageURL != nil

        if needsMeshSwap || needsAsyncTexture {
            // Async path — mesh swap or texture loading required
            materialTask?.cancel()
            materialTask = Task {
                if needsMeshSwap { await swapMesh(url: modelURL, shape: shape) }
                guard !Task.isCancelled else { return }
                do {
                    let mat = try await MaterialFactory.shared.material(for: model, params: params)
                    guard !Task.isCancelled else { return }
                    applyMaterial(mat)
                } catch {
                    log.error("[Coord] async material error: \(error)")
                    errorMessage = "Material error: \(error.localizedDescription)"
                }
            }
        } else {
            // Synchronous path — no I/O needed, apply immediately
            do {
                let mat = try MaterialFactory.shared.materialSync(for: model, params: params)
                applyMaterial(mat)
                errorMessage = nil
            } catch {
                log.error("[Coord] sync material error: \(error)")
                errorMessage = "Material error: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Orbit

    private var orbitYaw: Float = 0
    private var orbitPitch: Float = 0

    func rotate(deltaX: Float, deltaY: Float) {
        orbitYaw   += deltaX * 0.01
        orbitPitch  = max(-.pi / 2, min(.pi / 2, orbitPitch + deltaY * 0.01))
        let q = simd_quatf(angle: orbitYaw,   axis: [0, 1, 0])
                * simd_quatf(angle: orbitPitch, axis: [1, 0, 0])
        pivot.orientation = q
    }

    // MARK: - Private helpers

    private func applyMaterial(_ mat: any RealityKit.Material) {
        if let entity = meshEntity {
            applyMaterialRecursive(mat, to: entity)
        } else {
            log.error("[Coord] ERROR: meshEntity is nil at apply time!")
        }
    }

    private var lastModelURL: URL? = nil
    private var lastShape: MeshShape? = nil
    private func meshNeedsSwap(for url: URL?) -> Bool {
        url != lastModelURL
    }

    private func swapMesh(url: URL?, shape: MeshShape) async {
        lastModelURL = url
        lastShape = shape

        if let old = meshEntity {
            old.removeFromParent()
            meshEntity = nil
        }

        let entity: ModelEntity
        if let url {
            do {
                let loaded = try await ModelEntity(contentsOf: url)
                let bounds = loaded.visualBounds(relativeTo: nil)
                let maxDim = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
                if maxDim > 0 {
                    loaded.scale = SIMD3<Float>(repeating: 0.7 / maxDim)
                }
                entity = loaded
                errorMessage = nil
            } catch {
                errorMessage = "USDZ load error: \(error.localizedDescription)"
                entity = makePrimitive(shape)
            }
        } else {
            entity = makePrimitive(shape)
        }

        pivot.addChild(entity)
        meshEntity = entity
    }

    private func makePrimitive(_ shape: MeshShape) -> ModelEntity {
        let mesh: MeshResource
        switch shape {
        case .torus:
            mesh = Self.generateTorus(ringRadius: 0.25, tubeRadius: 0.1)
        case .sphere:
            mesh = MeshResource.generateSphere(radius: 0.35)
        case .box:
            mesh = MeshResource.generateBox(size: 0.5, cornerRadius: 0.03)
        case .cylinder:
            mesh = MeshResource.generateCylinder(height: 0.5, radius: 0.25)
        }
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: .init(red: 0.5, green: 0.5, blue: 0.5, alpha: 1))
        mat.roughness = .init(floatLiteral: 0.4)
        mat.metallic = .init(floatLiteral: 0.1)
        return ModelEntity(mesh: mesh, materials: [mat])
    }

    /// Procedural torus mesh — ringRadius is center-of-tube to origin, tubeRadius is tube cross-section.
    static func generateTorus(ringRadius: Float, tubeRadius: Float,
                              ringSegments: Int = 64, tubeSegments: Int = 32) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals:   [SIMD3<Float>] = []
        var uvs:       [SIMD2<Float>] = []
        var indices:   [UInt32]       = []

        for i in 0...ringSegments {
            let u = Float(i) / Float(ringSegments)
            let theta = u * 2.0 * .pi
            let cosTheta = cos(theta)
            let sinTheta = sin(theta)

            for j in 0...tubeSegments {
                let v = Float(j) / Float(tubeSegments)
                let phi = v * 2.0 * .pi
                let cosPhi = cos(phi)
                let sinPhi = sin(phi)

                let x = (ringRadius + tubeRadius * cosPhi) * cosTheta
                let y = tubeRadius * sinPhi
                let z = (ringRadius + tubeRadius * cosPhi) * sinTheta

                positions.append(SIMD3<Float>(x, y, z))

                let nx = cosPhi * cosTheta
                let ny = sinPhi
                let nz = cosPhi * sinTheta
                normals.append(SIMD3<Float>(nx, ny, nz))

                uvs.append(SIMD2<Float>(u, v))
            }
        }

        let stride = tubeSegments + 1
        for i in 0..<ringSegments {
            for j in 0..<tubeSegments {
                let a = UInt32(i * stride + j)
                let b = UInt32(i * stride + j + 1)
                let c = UInt32((i + 1) * stride + j)
                let d = UInt32((i + 1) * stride + j + 1)
                // Two triangles per quad
                indices.append(contentsOf: [a, c, b,  b, c, d])
            }
        }

        var desc = MeshDescriptor(name: "Torus")
        desc.positions = MeshBuffers.Positions(positions)
        desc.normals = MeshBuffers.Normals(normals)
        desc.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        desc.primitives = .triangles(indices)

        do {
            return try MeshResource.generate(from: [desc])
        } catch {
            log.error("[Coord] Torus mesh generation failed: \(error)")
            return MeshResource.generateSphere(radius: 0.35)
        }
    }

    private func applyMaterialRecursive(_ mat: any RealityKit.Material, to entity: Entity) {
        if let me = entity as? ModelEntity {
            me.model?.materials = [mat]
        }
        for child in entity.children {
            applyMaterialRecursive(mat, to: child)
        }
    }
}

// Equatable identity for deduplication
private struct MaterialKey: Equatable {
    let model: LightingModel
    let c1: SIMD3<Float>; let c2: SIMD3<Float>
    let f1: Float; let f2: Float; let f3: Float
    let auxURL: URL?; let modelURL: URL?
    let shape: MeshShape

    init(model: LightingModel, params: ShaderParams, modelURL: URL?, shape: MeshShape) {
        self.model    = model
        c1 = params.color1; c2 = params.color2
        f1 = params.float1; f2 = params.float2; f3 = params.float3
        auxURL        = params.auxImageURL
        self.modelURL = modelURL
        self.shape    = shape
    }
}

// MARK: - RealityKit Scene View

struct SceneView: View {
    let selectedModel: LightingModel
    let params: ShaderParams
    let modelURL: URL?
    let shape: MeshShape

    @StateObject private var coordinator = SceneCoordinator()

    // Orbit drag state
    @State private var dragStart: CGPoint = .zero

    var body: some View {
        RealityView { content in
            coordinator.setup()
            content.add(coordinator.root)
        } update: { _ in
            coordinator.update(model: selectedModel, params: params, modelURL: modelURL, shape: shape)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .overlay(alignment: .bottom) {
            if let err = coordinator.errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(6)
                    .background(.regularMaterial)
                    .cornerRadius(6)
                    .padding(.bottom, 8)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    let dx = Float(value.translation.width  - dragStart.x)
                    let dy = Float(value.translation.height - dragStart.y)
                    coordinator.rotate(deltaX: dx, deltaY: dy)
                    dragStart = CGPoint(x: value.translation.width, y: value.translation.height)
                }
                .onEnded { _ in dragStart = .zero }
        )
    }
}

// MARK: - Control Panel

struct ControlPanel: View {
    @Binding var selectedModel: LightingModel
    @Binding var params: ShaderParams
    @Binding var modelURL: URL?
    @Binding var selectedShape: MeshShape

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Scene") {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Shape", selection: $selectedShape) {
                            ForEach(MeshShape.allCases) { shape in
                                Text(shape.rawValue).tag(shape)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        HStack {
                            Text(modelURL?.lastPathComponent ?? "\(selectedShape.rawValue) (built-in)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                        }
                        HStack {
                            Button("Load USDZ\u{2026}") { pickModel() }
                                .font(.caption)
                            if modelURL != nil {
                                Button("Reset") { modelURL = nil }
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(4)
                }

                GroupBox("Lighting Model") {
                    Picker("", selection: $selectedModel) {
                        ForEach(LightingModel.allCases) { model in
                            Text(model.rawValue).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .padding(4)
                }

                Divider()

                ShaderParamsView(model: selectedModel, params: $params)

                Spacer()
            }
        }
    }

    private func pickModel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "usdz")!,
                                     .init(filenameExtension: "reality")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK { modelURL = panel.url }
    }
}

// MARK: - Per-shader parameter controls

struct ShaderParamsView: View {
    let model: LightingModel
    @Binding var params: ShaderParams

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch model {
            case .blinn:
                ColorRow("Light Color", binding: colorBinding1)

            case .phong:
                ColorRow("Light Color", binding: colorBinding1)
                ColorRow("Ambient Color", binding: colorBinding2)
                SliderRow("Shininess", value: $params.float1, range: 1...128)
                SliderRow("Specular", value: $params.float2, range: 0...1)

            case .gooch:
                ColorRow("Warm Color", binding: colorBinding1)
                ColorRow("Cool Color", binding: colorBinding2)
                SliderRow("Diff Warm", value: $params.float1, range: 0...1)
                SliderRow("Diff Cool", value: $params.float2, range: 0...1)

            case .edgefuzz:
                ColorRow("Light Color", binding: colorBinding1)
                ColorRow("Edge Color", binding: colorBinding2)
                SliderRow("Specularity", value: $params.float1, range: 1...64)
                SliderRow("Fuzziness", value: $params.float2, range: 0.1...8)
                SliderRow("Edge Fade", value: $params.float3, range: 0...1)

            case .glossywet:
                ColorRow("Spec Color", binding: colorBinding1)
                ColorRow("Diff Color", binding: colorBinding2)
                SliderRow("Spec Exp", value: $params.float1, range: 1...128)
                SliderRow("Gloss Spec", value: $params.float2, range: 0...1)
                SliderRow("Gloss Drop", value: $params.float3, range: 0...1)

            case .hemisphere:
                ColorRow("Sky Color", binding: colorBinding1)
                ColorRow("Ground Color", binding: colorBinding2)

            case .lambskin:
                ColorRow("Diff Color", binding: colorBinding1)
                ColorRow("Ambient Color", binding: colorBinding2)
                SliderRow("Rolloff", value: $params.float1, range: 0...1)

            case .lutskin:
                ColorRow("Diff Color", binding: colorBinding1)
                ColorRow("Spec Color", binding: colorBinding2)
                ImagePickerRow("Skin LUT", url: $params.auxImageURL)

            case .thinfilm:
                SliderRow("Film Depth", value: $params.float1, range: 0.1...5)
                ImagePickerRow("Fringe Map", url: $params.auxImageURL)

            case .envmap:
                ColorRow("Light Color", binding: colorBinding1)
                SliderRow("Env Ratio", value: $params.float2, range: 0...1)
                ImagePickerRow("Env Map", url: $params.auxImageURL)

            case .velvet:
                ColorRow("Under Color", binding: colorBinding1)
                SliderRow("Rolloff", value: $params.float1, range: 0...2)
            }
        }
    }

    private var colorBinding1: Binding<Color> {
        Binding(
            get: { Color(red: Double(params.color1.x), green: Double(params.color1.y), blue: Double(params.color1.z)) },
            set: { params.color1 = simd3FromColor($0) }
        )
    }

    private var colorBinding2: Binding<Color> {
        Binding(
            get: { Color(red: Double(params.color2.x), green: Double(params.color2.y), blue: Double(params.color2.z)) },
            set: { params.color2 = simd3FromColor($0) }
        )
    }

    private func simd3FromColor(_ color: Color) -> SIMD3<Float> {
        let resolved = color.resolve(in: EnvironmentValues())
        return SIMD3<Float>(resolved.red, resolved.green, resolved.blue)
    }
}

// MARK: - Reusable control rows

struct ColorRow: View {
    let label: String
    let binding: Binding<Color>

    init(_ label: String, binding: Binding<Color>) {
        self.label = label
        self.binding = binding
    }

    var body: some View {
        HStack {
            Text(label).frame(width: 100, alignment: .leading).font(.caption)
            ColorPicker("", selection: binding).labelsHidden()
        }
    }
}

struct SliderRow: View {
    let label: String
    let value: Binding<Float>
    let range: ClosedRange<Float>

    init(_ label: String, value: Binding<Float>, range: ClosedRange<Float>) {
        self.label = label
        self.value = value
        self.range = range
    }

    var body: some View {
        HStack {
            Text(label).frame(width: 100, alignment: .leading).font(.caption)
            Slider(value: value, in: range)
            Text(String(format: "%.2f", value.wrappedValue)).font(.caption2).frame(width: 36, alignment: .trailing)
        }
    }
}

struct ImagePickerRow: View {
    let label: String
    @Binding var url: URL?

    init(_ label: String, url: Binding<URL?>) {
        self.label = label
        self._url = url
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).frame(width: 100, alignment: .leading).font(.caption)
                Button(url == nil ? "Choose Image…" : "Replace…") { pickImage() }
                    .font(.caption)
                if url != nil {
                    Button("Clear") { url = nil }
                        .font(.caption).foregroundStyle(.red)
                }
            }
            if let url {
                Text(url.lastPathComponent)
                    .font(.caption2).foregroundStyle(.secondary)
                    .lineLimit(1).truncationMode(.middle)
                    .padding(.leading, 104)
            }
        }
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK { url = panel.url }
    }
}
