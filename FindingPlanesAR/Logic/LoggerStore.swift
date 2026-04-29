//
//  LoggerStore.swift
//  FindingPlanesAR
//

import Foundation
import Combine

@MainActor
protocol Logging: AnyObject {
    func log(_ level: LoggerStore.Level, _ message: String)
}

@MainActor
final class LoggerStore: ObservableObject, Logging {
    static let shared = LoggerStore()

    enum Level: String, CaseIterable, Hashable {
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }

    struct Entry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: Level
        let message: String
    }

    @Published private(set) var entries: [Entry] = []
    @Published var isEnabled: Bool = true
    private let maxEntries = 300

    private init() {}

    func log(_ level: Level, _ message: String) {
        guard isEnabled else { return }
        entries.append(Entry(timestamp: Date(), level: level, message: message))
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    func clear() {
        entries.removeAll()
    }

    func exportText(filter: Set<Level>) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"

        return entries
            .filter { filter.contains($0.level) }
            .map { "[\(formatter.string(from: $0.timestamp))] [\($0.level.rawValue)] \($0.message)" }
            .joined(separator: "\n")
    }
}
