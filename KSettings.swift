//
//  KSettings.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 22.04.25.
//

import SwiftUI

struct KSettings: View {

    @EnvironmentObject var language: LanguageSettings
    @State private var canShowAppSettings: Bool = true
    @State private var canShowSubscription: Bool = true
    
    enum SettingsSheet: Identifiable {
        case promptLanguage
        case aboutUs

        var id: Int {
            switch self {
            case .promptLanguage: return 0
            case .aboutUs: return 1
            }
        }
    }
    
    @State private var activeSheet: SettingsSheet?
    
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
                VStack(spacing: 24) {
                    
                    //MARK: Prompt Language
                    Button {
                        activeSheet = .promptLanguage
                    } label: {
                        HStack {
                            Text("Prompt Language")
                            Spacer()
                            
                        }
                    }
                    .kiokuButton()
                    .padding(.top, 25)
                    
                    
                    
                    //MARK: App Setting in the phone
                    if canShowAppSettings {
                        Button {
                            openAppSettings()
                        } label: {
                            HStack {
                                Text("App General Settings")
                                Spacer()
                            }
                            
                        }.kiokuButton()
                    }
                    
                    //MARK: Manage Subsription
                    if canShowSubscription {
                        Button {
                            openSubscriptionManagement()
                        } label: {
                            HStack {
                                Text("Manage Subscription")
                                Spacer()
                            }
                            
                        }.kiokuButton()
                    }
                    //MARK: Privacy Policy
                    Button {
                        openPrivacyPolicy()
                    } label: {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            
                        }
                    }
                    .kiokuButton()
                    
                    
                    //MARK: Terms of Use
                    Button {
                        eula()
                    } label: {
                        HStack {
                            Text("Terms of use")
                            Spacer()
                        }
                        //                        Image(systemName: "chevron.right")
                    } .kiokuButton()
                    
                    //MARK: Open Support request
                    Button {
                        openSupportRequest()
                    } label: {
                        HStack {
                            Text("Support Request")
                            Spacer()
                        }
                        //                        Image(systemName: "chevron.right")
                    }.kiokuButton()
                    
                    //MARK: About Us
                    Button {
                        activeSheet = .aboutUs
                    } label: {
                        HStack {
                            Text("About us")
                            Spacer()
                        }
                    }
                    .kiokuButton()
                    
                    //TODO: Bring 'Delete Account' from old Settings!
                }.padding(.top, 25)
                    .sheet(item: $activeSheet) { item in
                        switch item {
                        case .promptLanguage:
                            PromptLanguageView()
                        case .aboutUs:
                            AboutUsView()
                        }
                    }
            }
            .padding(.horizontal, 20)
            .frame(width: UIScreen.main.bounds.width)
        }
        .onAppear {
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
