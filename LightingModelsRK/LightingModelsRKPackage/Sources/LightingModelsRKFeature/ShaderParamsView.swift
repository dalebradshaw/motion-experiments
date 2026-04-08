import AppKit
import SwiftUI

struct ShaderParamsView: View {
    let model: LightingModel
    @Binding var params: ShaderParams

    @Environment(\.self) private var environment

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
            get: {
                Color(
                    red: Double(params.color1.x),
                    green: Double(params.color1.y),
                    blue: Double(params.color1.z)
                )
            },
            set: { params.color1 = simd3(from: $0) }
        )
    }

    private var colorBinding2: Binding<Color> {
        Binding(
            get: {
                Color(
                    red: Double(params.color2.x),
                    green: Double(params.color2.y),
                    blue: Double(params.color2.z)
                )
            },
            set: { params.color2 = simd3(from: $0) }
        )
    }

    private func simd3(from color: Color) -> SIMD3<Float> {
        let resolved = color.resolve(in: environment)
        return SIMD3<Float>(
            Float(resolved.red),
            Float(resolved.green),
            Float(resolved.blue)
        )
    }
}

private struct ColorRow: View {
    let label: String
    let binding: Binding<Color>

    init(_ label: String, binding: Binding<Color>) {
        self.label = label
        self.binding = binding
    }

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 100, alignment: .leading)
                .font(.caption)
            ColorPicker("", selection: binding)
                .labelsHidden()
        }
    }
}

private struct SliderRow: View {
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
            Text(label)
                .frame(width: 100, alignment: .leading)
                .font(.caption)
            Slider(value: value, in: range)
            Text(String(format: "%.2f", value.wrappedValue))
                .font(.caption2)
                .frame(width: 36, alignment: .trailing)
        }
    }
}

private struct ImagePickerRow: View {
    let label: String
    @Binding var url: URL?

    init(_ label: String, url: Binding<URL?>) {
        self.label = label
        self._url = url
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .frame(width: 100, alignment: .leading)
                    .font(.caption)
                Button(url == nil ? "Choose Image…" : "Replace…", action: pickImage)
                    .font(.caption)
                if url != nil {
                    Button("Clear") { url = nil }
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            if let url {
                Text(url.lastPathComponent)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.leading, 104)
            }
        }
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK else { return }
        url = panel.url
    }
}
