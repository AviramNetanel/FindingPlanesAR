//
//  ARPerformanceMonitor.swift
//  FindingPlanesAR
//

import ARKit
import simd

struct ARPerformanceSnapshot: Equatable {
    var arFPSText: String = "AR: — fps"
    var frameIntervalMsText: String = "Frame: — ms"
    var featurePointsText: String = "Features: —"
    var meshDriftText: String = "Drift: —"
    var meshUpdateHzText: String = "Mesh updates: —/s"
    var performanceGradeText: String = "Quality: —"
    var grade: ARPerformanceMonitor.PerformanceGrade = .fair
    var meshDriftLevel: ARPerformanceMonitor.MeshDriftLevel = .unknown

    var isDriftGood: Bool {
        meshDriftLevel == .low || meshDriftLevel == .unknown
    }

    var isGradeGood: Bool {
        grade == .good
    }
}

@MainActor
final class ARPerformanceMonitor {
    enum MeshDriftLevel: String, Equatable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case unknown = "—"
    }

    enum PerformanceGrade: String, Equatable {
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
    }

    private let windowDuration: TimeInterval = 2.0
    private let poorARFPSThreshold = 24.0
    private let poorFrameIntervalMs = 40.0
    private let lowFeatureThreshold = 200
    private let driftLowMaxMeters: Float = 0.02
    private let driftMediumMaxMeters: Float = 0.08

    private var lastFrameTimestamp: TimeInterval?
    private var frameIntervals: [(recordedAt: TimeInterval, interval: TimeInterval)] = []
    private var lastMeshPositions: [UUID: SIMD3<Float>] = [:]
    private var driftSamples: [(recordedAt: TimeInterval, meters: Float)] = []
    private var meshUpdateTimestamps: [TimeInterval] = []
    private var featurePointCount = 0
    private var isTrackingNormal = false

    func reset() {
        lastFrameTimestamp = nil
        frameIntervals.removeAll()
        lastMeshPositions.removeAll()
        driftSamples.removeAll()
        meshUpdateTimestamps.removeAll()
        featurePointCount = 0
        isTrackingNormal = false
    }

    func record(frame: ARFrame) {
        let now = ProcessInfo.processInfo.systemUptime
        if let last = lastFrameTimestamp {
            let interval = frame.timestamp - last
            if interval > 0 {
                frameIntervals.append((recordedAt: now, interval: interval))
            }
        }
        lastFrameTimestamp = frame.timestamp
        featurePointCount = frame.rawFeaturePoints?.points.count ?? 0
        isTrackingNormal = {
            if case .normal = frame.camera.trackingState { return true }
            return false
        }()
        prune(recordedAt: now)
    }

    func recordMeshAnchorUpdate(_ anchor: ARMeshAnchor) {
        let now = ProcessInfo.processInfo.systemUptime
        meshUpdateTimestamps.append(now)

        let position = SIMD3<Float>(
            anchor.transform.columns.3.x,
            anchor.transform.columns.3.y,
            anchor.transform.columns.3.z
        )
        if let lastPosition = lastMeshPositions[anchor.identifier] {
            let drift = simd_distance(lastPosition, position)
            driftSamples.append((recordedAt: now, meters: drift))
        }
        lastMeshPositions[anchor.identifier] = position
        prune(recordedAt: now)
    }

    func removeMeshAnchor(id: UUID) {
        lastMeshPositions.removeValue(forKey: id)
    }

    func snapshot() -> ARPerformanceSnapshot {
        let arFPS = averageARFrameRate()
        let frameMs = averageFrameIntervalMs()
        let driftLevel = meshDriftLevel()
        let meshHz = meshUpdateRateHz()
        let grade = performanceGrade(arFPS: arFPS, frameMs: frameMs, driftLevel: driftLevel)

        var result = ARPerformanceSnapshot()
        result.arFPSText = arFPS.map { String(format: "AR: %.0f fps", $0) } ?? "AR: — fps"
        result.frameIntervalMsText = frameMs.map { String(format: "Frame: %.0f ms", $0) } ?? "Frame: — ms"
        result.featurePointsText = "Features: \(featurePointCount)"
        result.meshDriftText = "Drift: \(driftLevel.rawValue)"
        result.meshUpdateHzText = meshHz.map { String(format: "Mesh updates: %.0f/s", $0) } ?? "Mesh updates: —/s"
        result.performanceGradeText = "Quality: \(grade.rawValue)"
        result.grade = grade
        result.meshDriftLevel = driftLevel
        return result
    }

    private func prune(recordedAt now: TimeInterval) {
        let cutoff = now - windowDuration
        frameIntervals.removeAll { $0.recordedAt < cutoff }
        driftSamples.removeAll { $0.recordedAt < cutoff }
        meshUpdateTimestamps.removeAll { $0 < cutoff }
    }

    private func averageARFrameRate() -> Double? {
        guard !frameIntervals.isEmpty else { return nil }
        let averageInterval = frameIntervals.map(\.interval).reduce(0, +) / Double(frameIntervals.count)
        guard averageInterval > 0 else { return nil }
        return 1.0 / averageInterval
    }

    private func averageFrameIntervalMs() -> Double? {
        guard !frameIntervals.isEmpty else { return nil }
        let averageInterval = frameIntervals.map(\.interval).reduce(0, +) / Double(frameIntervals.count)
        return averageInterval * 1000.0
    }

    private func meshUpdateRateHz() -> Double? {
        guard windowDuration > 0 else { return nil }
        let count = meshUpdateTimestamps.count
        guard count > 0 else { return 0 }
        return Double(count) / windowDuration
    }

    private func meshDriftLevel() -> MeshDriftLevel {
        guard !driftSamples.isEmpty else { return .unknown }
        let maxDrift = driftSamples.map(\.meters).max() ?? 0
        if maxDrift <= driftLowMaxMeters { return .low }
        if maxDrift <= driftMediumMaxMeters { return .medium }
        return .high
    }

    private func performanceGrade(
        arFPS: Double?,
        frameMs: Double?,
        driftLevel: MeshDriftLevel
    ) -> PerformanceGrade {
        var score = 100

        if let arFPS, arFPS < poorARFPSThreshold {
            score -= 30
        } else if arFPS == nil {
            score -= 10
        }

        if let frameMs, frameMs > poorFrameIntervalMs {
            score -= 25
        }

        if featurePointCount < lowFeatureThreshold {
            score -= 20
        }

        switch driftLevel {
        case .high:
            score -= 25
        case .medium:
            score -= 10
        case .low, .unknown:
            break
        }

        if !isTrackingNormal {
            score -= 30
        }

        if score >= 70 { return .good }
        if score >= 40 { return .fair }
        return .poor
    }
}
