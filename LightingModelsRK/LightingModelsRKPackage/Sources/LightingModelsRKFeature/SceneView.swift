import SwiftUI
import RealityKit

struct SceneView: View {
    let selectedModel: LightingModel
    let params: ShaderParams
    let modelURL: URL?
    let shape: MeshShape

    @State private var coordinator = SceneCoordinator()
    @State private var lastDragTranslation: CGSize = .zero

    var body: some View {
        RealityView { content in
            coordinator.setup()
            content.add(coordinator.root)
        } update: { _ in
            coordinator.update(
                model: selectedModel,
                params: params,
                modelURL: modelURL,
                shape: shape
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .overlay(alignment: .bottom) {
            if let errorMessage = coordinator.errorMessage {
                SceneErrorOverlay(message: errorMessage)
            }
        }
        .gesture(orbitGesture)
    }

    private var orbitGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let deltaX = Float(value.translation.width - lastDragTranslation.width)
                let deltaY = Float(value.translation.height - lastDragTranslation.height)
                coordinator.rotate(deltaX: deltaX, deltaY: deltaY)
                lastDragTranslation = value.translation
            }
            .onEnded { _ in
                lastDragTranslation = .zero
            }
    }
}

private struct SceneErrorOverlay: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.red)
            .padding(6)
            .background(.regularMaterial)
            .cornerRadius(6)
            .padding(.bottom, 8)
    }
}
