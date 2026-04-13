//
//  ARSessionController.swift
//  FindingPlanesAR
//

import ARKit
import Combine
import RealityKit
import UIKit

@MainActor
final class ARSessionController: NSObject, ObservableObject {
    @Published private(set) var statusText: String = "Session idle"
    @Published private(set) var planeCount: Int = 0
    @Published private(set) var meshStateText: String = "Mesh: Unknown"
    @Published private(set) var meshCount: Int = 0
    @Published private(set) var planesDetectedCount: Int = 0
    @Published private(set) var mapStateText: String = "Map: Limited"
    @Published private(set) var trackingStateText: String = "Tracking: Limited"
    @Published private(set) var vioStateText: String = "VIO: No"
    @Published private(set) var isMapStateGood: Bool = false
    @Published private(set) var isTrackingStateGood: Bool = false
    @Published private(set) var isVioInitialized: Bool = false

    private weak var arView: ARView?
    private var planeEntities: [UUID: ModelEntity] = [:]
    private var planeAnchorEntities: [UUID: AnchorEntity] = [:]
    private var planeLabelEntities: [UUID: ModelEntity] = [:]
    private var meshAnchorIDs: Set<UUID> = []
    private var showPlaneOverlays: Bool = true
    private var showPlaneLabels: Bool = true
    private var lastSessionSnapshot: SessionSettingsSnapshot?

    private struct SessionSettingsSnapshot: Equatable {
        let detectHorizontalPlanes: Bool
        let detectVerticalPlanes: Bool
        let showMeshOverlays: Bool
        let classifyMeshes: Bool
        let peopleOcclusion: Bool
    }

    func attach(to arView: ARView) {
        self.arView = arView
        arView.session.delegate = self
        arView.automaticallyConfigureSession = false
    }

    func apply(settings: ARSettings, resetTracking: Bool = false) {
        guard let arView else { return }
        let sessionSnapshot = SessionSettingsSnapshot(
            detectHorizontalPlanes: settings.detectHorizontalPlanes,
            detectVerticalPlanes: settings.detectVerticalPlanes,
            showMeshOverlays: settings.showMeshOverlays,
            classifyMeshes: settings.classifyMeshes,
            peopleOcclusion: settings.peopleOcclusion
        )

        showPlaneOverlays = settings.showPlaneOverlays
        showPlaneLabels = settings.showPlaneLabels
        applyVisualToggles()

        if !resetTracking, sessionSnapshot == lastSessionSnapshot {
            let detectionMode = settings.planeSelectionMode == .existing ? "existing" : "estimated"
            publishStatusText("Session running (\(detectionMode) planes)")
            return
        }
        lastSessionSnapshot = sessionSnapshot

        if settings.showMeshOverlays, settings.isMeshSupported {
            arView.debugOptions.insert(.showSceneUnderstanding)
        } else {
            arView.debugOptions.remove(.showSceneUnderstanding)
        }

        if settings.peopleOcclusion, ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            publishStatusText("Session running (people occlusion on)")
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = settings.configuredPlaneDetection
        configuration.environmentTexturing = .automatic

        if settings.peopleOcclusion,
           ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        }

        if settings.showMeshOverlays || settings.classifyMeshes {
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
                configuration.sceneReconstruction = .meshWithClassification
                publishMeshStateText("Mesh: Available (classified)")
            } else if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                configuration.sceneReconstruction = .mesh
                publishMeshStateText("Mesh: Available")
            } else {
                configuration.sceneReconstruction = []
                publishMeshStateText("Mesh: Unavailable on this device")
            }
        } else {
            configuration.sceneReconstruction = []
            publishMeshStateText(settings.isMeshSupported ? "Mesh: Disabled" : "Mesh: Unavailable on this device")
        }

        if resetTracking {
            clearPlaneEntities()
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        } else {
            arView.session.run(configuration, options: [])
        }

        let detectionMode = settings.planeSelectionMode == .existing ? "existing" : "estimated"
        publishStatusText("Session running (\(detectionMode) planes)")

        for entity in planeEntities.values {
            entity.isEnabled = showPlaneOverlays
        }
    }

    func resetSession(using settings: ARSettings) {
        apply(settings: settings, resetTracking: true)
    }

    func placeProbe(at screenPoint: CGPoint, settings: ARSettings) {
        guard let arView else { return }

        let target: ARRaycastQuery.Target = settings.planeSelectionMode == .existing ? .existingPlaneGeometry : .estimatedPlane
        guard let result = arView.raycast(from: screenPoint, allowing: target, alignment: .any).first else {
            return
        }

        let anchor = AnchorEntity(world: result.worldTransform)
        let marker = ModelEntity(
            mesh: .generateSphere(radius: 0.02),
            materials: [SimpleMaterial(color: .yellow, isMetallic: false)]
        )
        anchor.addChild(marker)
        arView.scene.addAnchor(anchor)
    }

    private func clearPlaneEntities() {
        for entity in planeEntities.values {
            entity.removeFromParent()
        }
        for label in planeLabelEntities.values {
            label.removeFromParent()
        }
        for anchor in planeAnchorEntities.values {
            anchor.removeFromParent()
        }
        planeEntities.removeAll()
        planeLabelEntities.removeAll()
        planeAnchorEntities.removeAll()
        meshAnchorIDs.removeAll()
        publishCounts(planes: 0, meshes: 0)
        lastSessionSnapshot = nil
    }

    private func createOrUpdatePlaneEntity(for planeAnchor: ARPlaneAnchor) {
        guard let arView else { return }

        let entity: ModelEntity
        let anchorEntity: AnchorEntity
        if let existing = planeEntities[planeAnchor.identifier] {
            entity = existing
            guard let existingAnchor = planeAnchorEntities[planeAnchor.identifier] else { return }
            anchorEntity = existingAnchor
        } else {
            entity = ModelEntity()
            planeEntities[planeAnchor.identifier] = entity
            anchorEntity = AnchorEntity(anchor: planeAnchor)
            anchorEntity.addChild(entity)
            planeAnchorEntities[planeAnchor.identifier] = anchorEntity
            arView.scene.addAnchor(anchorEntity)
        }

        let width = max(planeAnchor.extent.x, 0.01)
        let depth = max(planeAnchor.extent.z, 0.01)
        entity.model = ModelComponent(
            mesh: .generatePlane(width: width, depth: depth),
            materials: [SimpleMaterial(color: color(for: planeAnchor), isMetallic: false)]
        )
        entity.position = SIMD3<Float>(planeAnchor.center.x, 0, planeAnchor.center.z)
        entity.orientation = simd_quatf()
        entity.isEnabled = showPlaneOverlays
        upsertLabel(for: planeAnchor, in: anchorEntity)
    }

    private func removePlaneEntity(for id: UUID) {
        guard let entity = planeEntities.removeValue(forKey: id) else { return }
        entity.removeFromParent()
        planeLabelEntities[id]?.removeFromParent()
        planeLabelEntities[id] = nil
        planeAnchorEntities[id]?.removeFromParent()
        planeAnchorEntities[id] = nil
    }

    private func upsertLabel(for planeAnchor: ARPlaneAnchor, in anchorEntity: AnchorEntity) {
        let text = classificationText(for: planeAnchor.classification)
        let label: ModelEntity
        if let existing = planeLabelEntities[planeAnchor.identifier] {
            label = existing
        } else {
            label = ModelEntity()
            planeLabelEntities[planeAnchor.identifier] = label
            anchorEntity.addChild(label)
        }

        label.model = ModelComponent(
            mesh: .generateText(
                text,
                extrusionDepth: 0.002,
                font: .systemFont(ofSize: 0.12, weight: .semibold),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byTruncatingTail
            ),
            materials: [UnlitMaterial(color: .white)]
        )
        label.position = labelPosition(for: planeAnchor)
        label.scale = SIMD3<Float>(repeating: 0.2)
        label.isEnabled = showPlaneLabels
    }

    private func labelPosition(for planeAnchor: ARPlaneAnchor) -> SIMD3<Float> {
        switch planeAnchor.alignment {
        case .horizontal:
            return SIMD3<Float>(planeAnchor.center.x, 0.05, planeAnchor.center.z)
        case .vertical:
            return SIMD3<Float>(planeAnchor.center.x, 0.06, planeAnchor.center.z + 0.02)
        @unknown default:
            return SIMD3<Float>(planeAnchor.center.x, 0.05, planeAnchor.center.z)
        }
    }

    private func classificationText(for classification: ARPlaneAnchor.Classification) -> String {
        switch classification {
        case .floor: return "floor"
        case .wall: return "wall"
        case .ceiling: return "ceiling"
        case .table: return "table"
        case .seat: return "seat"
        case .door: return "door"
        case .window: return "window"
        default: return "unknown"
        }
    }

    private func applyVisualToggles() {
        for entity in planeEntities.values {
            entity.isEnabled = showPlaneOverlays
        }
        for label in planeLabelEntities.values {
            label.isEnabled = showPlaneLabels
        }
    }

    private func updatePlaneAndMeshCounts() {
        publishCounts(planes: planeEntities.count, meshes: meshAnchorIDs.count)
    }

    private func publishStatusText(_ value: String) {
        DispatchQueue.main.async { [weak self] in
            self?.statusText = value
        }
    }

    private func publishMeshStateText(_ value: String) {
        DispatchQueue.main.async { [weak self] in
            self?.meshStateText = value
        }
    }

    private func publishCounts(planes: Int, meshes: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.planeCount = planes
            self?.planesDetectedCount = planes
            self?.meshCount = meshes
        }
    }

    private func updateFrameDiagnostics(with frame: ARFrame) {
        switch frame.worldMappingStatus {
        case .mapped:
            mapStateText = "Map: Good"
            isMapStateGood = true
        case .extending:
            mapStateText = "Map: Extending"
            isMapStateGood = true
        case .limited:
            mapStateText = "Map: Limited"
            isMapStateGood = false
        case .notAvailable:
            mapStateText = "Map: N/A"
            isMapStateGood = false
        @unknown default:
            mapStateText = "Map: Unknown"
            isMapStateGood = false
        }

        switch frame.camera.trackingState {
        case .normal:
            trackingStateText = "Tracking: Nominal"
            vioStateText = "VIO: Ready"
            isTrackingStateGood = true
            isVioInitialized = true
        case .limited:
            trackingStateText = "Tracking: Limited"
            vioStateText = "VIO: No"
            isTrackingStateGood = false
            isVioInitialized = false
        case .notAvailable:
            trackingStateText = "Tracking: N/A"
            vioStateText = "VIO: No"
            isTrackingStateGood = false
            isVioInitialized = false
        }

        updateLabelFacing(with: frame)
    }

    private func updateLabelFacing(with frame: ARFrame) {
        let cameraTransform = frame.camera.transform
        let cameraPosition = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        for label in planeLabelEntities.values where label.isEnabled {
            label.look(at: cameraPosition, from: label.position(relativeTo: nil), relativeTo: nil, forward: .positiveZ)
        }
    }

    private func color(for planeAnchor: ARPlaneAnchor) -> UIColor {
        switch planeAnchor.classification {
        case .floor:
            return UIColor.systemBlue.withAlphaComponent(0.45)
        case .wall:
            return UIColor.systemGreen.withAlphaComponent(0.45)
        case .table:
            return UIColor.systemOrange.withAlphaComponent(0.45)
        case .seat:
            return UIColor.systemPurple.withAlphaComponent(0.45)
        case .ceiling:
            return UIColor.systemTeal.withAlphaComponent(0.45)
        case .window:
            return UIColor.systemCyan.withAlphaComponent(0.45)
        case .door:
            return UIColor.systemRed.withAlphaComponent(0.45)
        default:
            return UIColor.systemGray.withAlphaComponent(0.4)
        }
    }
}

extension ARSessionController: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        Task { @MainActor in
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    createOrUpdatePlaneEntity(for: planeAnchor)
                }
                if let meshAnchor = anchor as? ARMeshAnchor {
                    meshAnchorIDs.insert(meshAnchor.identifier)
                }
            }
            updatePlaneAndMeshCounts()
        }
    }

    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        Task { @MainActor in
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    createOrUpdatePlaneEntity(for: planeAnchor)
                }
                if let meshAnchor = anchor as? ARMeshAnchor {
                    meshAnchorIDs.insert(meshAnchor.identifier)
                }
            }
            updatePlaneAndMeshCounts()
        }
    }

    nonisolated func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        Task { @MainActor in
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    removePlaneEntity(for: planeAnchor.identifier)
                }
                if let meshAnchor = anchor as? ARMeshAnchor {
                    meshAnchorIDs.remove(meshAnchor.identifier)
                }
            }
            updatePlaneAndMeshCounts()
        }
    }

    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        Task { @MainActor in
            updateFrameDiagnostics(with: frame)
        }
    }
}
