//
//  KSettings.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 22.04.25.
//

import SwiftUI

struct KSettings: View {
    
    @State private var showPromptLanguage = false
    @State private var showAboutUs = false
    @State private var canShowAppSettings: Bool = true
    @State private var canShowSubscription: Bool = true
    
    var body: some View {
        ZStack {
            Image("oldPaper")
                .resizable()
                .scaledToFill()
                .blur(radius: 1)
                .opacity(0.85)
                .ignoresSafeArea()
            
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.7), Color.clear]),
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    
                    //MARK: Prompt Language
                    Button {
                        showPromptLanguage.toggle()
                    } label: {
                        HStack {
                            Text("Prompt Language")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                    .kiokuButton()
                    .sheet(isPresented: $showPromptLanguage) {
                        PromptLanguageView()
                    }
                    
                    
                    
                    //MARK: About Us
                    Button {
                        showAboutUs.toggle()
                    } label: {
                        HStack {
                            Text("About Us")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                    .kiokuButton()
                    .sheet(isPresented: $showPromptLanguage) {
                        PromptLanguageView()
                    }
                    
                    
                    //MARK: App Setting in the phone
                    if canShowAppSettings {
                        Button {
                            openAppSettings()
                        } label: {
                            Text("App General Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }.kiokuButton()
                    }
                    
                    //MARK: Manage Subsription
                    if canShowSubscription {
                        Button {
                            openSubscriptionManagement()
                        } label: {
                            Text("Manage Subscription")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }.kiokuButton()
                    }
                   //MARK: Privacy Policy
                    Button {
                        openPrivacyPolicy()
                    } label: {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                    .kiokuButton()
                    
                    
                    //MARK: Terms of Use
                    Button {
                        eula()
                    } label: {
                        Text("Terms of use")
                        Spacer()
                        Image(systemName: "chevron.right")
                    } .kiokuButton()
                    
                    //MARK: Open Support request
                    Button {
                        openSupportRequest()
                    } label: {
                        Text("Support Request")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }.kiokuButton()
                    
                    
                    //TODO: Delete Account from old Settings!
                }
                
            }
                .padding(.top, 32)
                .frame(maxWidth: 400)
        }.onAppear {
            checkOpeningSettings()
            checkOpeningSubscriptions()
        }
    }
    private func checkOpeningSettings() {
        guard let urlSettings = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(urlSettings)
        else {
            withAnimation { canShowAppSettings = false }
            return
        }
    }
    
    private func checkOpeningSubscriptions() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions"),
              UIApplication.shared.canOpenURL(url)
        else {
            withAnimation { canShowSubscription = false }
            return
        }
    }
    private func eula() {
        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openSupportRequest() {
        if let url = URL(string: "https://polydactyl-drain-3f7.notion.site/MyndVault-d74ca5df50374eada3193a64c1cee7dc?pvs=4") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://polydactyl-drain-3f7.notion.site/MyndVault-Privacy-Policy-3ddf94bced6c4481b1753cac12844f1c?pvs=4") {
            UIApplication.shared.open(url)
        }
    }
    
    
    private func openSubscriptionManagement() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func openAppSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings)
            
        }
    }

    }
extension View {
    func kiokuButton() -> some View {
        self.modifier(KiokuButtonStyle())
    }
}

struct KiokuButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.custom("New York", size: 18))
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
            .foregroundColor(.black)
    }
}

#Preview {
    KSettings()
}
