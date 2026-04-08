import Foundation

enum MeshShape: String, CaseIterable, Identifiable {
    case torus = "Torus"
    case sphere = "Sphere"
    case box = "Box"
    case cylinder = "Cylinder"

    var id: String { rawValue }
}
