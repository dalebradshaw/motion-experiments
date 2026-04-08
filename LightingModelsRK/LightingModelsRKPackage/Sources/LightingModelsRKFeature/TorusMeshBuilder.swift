import RealityKit
import simd

struct TorusMeshData {
    let positions: [SIMD3<Float>]
    let normals: [SIMD3<Float>]
    let textureCoordinates: [SIMD2<Float>]
    let triangleIndices: [UInt32]
}

enum TorusMeshBuilder {
    static func makeData(
        ringRadius: Float,
        tubeRadius: Float,
        ringSegments: Int = 64,
        tubeSegments: Int = 32
    ) -> TorusMeshData {
        precondition(ringRadius > 0, "ringRadius must be positive")
        precondition(tubeRadius > 0, "tubeRadius must be positive")
        precondition(ringSegments >= 3, "ringSegments must be at least 3")
        precondition(tubeSegments >= 3, "tubeSegments must be at least 3")

        let vertexCount = (ringSegments + 1) * (tubeSegments + 1)
        let indexCount = ringSegments * tubeSegments * 6

        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var textureCoordinates: [SIMD2<Float>] = []
        var triangleIndices: [UInt32] = []

        positions.reserveCapacity(vertexCount)
        normals.reserveCapacity(vertexCount)
        textureCoordinates.reserveCapacity(vertexCount)
        triangleIndices.reserveCapacity(indexCount)

        for ringIndex in 0...ringSegments {
            let u = Float(ringIndex) / Float(ringSegments)
            let theta = u * 2 * .pi
            let cosTheta = cos(theta)
            let sinTheta = sin(theta)

            for tubeIndex in 0...tubeSegments {
                let v = Float(tubeIndex) / Float(tubeSegments)
                let phi = v * 2 * .pi
                let cosPhi = cos(phi)
                let sinPhi = sin(phi)

                let x = (ringRadius + tubeRadius * cosPhi) * cosTheta
                let y = tubeRadius * sinPhi
                let z = (ringRadius + tubeRadius * cosPhi) * sinTheta
                positions.append(SIMD3<Float>(x, y, z))

                let normal = SIMD3<Float>(cosPhi * cosTheta, sinPhi, cosPhi * sinTheta)
                normals.append(simd_normalize(normal))

                textureCoordinates.append(SIMD2<Float>(u, v))
            }
        }

        let stride = tubeSegments + 1
        for ringIndex in 0..<ringSegments {
            for tubeIndex in 0..<tubeSegments {
                let a = UInt32(ringIndex * stride + tubeIndex)
                let b = UInt32(ringIndex * stride + tubeIndex + 1)
                let c = UInt32((ringIndex + 1) * stride + tubeIndex)
                let d = UInt32((ringIndex + 1) * stride + tubeIndex + 1)

                triangleIndices.append(contentsOf: [a, b, c, b, d, c])
            }
        }

        return TorusMeshData(
            positions: positions,
            normals: normals,
            textureCoordinates: textureCoordinates,
            triangleIndices: triangleIndices
        )
    }

    @MainActor
    static func makeMeshResource(
        ringRadius: Float,
        tubeRadius: Float,
        ringSegments: Int = 64,
        tubeSegments: Int = 32
    ) throws -> MeshResource {
        let data = makeData(
            ringRadius: ringRadius,
            tubeRadius: tubeRadius,
            ringSegments: ringSegments,
            tubeSegments: tubeSegments
        )

        var descriptor = MeshDescriptor(name: "Torus")
        descriptor.positions = MeshBuffers.Positions(data.positions)
        descriptor.normals = MeshBuffers.Normals(data.normals)
        descriptor.textureCoordinates = MeshBuffers.TextureCoordinates(data.textureCoordinates)
        descriptor.primitives = .triangles(data.triangleIndices)

        return try MeshResource.generate(from: [descriptor])
    }
}
