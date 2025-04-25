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
                VStack(alignment: .leading, spacing: 24) {
                    Text("About Kioku")
                        .font(.custom("New York", size: 28))
                        .fontWeight(.bold)
                        .padding(.top, 30)

                    Text("This app is more than just a project—it’s a reflection of my journey. Transitioning into software development later in life wasn’t easy, but it was driven by a desire to create meaningful, distraction-free tools in a world of digital noise. Kioku was built with digital minimalism in mind, designed to help you store and retrieve your thoughts effortlessly, without stealing your attention.\n\nNo ads, no notifications, no personal data collection.\n\nJust a simple, elegant interface that empowers you to remember what matters.")
                        .font(.custom("NewYork-RegularItalic", size: 17))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)

                    Button {
                        openLinkedInProfile()
                    } label: {
                        HStack {
                            Image(systemName: "link.circle.fill")
                            Text("Connect with me on LinkedIn")
                        }
                    }
                    .kiokuButton()

                    Text("Natively built with SwiftUI")
                        .font(.footnote)
                        .italic()
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 500, alignment: .leading)
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
            .environment(\.locale, Locale(identifier: "de"))
    }
}
