//
//  ConfigurationPanelView.swift
//  FindingPlanesAR
//

import SwiftUI

struct ConfigurationPanelView: View {
    @Binding var isExpanded: Bool
    @ObservedObject var settings: ARSettings
    @ObservedObject var controller: ARSessionController
    let soundPlayer: SoundPlaying

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    soundPlayer.play(isExpanded ? .shrink : .expand)
                    withAnimation(PanelStyle.configAnimation) {
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
                            .padding(.leading, PanelStyle.headerIconLeading)
                            .padding(.trailing, PanelStyle.headerIconTrailing)
                            .padding(.vertical, PanelStyle.headerIconVertical)
                    }
                }
                .buttonStyle(.plain)
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
            ? AnyShape(RoundedRectangle(cornerRadius: PanelStyle.configExpandedCornerRadius))
            : AnyShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: PanelStyle.collapsedTrailingRadius, topTrailingRadius: PanelStyle.collapsedTrailingRadius))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .offset(x: isExpanded ? 0 : PanelStyle.collapsedOffsetX)
        .animation(PanelStyle.configAnimation, value: isExpanded)
        .onChange(of: settings.detectHorizontalPlanes) { _ in soundPlayer.play(.toggle) }
        .onChange(of: settings.detectVerticalPlanes) { _ in soundPlayer.play(.toggle) }
        .onChange(of: settings.showPlaneOverlays) { _ in soundPlayer.play(.toggle) }
        .onChange(of: settings.showPlaneLabels) { _ in soundPlayer.play(.toggle) }
        .onChange(of: settings.showMeshOverlays) { _ in soundPlayer.play(.toggle) }
        .onChange(of: settings.classifyMeshes) { _ in soundPlayer.play(.toggle) }
        .onChange(of: settings.peopleOcclusion) { _ in soundPlayer.play(.toggle) }
        .onChange(of: settings.planeSelectionMode) { _ in soundPlayer.play(.toggle) }
    }
}

#Preview {
    ConfigurationPanelView(
        isExpanded: .constant(true),
        settings: ARSettings(),
        controller: ARSessionController(),
        soundPlayer: SoundPlayer.shared
    )
}
