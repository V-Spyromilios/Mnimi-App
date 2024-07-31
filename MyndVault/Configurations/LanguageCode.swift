//
//  LanguageCode.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 10.02.24.
//

import Foundation

enum LanguageCode: String, CaseIterable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case greek = "gr"
    case korean = "ko"
    case japanese = "ja"
    case chineseSimplified = "zh-Hans"
    case portuguese = "pt"
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .german:
            return "Deutsch"
        case .spanish:
            return "Español"
        case .french:
            return "Français"
        case .greek:
            return "Ελληνικά"
        case .korean:
            return "한국어"
        case .japanese:
            return "日本語"
        case .chineseSimplified:
            return "简体中文"
        case .portuguese:
            return "Português"
        }
    }
    
    var flagEmoji: String {
        switch self {
        case .german: return "🇩🇪"
        case .english: return "🇬🇧"
        case .french: return "🇫🇷"
        case .spanish: return "🇪🇸"
        case .greek: return "🇬🇷"
        case .korean: return "🇰🇷"
        case .japanese: return "🇯🇵"
        case .chineseSimplified: return "🇨🇳"
        case .portuguese: return "🇵🇹"

        }
    }
}
