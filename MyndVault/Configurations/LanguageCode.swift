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
    case italian = "it"
    
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
        case .italian:
            return "Italiano"
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
        case .italian: return "🇮🇹"
        }
    }
}

final class LanguageSettings: ObservableObject {
/// if the device lang is one of the LanguageCode set the selected otherwirse set to English (or last selected language by the user)
    @Published var selectedLanguage: LanguageCode = .english {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "selectedPromptLanguage")
        }
    }

    static var shared = LanguageSettings()

    init() {
            let systemLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
            
            if let savedLanguage = UserDefaults.standard.string(forKey: "selectedPromptLanguage"),
               let languageCode = LanguageCode(rawValue: savedLanguage) {
                self.selectedLanguage = languageCode
            } else if let languageCode = LanguageCode(rawValue: systemLanguageCode), LanguageCode.allCases.contains(languageCode) {
                self.selectedLanguage = languageCode
            } else {
                self.selectedLanguage = .english
            }
        }
}
