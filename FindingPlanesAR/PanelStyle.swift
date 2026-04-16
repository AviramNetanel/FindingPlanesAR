//
//  PanelStyle.swift
//  FindingPlanesAR
//

import SwiftUI

enum PanelStyle {
    static let expandedCornerRadius: CGFloat = 12
    static let configExpandedCornerRadius: CGFloat = 14
    static let collapsedTrailingRadius: CGFloat = 22
    static let collapsedOffsetX: CGFloat = -16
    static let headerIconLeading: CGFloat = 8
    static let headerIconTrailing: CGFloat = 12
    static let headerIconVertical: CGFloat = 12
    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat = 4
    static let shadowOpacity: Double = 0.18
    static let animation = Animation.spring(response: 0.36, dampingFraction: 0.82)
    static let configAnimation = Animation.spring(response: 0.4, dampingFraction: 0.84)
}
