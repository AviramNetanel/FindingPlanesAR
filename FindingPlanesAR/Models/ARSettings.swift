//
//  ARSettings.swift
//  FindingPlanesAR
//

import ARKit
import Combine
import Foundation

enum PlaneSelectionMode: String, CaseIterable, Identifiable {
    case existing
    case estimated

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .existing:
            return "Existing Planes"
        case .estimated:
            return "Estimated Planes"
        }
    }
}

@MainActor
final class ARSettings: ObservableObject {
    @Published var planeSelectionMode: PlaneSelectionMode = .existing
    @Published var detectHorizontalPlanes: Bool = true
    @Published var detectVerticalPlanes: Bool = true
    @Published var showPlaneOverlays: Bool = true
    @Published var showPlaneLabels: Bool = true
    @Published var showMeshOverlays: Bool = true
    @Published var classifyMeshes: Bool = true
    @Published var peopleOcclusion: Bool = false

    @Published private(set) var isMeshSupported: Bool = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)

    var configuredPlaneDetection: ARWorldTrackingConfiguration.PlaneDetection {
        var detection: ARWorldTrackingConfiguration.PlaneDetection = []
        if detectHorizontalPlanes {
            detection.insert(.horizontal)
        }
        if detectVerticalPlanes {
            detection.insert(.vertical)
        }
        return detection
    }
}
