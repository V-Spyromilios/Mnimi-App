//
//  SettingsView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 10.02.24.
//

import SwiftUI

struct PromptLanguageView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var languageSettings: LanguageSettings

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Image("oldPaper")
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 1)
                    .opacity(0.85)
                    .ignoresSafeArea()

                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.6), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 17) {
                        ForEach(LanguageCode.allCases, id: \.self) { language in
                            Button(action: {
                                languageSettings.selectedLanguage = language
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    dismiss()
                                }
                            }) {
                                HStack {
                                    Text(language.displayName)
                                        .font(.custom("New York", size: 18))
                                        .foregroundStyle(.black)
                                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                                        .underline(language == languageSettings.selectedLanguage, color: .black)
                                        .animation(.easeInOut(duration: 0.2), value: languageSettings.selectedLanguage)

                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.clear)
                                )
                                
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: UIScreen.main.bounds.width)
                }
            }
        }
    }
}
#Preview {
    let languageSettings = LanguageSettings.shared
    PromptLanguageView()
        .environmentObject(languageSettings)
}
