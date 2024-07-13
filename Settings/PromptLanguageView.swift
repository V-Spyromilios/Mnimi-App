//
//  SettingsView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 10.02.24.
//

import SwiftUI

struct PromptLanguageView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedLanguage: LanguageCode
    
    init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedPromptLanguage"),
           let languageCode = LanguageCode(rawValue: savedLanguage) {
            _selectedLanguage = State(initialValue: languageCode)
        } else {
            _selectedLanguage = State(initialValue: .english)
        }
    }
    var body: some View {
        
        SwiftLogoView().padding()
        
        List(LanguageCode.allCases, id: \.self) { language in
            Button(action: {
                self.selectedLanguage = language
                saveLanguageSelection(language: language)
            }) {
                HStack() {
                    Text(language.displayName)
                        .foregroundStyle(colorScheme == .light ? .black : Color.smoothWhite)
                    Spacer()
                    if language == selectedLanguage {
                        
                        Text(language.flagEmoji).font(.title3)
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .contentShape(Rectangle()) // otherwise only text listens for taps and changes language.
                    .accessibilityLabel("selected Language: \(language.rawValue)")
            }
        }.padding(.top, 12)
            .buttonStyle(PlainButtonStyle())
            .background(Color.primaryBackground.ignoresSafeArea())
            .navigationTitle("Prompt Language")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("⚙️")
                    }
                }
            }
        }
    }
    
    private func saveLanguageSelection(language: LanguageCode) {
        UserDefaults.standard.set(language.rawValue, forKey: "selectedPromptLanguage")
    }
}

#Preview {
    PromptLanguageView()
}
