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
    @State private var isStatusBannerExpanded = true
    @State private var isConfigPanelExpanded = true

    var body: some View {
        ZStack {
            ARViewContainer(settings: settings, controller: controller)
                .ignoresSafeArea()

            VStack(alignment: .leading) {
              StatusBannerView(isStatusBannerExpanded: $isStatusBannerExpanded,
                               controller: controller)
                .frame(maxWidth: .infinity, alignment: .leading)

                ConfigurationPanelView(
                    isExpanded: $isConfigPanelExpanded,
                    settings: settings,
                    controller: controller
                )
                Spacer()
                Spacer()
            }
            .padding()
        }
    }
}

//MARK: -

#Preview {
  ContentView()
}
