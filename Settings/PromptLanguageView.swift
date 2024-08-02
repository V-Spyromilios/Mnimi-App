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
    @EnvironmentObject var languageSettings: LanguageSettings

    
    var body: some View {
        ScrollView {
            
            VStack(spacing: 10) {
                ForEach(LanguageCode.allCases, id: \.self) { language in
                    Button(action: {
                       
                        languageSettings.selectedLanguage = language
                    }) {
                        HStack {
                            Text(language.displayName)
                                .foregroundStyle(colorScheme == .light ? .black : Color.smoothWhite)
                            Spacer()
                            if language == languageSettings.selectedLanguage {
                                Text(language.flagEmoji).font(.title3)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background( Color.primaryBackground)
                        .cornerRadius(10)
                        .shadow(color: colorScheme == .dark ? .white : .black, radius: language == languageSettings.selectedLanguage ? 5 : 2)
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
}
#Preview {
    PromptLanguageView()
}
