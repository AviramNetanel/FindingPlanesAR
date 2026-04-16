//
//  ConfigurationPanelView.swift
//  FindingPlanesAR
//

import SwiftUI

struct ConfigurationPanelView: View {
    @Binding var isExpanded: Bool
    @ObservedObject var settings: ARSettings
    @ObservedObject var controller: ARSessionController

    private let panelAnimation = Animation.spring(response: 0.4, dampingFraction: 0.84)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    withAnimation(panelAnimation) {
                        isExpanded.toggle()
                    }
                } label: {
                    if isExpanded {
                        Label("Configuration", systemImage: "gear")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    } else {
                        Image(systemName: "gear.circle.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.blue)
                            .padding(.leading, 8)
                            .padding(.trailing, 12)
                            .padding(.vertical, 12)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Spacer()

                    Button {
                        controller.resetSession(using: settings)
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Reset")
                }
            }

            if isExpanded {
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

                Text(controller.statusText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .font(.subheadline)
        .padding(isExpanded ? 12 : 0)
        .frame(maxWidth: isExpanded ? 360 : nil)
        .background(
            .ultraThinMaterial,
            in: isExpanded
            ? AnyShape(RoundedRectangle(cornerRadius: 14))
            : AnyShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 22, topTrailingRadius: 22))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .offset(x: isExpanded ? 0 : -16)
        .animation(panelAnimation, value: isExpanded)
    }
}

#Preview {
    ConfigurationPanelView(
        isExpanded: .constant(true),
        settings: ARSettings(),
        controller: ARSessionController()
    )
}
