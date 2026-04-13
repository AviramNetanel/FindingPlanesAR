//
//  ContentView.swift
//  FindingPlanesAR
//
//  Created by Aviram Netanel on 13/04/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var settings = ARSettings()
    @StateObject private var controller = ARSessionController()
    @State private var isPanelVisible = true

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ARViewContainer(settings: settings, controller: controller)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                statusBanner
                if isPanelVisible {
                    configPanel
                }
            }
            .padding()
        }
    }

    private var statusBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(controller.meshCount)", systemImage: "arrowtriangle.up")
                    Label("\(controller.planesDetectedCount)", systemImage: "square.stack.3d.up")
                }

                Spacer(minLength: 12)

                Button(isPanelVisible ? "Hide Panel" : "Show Panel") {
                    isPanelVisible.toggle()
                }
            }

            Text(controller.meshStateText)
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                indicatorChip(title: controller.mapStateText, isGood: controller.isMapStateGood)
                indicatorChip(title: controller.trackingStateText, isGood: controller.isTrackingStateGood)
                indicatorChip(title: controller.vioStateText, isGood: controller.isVioInitialized)
            }
        }
        .font(.caption)
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var configPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Configuration")
                .font(.headline)

            Picker("Plane Mode", selection: $settings.planeSelectionMode) {
                ForEach(PlaneSelectionMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Detect Horizontal", isOn: $settings.detectHorizontalPlanes)
            Toggle("Detect Vertical", isOn: $settings.detectVerticalPlanes)
            Toggle("Show Colored Planes", isOn: $settings.showPlaneOverlays)
            Toggle("Show Plane Labels", isOn: $settings.showPlaneLabels)

            Toggle("Show Mesh Overlay", isOn: $settings.showMeshOverlays)
                .disabled(!settings.isMeshSupported)
            Toggle("Classify Mesh", isOn: $settings.classifyMeshes)
                .disabled(!settings.isMeshSupported)

            Toggle("People Occlusion", isOn: $settings.peopleOcclusion)

            Button("Reset Session") {
                controller.resetSession(using: settings)
            }
            .buttonStyle(.borderedProminent)

            Text(controller.statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .padding(12)
        .frame(maxWidth: 360)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func indicatorChip(title: String, isGood: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isGood ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(title)
                .lineLimit(1)
        }
    }
}

