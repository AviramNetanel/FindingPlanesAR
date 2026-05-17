//
//  LoggerView.swift
//  FindingPlanesAR
//

import SwiftUI
import UIKit

struct LoggerView: View {
    @Binding var isExpanded: Bool
    @StateObject private var logger: LoggerStore
    private let soundPlayer: SoundPlaying
    @State private var enabledLevels: Set<LoggerStore.Level> = Set(LoggerStore.Level.allCases)
    @State private var copiedFeedbackVisible = false

    init(
        isExpanded: Binding<Bool>,
        logger: LoggerStore = .shared,
        soundPlayer: SoundPlaying = SoundPlayer.shared
    ) {
        _isExpanded = isExpanded
        _logger = StateObject(wrappedValue: logger)
        self.soundPlayer = soundPlayer
    }

    private var filteredEntries: [LoggerStore.Entry] {
        logger.entries.filter { enabledLevels.contains($0.level) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 8 : 6) {
            HStack(spacing: 8) {
                Button {
                    soundPlayer.play(isExpanded ? .shrink : .expand)
                    withAnimation(PanelStyle.animation) {
                        isExpanded.toggle()
                    }
                } label: {
                    if isExpanded {
                        Label("Logger", systemImage: "list.clipboard")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    } else {
                        Image(systemName: "list.clipboard.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.blue)
                            .padding(.leading, PanelStyle.headerIconLeading)
                            .padding(.trailing, PanelStyle.headerIconTrailing)
                            .padding(.vertical, PanelStyle.headerIconVertical)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)

                if isExpanded {
                    Toggle("", isOn: $logger.isEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .scaleEffect(0.8)
                        .onChange(of: logger.isEnabled) {
                            soundPlayer.play(.toggle)
                        }
                }
            }

            if isExpanded {
                HStack(spacing: 8) {
                    levelToggle(.info)
                    levelToggle(.warning)
                    levelToggle(.error)

                    Spacer(minLength: 8)

                    Button {
                        soundPlayer.play(.trash)
                        logger.clear()
                    } label: {
                        Image(systemName: "trash")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear logs")

                    Button {
                        copyLogs()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Copy logs")
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(filteredEntries.reversed()) { entry in
                            Text("[\(entry.level.rawValue)] \(entry.message)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(color(for: entry.level))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if filteredEntries.isEmpty {
                            Text("No log entries for selected filters")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(height: 140)
                .overlay(alignment: .topTrailing) {
                    if copiedFeedbackVisible {
                        Text("Copied")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .font(.caption)
        .padding(isExpanded ? 10 : 0)
        .background(
            .ultraThinMaterial,
            in: isExpanded
            ? AnyShape(RoundedRectangle(cornerRadius: PanelStyle.expandedCornerRadius))
            : AnyShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: PanelStyle.collapsedTrailingRadius, topTrailingRadius: PanelStyle.collapsedTrailingRadius))
        )
        .frame(maxWidth: isExpanded ? 420 : nil, alignment: .leading)
        .fixedSize(horizontal: !isExpanded, vertical: false)
        .frame(maxWidth: .infinity, alignment: .leading)
        .offset(x: isExpanded ? 0 : PanelStyle.collapsedOffsetX)
        .animation(PanelStyle.animation, value: isExpanded)
    }

    private func levelToggle(_ level: LoggerStore.Level) -> some View {
        Button {
            soundPlayer.play(.toggle)
            if enabledLevels.contains(level) {
                enabledLevels.remove(level)
            } else {
                enabledLevels.insert(level)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: enabledLevels.contains(level) ? "checkmark.square.fill" : "square")
                Text(level.rawValue.lowercased())
                    .textCase(.lowercase)
            }
            .font(.caption)
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }

    private func color(for level: LoggerStore.Level) -> Color {
        switch level {
        case .info: .white
        case .warning: .orange
        case .error: .red
        }
    }

    private func copyLogs() {
        soundPlayer.play(.copy)
        let text = logger.exportText(filter: enabledLevels)
        UIPasteboard.general.string = text

        copiedFeedbackVisible = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            copiedFeedbackVisible = false
        }
    }
}

#Preview {
    LoggerView(isExpanded: .constant(true), logger: .shared, soundPlayer: SoundPlayer.shared)
}
