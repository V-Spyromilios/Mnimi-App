//
//  SettingsView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 10.02.24.
//

import SwiftUI

struct LanguageView: View {
    
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
        ScrollView {
            
            VStack(spacing: 10) {
                ForEach(LanguageCode.allCases, id: \.self) { language in
                    Button(action: {
                        self.selectedLanguage = language
                        saveLanguageSelection(language: language)
                    }) {
                        HStack {
                            Text(language.displayName)
                                .foregroundStyle(colorScheme == .light ? .black : Color.smoothWhite)
                            Spacer()
                            if language == selectedLanguage {
                                Text(language.flagEmoji).font(.title3)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background( Color.primaryBackground)
                        .cornerRadius(10)
                        .shadow(color: colorScheme == .dark ? .white : .black, radius: language == selectedLanguage ? 5 : 2)
                        .contentShape(Rectangle())
                        .accessibilityLabel("selected Language: \(language.rawValue)")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.top, 12)
            .padding(.horizontal)
        }
        .background {
            LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: backgroundSpeed, contentMode: .scaleAspectFill)
                .opacity(0.4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Settings")
                    }.font(.title2).bold().foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded).padding(.trailing, 6)
                }
            }
        }
    }
    
    private func saveLanguageSelection(language: LanguageCode) {
        UserDefaults.standard.set(language.rawValue, forKey: "selectedPromptLanguage")
    }
}
#Preview {
    LanguageView()
}
