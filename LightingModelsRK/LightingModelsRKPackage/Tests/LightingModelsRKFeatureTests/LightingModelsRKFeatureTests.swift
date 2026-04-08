import Testing
@testable import LightingModelsRKFeature
import simd

@Test("Torus mesh data has stable counts")
func torusMeshDataHasStableCounts() {
    let ringSegments = 8
    let tubeSegments = 6
    let data = TorusMeshBuilder.makeData(
        ringRadius: 0.25,
        tubeRadius: 0.1,
        ringSegments: ringSegments,
        tubeSegments: tubeSegments
    )

    #expect(data.positions.count == (ringSegments + 1) * (tubeSegments + 1))
    #expect(data.normals.count == data.positions.count)
    #expect(data.textureCoordinates.count == data.positions.count)
    #expect(data.triangleIndices.count == ringSegments * tubeSegments * 6)
}

@Test("Torus normals are unit length")
func torusNormalsAreUnitLength() {
    let data = TorusMeshBuilder.makeData(ringRadius: 0.25, tubeRadius: 0.1)

    for normal in data.normals {
        #expect(abs(simd_length(normal) - 1) < 0.0001)
    }
}

@Test("Torus triangle winding faces outward")
func torusTriangleWindingFacesOutward() {
    let data = TorusMeshBuilder.makeData(ringRadius: 0.25, tubeRadius: 0.1)

    for triangleStart in stride(from: 0, to: data.triangleIndices.count, by: 3) {
        let i0 = Int(data.triangleIndices[triangleStart])
        let i1 = Int(data.triangleIndices[triangleStart + 1])
        let i2 = Int(data.triangleIndices[triangleStart + 2])

        let p0 = data.positions[i0]
        let p1 = data.positions[i1]
        let p2 = data.positions[i2]
        let outwardNormal = data.normals[i0]
        let faceNormal = simd_cross(p1 - p0, p2 - p0)

        #expect(simd_dot(faceNormal, outwardNormal) > 0)
    }
}
