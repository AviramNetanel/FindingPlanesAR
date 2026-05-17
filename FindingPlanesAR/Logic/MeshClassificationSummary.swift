//
//  MeshClassificationSummary.swift
//  FindingPlanesAR
//

import ARKit
import Metal
import simd

struct MeshAnchorClassificationSummary: Equatable {
    let anchorID: UUID
    let faceCount: Int
    let counts: [ARMeshClassification: Int]
    let dominantClassification: ARMeshClassification
}

enum MeshClassificationAnalyzer {
    static let minimumDetectedFaceCount = 10
    static let tapQueryMaxDistance: Float = 0.08

    static func summarize(_ meshAnchor: ARMeshAnchor) -> MeshAnchorClassificationSummary {
        let geometry = meshAnchor.geometry
        let faceCount = triangleFaceCount(in: geometry)
        guard faceCount > 0 else {
            return MeshAnchorClassificationSummary(
                anchorID: meshAnchor.identifier,
                faceCount: 0,
                counts: [:],
                dominantClassification: .none
            )
        }

        guard classificationSource(in: geometry) != nil else {
            return MeshAnchorClassificationSummary(
                anchorID: meshAnchor.identifier,
                faceCount: faceCount,
                counts: [:],
                dominantClassification: .none
            )
        }

        var counts: [ARMeshClassification: Int] = [:]
        for faceIndex in 0..<faceCount {
            let classification = classification(ofFaceAt: faceIndex, in: geometry)
            counts[classification, default: 0] += 1
        }

        let dominant = counts
            .filter { $0.key != .none }
            .max(by: { $0.value < $1.value })?
            .key ?? .none

        return MeshAnchorClassificationSummary(
            anchorID: meshAnchor.identifier,
            faceCount: faceCount,
            counts: counts,
            dominantClassification: dominant
        )
    }

    static func mergeCounts(_ summaries: [MeshAnchorClassificationSummary]) -> [ARMeshClassification: Int] {
        var merged: [ARMeshClassification: Int] = [:]
        for summary in summaries {
            for (classification, count) in summary.counts {
                merged[classification, default: 0] += count
            }
        }
        return merged
    }

    static func detectedSemantics(
        from counts: [ARMeshClassification: Int],
        minimumFaceCount: Int = minimumDetectedFaceCount
    ) -> [String] {
        counts
            .filter { $0.key != .none && $0.value >= minimumFaceCount }
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key.displayName < rhs.key.displayName
                }
                return lhs.value > rhs.value
            }
            .map(\.key.displayName)
    }

    static func classification(
        near worldPoint: SIMD3<Float>,
        meshAnchors: [ARMeshAnchor],
        maxDistance: Float = tapQueryMaxDistance
    ) -> ARMeshClassification? {
        var best: (classification: ARMeshClassification, distance: Float)?

        for anchor in meshAnchors {
            let inverseTransform = simd_inverse(anchor.transform)
            let localHomogeneous = inverseTransform * SIMD4<Float>(worldPoint.x, worldPoint.y, worldPoint.z, 1)
            let localPoint = SIMD3<Float>(localHomogeneous.x, localHomogeneous.y, localHomogeneous.z)
            let geometry = anchor.geometry
            let faceCount = triangleFaceCount(in: geometry)
            guard faceCount > 0 else { continue }

            for faceIndex in 0..<faceCount {
                guard let centroid = faceCentroid(faceIndex: faceIndex, in: geometry) else { continue }
                let distance = simd_distance(localPoint, centroid)
                guard distance <= maxDistance else { continue }

                let faceClassification = classification(ofFaceAt: faceIndex, in: geometry)
                guard faceClassification != .none else { continue }

                if best == nil || distance < best!.distance {
                    best = (faceClassification, distance)
                }
            }
        }

        return best?.classification
    }

    private static func classificationSource(in geometry: ARMeshGeometry) -> ARGeometrySource? {
        guard let source = geometry.classification,
              source.format == .uchar,
              source.componentsPerVector == 1 else {
            return nil
        }
        return source
    }

    private static func classification(ofFaceAt faceIndex: Int, in geometry: ARMeshGeometry) -> ARMeshClassification {
        guard let source = classificationSource(in: geometry) else { return .none }

        let pointer = source.buffer.contents()
            .advanced(by: source.offset + source.stride * faceIndex)
            .assumingMemoryBound(to: UInt8.self)
        let rawValue = Int(pointer.pointee)
        return ARMeshClassification(rawValue: rawValue) ?? .none
    }

    private static func triangleFaceCount(in geometry: ARMeshGeometry) -> Int {
        let faces = geometry.faces
        guard faces.primitiveType == .triangle, faces.indexCountPerPrimitive > 0 else { return 0 }
        return faces.count / faces.indexCountPerPrimitive
    }

    private static func faceCentroid(faceIndex: Int, in geometry: ARMeshGeometry) -> SIMD3<Float>? {
        let faces = geometry.faces
        guard faces.primitiveType == .triangle else { return nil }

        let indexOffset = faceIndex * faces.indexCountPerPrimitive
        guard indexOffset + faces.indexCountPerPrimitive <= faces.count else { return nil }

        let i0 = faceIndexBufferValue(at: indexOffset, faces: faces)
        let i1 = faceIndexBufferValue(at: indexOffset + 1, faces: faces)
        let i2 = faceIndexBufferValue(at: indexOffset + 2, faces: faces) // triangles only

        let v0 = vertex(at: i0, in: geometry.vertices)
        let v1 = vertex(at: i1, in: geometry.vertices)
        let v2 = vertex(at: i2, in: geometry.vertices)
        return (v0 + v1 + v2) / 3
    }

    private static func faceIndexBufferValue(at offset: Int, faces: ARGeometryElement) -> Int {
        let pointer = faces.buffer.contents()
        switch faces.bytesPerIndex {
        case 2:
            return Int(pointer.advanced(by: offset * MemoryLayout<UInt16>.size).assumingMemoryBound(to: UInt16.self).pointee)
        case 4:
            return Int(pointer.advanced(by: offset * MemoryLayout<UInt32>.size).assumingMemoryBound(to: UInt32.self).pointee)
        default:
            return 0
        }
    }

    private static func vertex(at index: Int, in source: ARGeometrySource) -> SIMD3<Float> {
        let pointer = source.buffer.contents()
            .advanced(by: source.offset + source.stride * index)
            .assumingMemoryBound(to: SIMD3<Float>.self)
        return pointer.pointee
    }
}

extension ARMeshClassification {
    var displayName: String {
        switch self {
        case .none: return "none"
        case .wall: return "wall"
        case .floor: return "floor"
        case .ceiling: return "ceiling"
        case .table: return "table"
        case .seat: return "seat"
        case .door: return "door"
        case .window: return "window"
        @unknown default: return "unknown"
        }
    }
}
