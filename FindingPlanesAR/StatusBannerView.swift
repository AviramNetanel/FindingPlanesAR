//
//  statusBannerView.swift
//  FindingPlanesAR
//
//  Created by Aviram Netanel on 16/04/2026.
//

import SwiftUI
import Combine

struct StatusBannerView: View {
  
  @Binding var isStatusBannerExpanded : Bool
  
  @ObservedObject var controller: ARSessionController
  let onResetTapped: () -> Void
  let soundPlayer: SoundPlaying
  @StateObject private var diagnostics = StatusBannerDiagnosticsViewModel()
  
  var body: some View {
    VStack(alignment: .leading, spacing: isStatusBannerExpanded ? 8 : 6) {
      HStack(spacing: 8) {
        Button {
          soundPlayer.play(isStatusBannerExpanded ? .shrink : .expand)
          withAnimation(PanelStyle.animation) {
            isStatusBannerExpanded.toggle()
          }
        }
        label: {
          if isStatusBannerExpanded {
            Label("Live Info", systemImage: "info.circle")
              .font(.headline)
              .foregroundStyle(.blue)
          } else {
            Image(systemName: "info.circle.fill")
              .font(.title3.weight(.semibold))
              .foregroundStyle(.blue)
              .padding(.leading, PanelStyle.headerIconLeading)
              .padding(.trailing, PanelStyle.headerIconTrailing)
              .padding(.vertical, PanelStyle.headerIconVertical)
              .background(.ultraThinMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: PanelStyle.collapsedTrailingRadius, topTrailingRadius: PanelStyle.collapsedTrailingRadius))
              .shadow(color: .black.opacity(PanelStyle.shadowOpacity), radius: PanelStyle.shadowRadius, y: PanelStyle.shadowY)
          }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)

        if isStatusBannerExpanded {
          Button {
            soundPlayer.play(.reset)
            onResetTapped()
          } label: {
            Image(systemName: "arrow.counterclockwise.circle.fill")
              .font(.title3)
              .foregroundStyle(.blue)
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Reset")
        }
      }
      
      if isStatusBannerExpanded {
        VStack(alignment: .leading, spacing: 8) {
          HStack{
            VStack(alignment: .leading, spacing: 4) {
              Label {
                Text("\(controller.userObjectCount) User Objects")
              } icon: {
                Image(systemName: "tennisball.fill")
              }

              Label {
                Text("\(controller.meshCount) Mesh Objects")
              } icon: {
                Image(systemName: "arrowtriangle.up")
              }
              
              Label {
                Text("\(controller.planesDetectedCount) Planes")
              } icon: {
                Image(systemName: "square.stack.3d.up")
              }
              
              Divider()
              
              Label {
                Text("\(diagnostics.frameRateText) FPS")
              } icon: {
                Image(systemName: "gauge.with.dots.needle.33percent")
              }

              Label {
                Text("CPU \(diagnostics.cpuUsageText)")
              } icon: {
                Image(systemName: "cpu")
              }

              Label {
                Text("Memory \(diagnostics.memoryUsageText)")
              } icon: {
                Image(systemName: "memorychip")
              }
            }

            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
              indicatorChip(title: controller.mapStateText, isGood: controller.isMapStateGood)
              indicatorChip(title: controller.trackingStateText, isGood: controller.isTrackingStateGood)
              indicatorChip(title: controller.vioStateText, isGood: controller.isVioInitialized)
              
              Text(controller.meshStateText)
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
          }
          
          
          

        }
        .transition(.move(edge: .leading).combined(with: .opacity))
      } else {
        VStack(spacing: 8) {
          statusDot(isGood: controller.isMapStateGood, size: 10)
          statusDot(isGood: controller.isTrackingStateGood, size: 10)
          statusDot(isGood: controller.isVioInitialized, size: 10)
        }
        .padding(.leading, 10)
        .padding(.trailing, 12)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.move(edge: .leading).combined(with: .opacity))
      }
    }
    .font(.caption)
    .padding(isStatusBannerExpanded ? 10 : 0)
    .background(
      .ultraThinMaterial,
      in: isStatusBannerExpanded
      ? AnyShape(RoundedRectangle(cornerRadius: PanelStyle.expandedCornerRadius))
      : AnyShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: PanelStyle.collapsedTrailingRadius, topTrailingRadius: PanelStyle.collapsedTrailingRadius))
    )
    .fixedSize(horizontal: !isStatusBannerExpanded, vertical: false)
    .frame(maxWidth: .infinity, alignment: .leading)
    .offset(x: isStatusBannerExpanded ? 0 : PanelStyle.collapsedOffsetX)
    .animation(PanelStyle.animation, value: isStatusBannerExpanded)
  }
  
  private func indicatorChip(title: String, isGood: Bool) -> some View {
    VStack(alignment: .trailing){
      HStack(spacing: 4) {
        Text(title)
          .lineLimit(1)
          .frame(alignment: .trailing)
        statusDot(isGood: isGood, size: 8)
        
      }
    }
  }
  
  private func statusDot(isGood: Bool, size: CGFloat) -> some View {
      Circle()
          .fill(isGood ? Color.green : Color.red)
          .frame(width: size, height: size)
  }
  
}

@MainActor
private final class StatusBannerDiagnosticsViewModel: ObservableObject {
  @Published private(set) var frameRateText: String = "--"
  @Published private(set) var cpuUsageText: String = "--"
  @Published private(set) var memoryUsageText: String = "--"

  private let fpsMonitor = FPSMonitor()
  private var timer: Timer?

  init() {
    refresh()
    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.refresh()
      }
    }
  }

  deinit {
    timer?.invalidate()
  }

  private func refresh() {
    frameRateText = String(Int(FPSMonitor.currentFps.rounded()))
    let current = Diagnostics.current()
    cpuUsageText = String(format: "%.0f%%", current.cpuUsage)

    let memory = current.memory
    let memoryPercent = memory.1 > 0 ? (Double(memory.0) / Double(memory.1)) * 100 : 0
    memoryUsageText = String(format: "%.0f%% (%llu/%llu MB)", memoryPercent, memory.0, memory.1)
  }
}

#Preview {
  let controller = ARSessionController()
  
  StatusBannerView(isStatusBannerExpanded: .constant(true),
                   controller: controller,
                   onResetTapped: {},
                   soundPlayer: SoundPlayer.shared)
}
