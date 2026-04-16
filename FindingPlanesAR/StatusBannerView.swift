//
//  statusBannerView.swift
//  FindingPlanesAR
//
//  Created by Aviram Netanel on 16/04/2026.
//

import SwiftUI

struct StatusBannerView: View {
  
  @Binding var isStatusBannerExpanded : Bool
  @ObservedObject var controller: ARSessionController
  private let panelAnimation = Animation.spring(response: 0.36, dampingFraction: 0.82)
  
  var body: some View {
    VStack(alignment: .leading, spacing: isStatusBannerExpanded ? 8 : 6) {
      Button {
        withAnimation(panelAnimation) {
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
            .padding(.leading, 8)
            .padding(.trailing, 12)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 22, topTrailingRadius: 22))
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        }
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity, alignment: .leading)
      
      if isStatusBannerExpanded {
        VStack(alignment: .leading, spacing: 8) {
          HStack{
            VStack(alignment: .leading, spacing: 4) {
              Label {
                Text("\(controller.meshCount) Objects")
              } icon: {
                Image(systemName: "arrowtriangle.up")
              }
              
              Label {
                Text("\(controller.planesDetectedCount) Planes")
              } icon: {
                Image(systemName: "square.stack.3d.up")
              }
              
              Label {
                Text("\(controller.frameRateText) FPS")
              } icon: {
                Image(systemName: "gauge.with.dots.needle.33percent")
              }
            }
            
            Spacer()
            Divider()
              .frame(maxWidth: 2, maxHeight: 80)
            Spacer()
            
            
            VStack(alignment: .trailing, spacing: 8) {
              indicatorChip(title: controller.mapStateText, isGood: controller.isMapStateGood)
              indicatorChip(title: controller.trackingStateText, isGood: controller.isTrackingStateGood)
              indicatorChip(title: controller.vioStateText, isGood: controller.isVioInitialized)
            }
          }
          
          Text(controller.meshStateText)
            .font(.caption2)
            .foregroundStyle(.secondary)
          

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
      ? AnyShape(RoundedRectangle(cornerRadius: 12))
      : AnyShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 22, topTrailingRadius: 22))
    )
    .fixedSize(horizontal: !isStatusBannerExpanded, vertical: false)
    .frame(maxWidth: .infinity, alignment: .leading)
    .offset(x: isStatusBannerExpanded ? 0 : -16)
    .animation(panelAnimation, value: isStatusBannerExpanded)
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

#Preview {
  let controller = ARSessionController()
  
  StatusBannerView(isStatusBannerExpanded: .constant(true),
                   controller: controller)
}
