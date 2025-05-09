//
//  AboutUsView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 10.08.24.
//

import SwiftUI

struct AboutUsView: View {
    private let linkedInURL: URL = URL(string: "https://www.linkedin.com/in/evangelos-spyromilios/")!
    
    var body: some View {
        ZStack {
            KiokuBackgroundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("The Developer")
                        .font(.custom("New York", size: 28))
                        .foregroundColor(.gray)
                        .fontWeight(.bold)
                        .padding(.top, 30)
                        .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)

                    Text("This app is more than just a project—it’s a reflection of my journey.\n\nTransitioning into software development later in life wasn’t easy, but it was driven by a desire to create meaningful, distraction-free tools in a world of digital noise.\nMnimi was built with digital minimalism in mind, designed to help you store and retrieve your thoughts effortlessly, without stealing your attention.\n\nNo ads, no notifications, no personal data collection. - Just a simple, elegant interface that empowers you to remember what matters.\n\nCurious to connect? I’d love to hear from you.")
                        .font(.custom("NewYork-RegularItalic", size: 17))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                        .kiokuShadow()

                    Button {
                        openLinkedInProfile()
                    } label: {
                        Text("LinkedIn").underline().italic().fontWeight(.light).foregroundColor(.black)
                            .font(.custom("NewYork-RegularItalic", size: 17))
                            .kiokuShadow()
                    }
                    .buttonStyle(.plain)

                    HStack {
                        Spacer()
                        
                        Button(action: {
                            if let url = URL(string: "https://developer.apple.com/xcode/swiftui/") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            (
                                Text("Natively built with Apple's ")
                                    .font(.custom("NewYork-RegularItalic", size: 14))
                                    .italic()
                                    .foregroundColor(.black)
                                +
                                Text("SwiftUI")
                                    .font(.custom("NewYork-RegularItalic", size: 14))
                                    .italic()
                                    .underline()
                                    .foregroundColor(.black)
                            )
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
