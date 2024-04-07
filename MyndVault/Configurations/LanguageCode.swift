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

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .german:
            return "German"
        case .spanish:
            return "Spanish"
        case .french:
            return "French"

        }
    }

    var flagEmoji: String {
           switch self {
           case .german: return "🇩🇪"
           case .english: return "🇬🇧"
           case .french: return "🇫🇷"
           case .spanish: return "🇪🇸"
           }
       }
}
