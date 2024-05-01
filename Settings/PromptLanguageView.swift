//
//  SettingsView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 10.02.24.
//

import SwiftUI

struct PromptLanguageView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var selectedLanguage: LanguageCode {
        didSet { saveLanguageSelection(language: selectedLanguage) }
    }

    init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedPromptLanguage"),
           let languageCode = LanguageCode(rawValue: savedLanguage) {
            _selectedLanguage = State(initialValue: languageCode)
        } else {
            _selectedLanguage = State(initialValue: .english)
        }
    }

    var body: some View {
        List(LanguageCode.allCases, id: \.self) { language in
            HStack {
                
                Text(language.displayName)
                if language == selectedLanguage {
                    Spacer()
                    Text(language.flagEmoji).font(.title3)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { self.selectedLanguage = language }
        }
        .navigationTitle("Prompt Language")
        .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Settings")
                            }
                        }
                    }
                }
    }

    private func saveLanguageSelection(language: LanguageCode) {
            UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
        }
}

#Preview {
    PromptLanguageView()
}
