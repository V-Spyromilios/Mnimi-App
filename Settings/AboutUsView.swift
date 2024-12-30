//
//  AboutUsView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 10.08.24.
//

import SwiftUI

struct AboutUsView: View {
    @State private var animate: Bool = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    let linkedInURL = URL(string: "https://www.linkedin.com/in/evangelos-spyromilios/")!
    
    
    var body: some View {
        ScrollView {
            HStack {
                TypingTextView(fullText: "Hello World!", typingSpeed: 0.1, isTitle: true)
//                    .frame(maxWidth: .infinity)
                    .padding(.leading)
//                SwiftLogo()
            }.padding(.top)
            
            
            
            LottieRepresentable(filename: "ManWithLaptop").frame(height: 180)
            
            VStack {
                Text(Constants.welcomeText)
                    .font(.headline)
//                    .font(.system(.callout))
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .padding()
                    .foregroundStyle(.primary)
                    .dynamicTypeSize(.medium ... .xxLarge)
                
                LinkedInButton(url: linkedInURL)
                builtWith().padding(.top)
            }
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
        }  .background {
            LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                .opacity(0.2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    NavigationView {
            AboutUsView()
        }
}

private func builtWith() -> some View {

    Text("Natively built with SwiftUI")
        .font(.footnote)
        .fontWeight(.semibold)
        .fontDesign(.rounded)
        .foregroundStyle(.secondary)
        .dynamicTypeSize(.medium ... .xxLarge)
        .offset(y: 7)
}

@MainActor
private func SwiftLogo() -> some View {

    HStack {
        LottieRepresentable(filename: "Swift", loopMode: .playOnce, speed: 0.3)
            .frame(width: 70, height: 70)
    }
}

struct LinkedInButton: View {
    var url: URL

    var body: some View {
        Button(action: {
            openLinkedInProfile()
        }) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
                Text("Connect with me on LinkedIn")
                    .font(.system(size: 16, weight: .semibold))
                    .fontDesign(.rounded)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
            )
        }
    }

    private func openLinkedInProfile() {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
