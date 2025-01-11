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
            
                TypingTextView(fullText: "Hello World !", typingSpeed: 0.1, isTitle: true)
                    .padding(.top, 30)
           
            
            LottieRepresentable(filename: "ManWithLaptop", loopMode: .playOnce)
                .frame(height: 140)
            
            VStack {
                Text(Constants.welcomeText)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .padding()
                    .foregroundStyle(.primary)
                    .dynamicTypeSize(.medium ... .xxLarge)
                
                CoolButton(title: "Connect with me on LinkedIn", systemImage: "link.circle.fill", action: openLinkedInProfile)
                builtWith().padding(.top, 8)
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
    
    
    private func builtWith() -> some View {
        
        Text("Natively built with SwiftUI")
            .font(.footnote)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
            .foregroundStyle(.secondary)
            .dynamicTypeSize(.medium ... .xxLarge)
//            .offset(y: 7)
    }
    
    @MainActor
    private func SwiftLogo() -> some View {
        
        HStack {
            LottieRepresentable(filename: "Swift", loopMode: .playOnce, speed: 0.3)
                .frame(width: 70, height: 70)
        }
    }
    
    private func openLinkedInProfile() {
        if UIApplication.shared.canOpenURL(linkedInURL) {
            UIApplication.shared.open(linkedInURL, options: [:], completionHandler: nil)
        }
    }
}

#Preview {
    NavigationView {
        AboutUsView()
    }
}
