//
//  AboutUsView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 10.08.24.
//

import SwiftUI
import Combine

struct AboutUsView: View {
    
    @State private var cursorCancellable: AnyCancellable?
    
    private let linkedInURL: URL = URL(string: "https://www.linkedin.com/in/evangelos-spyromilios/")!
    
    @State private var typewriterText = ""
    @State private var showCursor = true
    private let fullTypewriterText = "Quietly building? Me too. Let's talk."
    
    var body: some View {
        ZStack {
            KiokuBackgroundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("The Developer")
                        .font(.custom(NewYorkFont.heavy.rawValue, size: 22))
                        .foregroundColor(.gray)
                        .fontWeight(.bold)
                        .padding(.top, 25)
                        .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                    

                    Text("""
                    I didn’t set out to build yet another app.

                    In 2021, I saw an ad for a coding school called 42 Wolfsburg. I got accepted and within weeks, I had packed my life and moved to Germany. That decision changed everything.
                    
                    Mnimi started because I kept forgetting things — ideas, details, appointments. Most note-taking apps are bloated, distracting, or built to harvest your data. I wanted something quieter. Something that respected my time and memory.

                    I’m not a big company. I’m a solo developer, self-taught, building this between raising my kids and learning as I go.

                    There are no investors here. No ads. No dark patterns. No sneaky data collection. Just a clear goal: help people think better, remember more, and stay focused in a noisy world.
                    """)
                    .font(.custom(NewYorkFont.regular.rawValue, size: 17))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(5)
                    .kiokuShadow()

                    Group {
                        if typewriterText.contains("talk") {
                            Button {
                                openLinkedInProfile()
                            } label: {
                                (
                                    Text("Quietly building? Me too. ")
                                        .font(.custom(NewYorkFont.italic.rawValue, size: 17))
                                        .foregroundColor(.black)
                                    +
                                    Text("Let's talk.")
                                        .font(.custom(NewYorkFont.italic.rawValue, size: 17))
                                        .italic()
                                        .underline()
                                        .foregroundColor(.black)
                                )
                                .kiokuShadow()
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Quietly building? Me too. Let's talk.")
                            .accessibilityHint("Opens the developer's LinkedIn profile in the browser.")
                        } else {
                            HStack(spacing: 0) {
                                Text(typewriterText)
                                    .font(.custom(NewYorkFont.italic.rawValue, size: 17))
                                    .italic()
                                    .foregroundColor(.black)
                                Text(showCursor ? "|" : " ")
                                    .font(.custom(NewYorkFont.italic.rawValue, size: 17))
                                    .foregroundColor(.black)
                                    .transition(.opacity)
                            }
                            .kiokuShadow()
                        }
                    }

                    HStack {
                        Spacer()
                        
                        Button(action: {
                            if let url = URL(string: "https://developer.apple.com/xcode/swiftui/") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            (
                                Text("Built from scratch with Apple's ")
                                    .font(.custom(NewYorkFont.italic.rawValue, size: 14))
                                    .italic()
                                    .foregroundColor(.black)
                                +
                                Text("SwiftUI.")
                                    .font(.custom(NewYorkFont.italic.rawValue, size: 14))
                                    .italic()
                                    .underline()
                                    .foregroundColor(.black)
                            
                                +
                                Text("\nNo templates. Just code, caffeine, and stubbornness.")
                                    .font(.custom(NewYorkFont.italic.rawValue, size: 14))
                                .italic()
                               
                                .foregroundColor(.black)
                                )
                            .lineSpacing(5)
                            .kiokuShadow()
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                    .padding(.top, 28)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: UIScreen.main.bounds.width, alignment: .leading)
            }.scrollIndicators(.hidden)
                .onAppear {
                    typewriterText = ""
                    showCursor = true

                    // Typewriter animation
                    let characters = Array(fullTypewriterText)
                    for i in characters.indices {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 + Double(i) * 0.1) {
                            typewriterText.append(characters[i])
                        }
                    }

                    // Start blinking cursor safely on main actor
                    cursorCancellable = Timer.publish(every: 0.4, on: .main, in: .common)
                        .autoconnect()
                        .sink { _ in
                            showCursor.toggle()
                        }
                }
        }
       
    }

    private func openLinkedInProfile() {
        if UIApplication.shared.canOpenURL(linkedInURL) {
            UIApplication.shared.open(linkedInURL)
        }
    }
}

#Preview {
    NavigationView {
        AboutUsView()
            .environment(\.locale, Locale(identifier: "en"))
    }
}
