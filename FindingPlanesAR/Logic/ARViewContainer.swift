//
//  ARViewContainer.swift
//  FindingPlanesAR
//

import ARKit
import RealityKit
import SwiftUI
import UIKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var settings: ARSettings
    @ObservedObject var controller: ARSessionController

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        arView.renderOptions.insert(.disableMotionBlur)

        controller.attach(to: arView)
        controller.apply(settings: settings, resetTracking: true)

        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapRecognizer)
        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        controller.apply(settings: settings)
        context.coordinator.settings = settings
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller, settings: settings)
    }

    final class Coordinator: NSObject {
        weak var arView: ARView?
        let controller: ARSessionController
        var settings: ARSettings

        init(controller: ARSessionController, settings: ARSettings) {
            self.controller = controller
            self.settings = settings
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = arView else { return }
            let location = recognizer.location(in: view)
            controller.placeProbe(at: location, settings: settings)
        }
    }
}
