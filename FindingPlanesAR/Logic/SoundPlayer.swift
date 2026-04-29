//
//  SoundPlayer.swift
//  FindingPlanesAR
//

import AudioToolbox

enum AppSound {
    case expand
    case shrink
    case trash
    case toggle
    case reset
    case copy

    var systemSoundID: SystemSoundID {
        switch self {
        case .expand:
            return 1113
        case .shrink:
            return 1114
        case .trash:
            return 1155
        case .toggle:
            return 1104
        case .reset:
            return 1350
        case .copy:
            return 1156
        }
    }
}

protocol SoundPlaying {
    func play(_ sound: AppSound)
}

struct SystemSoundPlayer: SoundPlaying {
    func play(_ sound: AppSound) {
        AudioServicesPlaySystemSound(sound.systemSoundID)
    }
}

enum SoundPlayer {
    static let shared: SoundPlaying = SystemSoundPlayer()
}
