//
//  Diagnostics.swift
//  FindingPlanesAR
//

import Foundation

struct Diagnostics {
  var memory: (UInt64, UInt64)
  var cpuUsage: Double
  var state: ProcessInfo.ThermalState

  var stateString: String {
    Diagnostics.stateStringFor(self)
  }

  init() {
    memory = Utils.memoryUsage()
    cpuUsage = Utils.cpuUsage()
    state = ProcessInfo.processInfo.thermalState
  }

  static func current() -> Diagnostics {
    Diagnostics()
  }

  static func stateStringFor(_ diagnostics: Diagnostics) -> String {
    switch diagnostics.state {
    case .nominal: "nominal"
    case .fair: "fair"
    case .serious: "serious"
    case .critical: "critical"
    @unknown default:
      "default"
    }
  }
}
