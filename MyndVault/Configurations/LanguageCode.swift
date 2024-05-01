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
        }
    }

    var flagEmoji: String {
           switch self {
           case .german: return "🇩🇪"
           case .english: return "🇬🇧"
           case .french: return "🇫🇷"
           case .spanish: return "🇪🇸"
           case .greek: return "🇬🇷"
           }
       }
}
