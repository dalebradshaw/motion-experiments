import AppKit
import SwiftUI
import UniformTypeIdentifiers

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
                            Button("Load USDZ…", action: pickModel)
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
        panel.allowedContentTypes = ["usdz", "reality"].compactMap { UTType(filenameExtension: $0) }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK else { return }
        modelURL = panel.url
    }
}
