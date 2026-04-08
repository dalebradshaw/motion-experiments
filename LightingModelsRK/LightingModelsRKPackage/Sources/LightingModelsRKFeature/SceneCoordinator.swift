import Observation
import RealityKit
import SwiftUI
import os.log

private let log = Logger(subsystem: "com.dalebradshaw.LightingModelsRK", category: "Scene")

@MainActor
@Observable
final class SceneCoordinator {
    private(set) var errorMessage: String?

    let root = Entity()

    private let pivot = Entity()
    private var meshEntity: ModelEntity?
    private var didSetup = false
    private var lastKey: MaterialKey?
    private var materialTask: Task<Void, Never>?
    private var orbitYaw: Float = 0
    private var orbitPitch: Float = 0
    private var lastModelURL: URL?
    private var lastShape: MeshShape?

    func setup() {
        guard !didSetup else { return }
        didSetup = true

        root.addChild(pivot)

        let entity = makePrimitive(.torus)
        pivot.addChild(entity)
        meshEntity = entity

        addLights()
    }

    func update(model: LightingModel, params: ShaderParams, modelURL: URL?, shape: MeshShape) {
        let key = MaterialKey(model: model, params: params, modelURL: modelURL, shape: shape)
        guard key != lastKey else { return }
        lastKey = key

        let needsMeshSwap = meshNeedsSwap(url: modelURL, shape: shape)
        let needsAsyncTexture = model.usesAuxImage && params.auxImageURL != nil

        if needsMeshSwap || needsAsyncTexture {
            materialTask?.cancel()
            materialTask = Task {
                if needsMeshSwap {
                    await swapMesh(url: modelURL, shape: shape)
                }
                guard !Task.isCancelled else { return }

                do {
                    let material = try await MaterialFactory.shared.material(for: model, params: params)
                    guard !Task.isCancelled else { return }
                    applyMaterial(material)
                    errorMessage = nil
                } catch {
                    log.error("[Coord] async material error: \(error.localizedDescription, privacy: .public)")
                    errorMessage = "Material error: \(error.localizedDescription)"
                }
            }
            return
        }

        do {
            let material = try MaterialFactory.shared.materialSync(for: model, params: params)
            applyMaterial(material)
            errorMessage = nil
        } catch {
            log.error("[Coord] sync material error: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Material error: \(error.localizedDescription)"
        }
    }

    func rotate(deltaX: Float, deltaY: Float) {
        orbitYaw += deltaX * 0.01
        orbitPitch = max(-.pi / 2, min(.pi / 2, orbitPitch + deltaY * 0.01))

        let yawRotation = simd_quatf(angle: orbitYaw, axis: [0, 1, 0])
        let pitchRotation = simd_quatf(angle: orbitPitch, axis: [1, 0, 0])
        pivot.orientation = yawRotation * pitchRotation
    }

    private func addLights() {
        let keyLight = Entity()
        keyLight.components.set(DirectionalLightComponent(color: .white, intensity: 4000))
        keyLight.orientation = simd_quatf(angle: -.pi / 4, axis: [1, 0, 0])
        root.addChild(keyLight)

        let fillLight = Entity()
        fillLight.components.set(
            DirectionalLightComponent(
                color: .init(red: 0.4, green: 0.5, blue: 0.8, alpha: 1),
                intensity: 800
            )
        )
        fillLight.orientation = simd_quatf(angle: .pi / 6, axis: [0, 1, 0])
        root.addChild(fillLight)

        let pointLight = Entity()
        pointLight.components.set(
            PointLightComponent(color: .white, intensity: 3000, attenuationRadius: 5)
        )
        pointLight.position = [0, 1.5, 1]
        root.addChild(pointLight)
    }

    private func meshNeedsSwap(url: URL?, shape: MeshShape) -> Bool {
        url != lastModelURL || (url == nil && shape != lastShape)
    }

    private func swapMesh(url: URL?, shape: MeshShape) async {
        lastModelURL = url
        lastShape = shape

        meshEntity?.removeFromParent()
        meshEntity = nil

        let entity: ModelEntity
        if let url {
            do {
                let loaded = try await ModelEntity(contentsOf: url)
                let bounds = loaded.visualBounds(relativeTo: nil)
                let maxDimension = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
                if maxDimension > 0 {
                    loaded.scale = SIMD3<Float>(repeating: 0.7 / maxDimension)
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
            do {
                mesh = try TorusMeshBuilder.makeMeshResource(ringRadius: 0.25, tubeRadius: 0.1)
            } catch {
                log.error("[Coord] Torus mesh generation failed: \(error.localizedDescription, privacy: .public)")
                mesh = MeshResource.generateSphere(radius: 0.35)
            }
        case .sphere:
            mesh = MeshResource.generateSphere(radius: 0.35)
        case .box:
            mesh = MeshResource.generateBox(size: 0.5, cornerRadius: 0.03)
        case .cylinder:
            mesh = MeshResource.generateCylinder(height: 0.5, radius: 0.25)
        }

        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .init(red: 0.5, green: 0.5, blue: 0.5, alpha: 1))
        material.roughness = .init(floatLiteral: 0.4)
        material.metallic = .init(floatLiteral: 0.1)

        return ModelEntity(mesh: mesh, materials: [material])
    }

    private func applyMaterial(_ material: any RealityKit.Material) {
        guard let meshEntity else {
            log.error("[Coord] meshEntity missing while applying material")
            return
        }

        applyMaterialRecursively(material, to: meshEntity)
    }

    private func applyMaterialRecursively(_ material: any RealityKit.Material, to entity: Entity) {
        if let modelEntity = entity as? ModelEntity {
            modelEntity.model?.materials = [material]
        }

        for child in entity.children {
            applyMaterialRecursively(material, to: child)
        }
    }
}

private struct MaterialKey: Equatable {
    let model: LightingModel
    let params: ShaderParams
    let modelURL: URL?
    let shape: MeshShape
}
