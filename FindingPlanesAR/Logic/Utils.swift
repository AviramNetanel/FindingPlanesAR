//
//  Utils.swift
//  FindingPlanesAR
//
//  Created by Aviram Netanel on 16/04/2026.
//

import Foundation
import QuartzCore
import Darwin.Mach


final class Utils {
  
  // Function to get Memory Usage
  static func memoryUsage() -> (used: UInt64, total: UInt64) {
    var taskInfo = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
    let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
      }
    }
    
    var used: UInt64 = 0
    if result == KERN_SUCCESS {
      used = UInt64(taskInfo.phys_footprint) / 1024 / 1024
    }
    
    let total = ProcessInfo.processInfo.physicalMemory / 1024 / 1024
    return (used, total)
  }

  // Approximate CPU usage for the current process in percent.
  static func cpuUsage() -> Double {
    var threadList: thread_act_array_t?
    var threadCount: mach_msg_type_number_t = 0

    let threadsResult = task_threads(mach_task_self_, &threadList, &threadCount)
    guard threadsResult == KERN_SUCCESS, let threadList else {
      return 0
    }

    defer {
      vm_deallocate(
        mach_task_self_,
        vm_address_t(bitPattern: threadList),
        vm_size_t(threadCount) * vm_size_t(MemoryLayout<thread_t>.stride)
      )
    }

    var totalUsageOfCPU: Double = 0

    for index in 0..<Int(threadCount) {
      var threadInfo = thread_basic_info()
      var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)

      let infoResult = withUnsafeMutablePointer(to: &threadInfo) { pointer in
        pointer.withMemoryRebound(to: integer_t.self, capacity: Int(threadInfoCount)) { intPointer in
          thread_info(
            threadList[index],
            thread_flavor_t(THREAD_BASIC_INFO),
            intPointer,
            &threadInfoCount
          )
        }
      }

      guard infoResult == KERN_SUCCESS else { continue }
      if (threadInfo.flags & TH_FLAGS_IDLE) == 0 {
        totalUsageOfCPU +=
        (Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
      }
    }

    return totalUsageOfCPU
  }
}


//MARK: -
final class FPSMonitor {
    var displayLink: CADisplayLink?
    var previousTimestamp: CFTimeInterval = 0
    var frameCount = 0
    
  static public var currentFps : Double = 0
    
    init() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    @objc func displayLinkCallback(displayLink: CADisplayLink) {
        if previousTimestamp == 0 {
            previousTimestamp = displayLink.timestamp
            return
        }
        
        frameCount += 1
        let timestamp = displayLink.timestamp
        let deltaTime = timestamp - previousTimestamp
        
        if deltaTime >= 1 {
          FPSMonitor.currentFps = Double(frameCount) / deltaTime
            frameCount = 0
            previousTimestamp = timestamp
        }
    }
}
