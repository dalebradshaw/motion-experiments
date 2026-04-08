import SwiftUI

public struct ContentView: View {
    @State private var selectedModel: LightingModel = .blinn
    @State private var params = ShaderParams.defaults(for: .blinn)
    @State private var modelURL: URL?
    @State private var selectedShape: MeshShape = .torus

    public init() {}

    public var body: some View {
        HSplitView {
            SceneView(
                selectedModel: selectedModel,
                params: params,
                modelURL: modelURL,
                shape: selectedShape
            )
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
            resetParams(for: newModel)
        }
    }

    private func resetParams(for model: LightingModel) {
        params = ShaderParams.defaults(for: model)
    }
}
