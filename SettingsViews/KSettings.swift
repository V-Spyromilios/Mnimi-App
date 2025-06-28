//
//  KSettings.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 22.04.25.
//

import SwiftUI
import RevenueCat
import EventKit
import AVFoundation

struct KSettings: View {
    
    @State private var canShowAppSettings: Bool = true
    @State private var canShowSubscription: Bool = true
    @EnvironmentObject var pineconeManager: PineconeViewModel
    @EnvironmentObject var usageManager: ApiCallUsageManager
    
    enum SettingsSheet: Identifiable {
        case aboutUs
        case kEmbarkationView
        case deleteAccount
        case paywall
        
        var id: Int {
            switch self {
            case .aboutUs: return 1
            case .kEmbarkationView: return 2
            case .deleteAccount: return 3
            case .paywall: return 4
            }
        }
    }
    
    @State private var activeSheet: SettingsSheet?
    
    var body: some View {
        
        ZStack {
            KiokuBackgroundView()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    //MARK: App Setting in the phone
                    if canShowAppSettings {
                        Button {
                            openAppSettings()
                        } label: {
                            HStack {
                                Text("Open System Settings")
                                Spacer()
                            }.padding(.top, 45)
                            
                        }.kiokuButton()
                            .accessibilityLabel("Open system settings")
                            .accessibilityHint("Opens the iOS settings for Mnimi")
                    }
                    
                    PermissionButtonGroup()
                    
                    //MARK: Manage Subsription
                    if usageManager.isProUser {
                        Button {
                            openSubscriptionManagement()
                        } label: {
                            HStack {
                                Text("Manage Subscription")
                                Spacer()
                            }
                        }.kiokuButton()
                            .accessibilityLabel("Manage subscription")
                                .accessibilityHint("Opens your Apple subscription settings")
                    } else {
                        Button {
                            showPaywall()
                        } label: {
                            HStack {
                                Text("Get Unlimited Mnimi")
                                Spacer()
                            }
                           
                            
                        }.kiokuButton()
                            .accessibilityLabel("Get Unlimited Mnimi")
                               .accessibilityHint("Subscribe for unlimited usage and faster responses")
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
                    .accessibilityLabel("Privacy policy")
                    .accessibilityHint("Opens Mnimi’s privacy policy in your browser")
                    
                    
                    //MARK: Terms of Use
                    Button {
                        eula()
                    } label: {
                        HStack {
                            Text("Terms of Use")
                            Spacer()
                        }
                        //                        Image(systemName: "chevron.right")
                    } .kiokuButton()
                        .accessibilityLabel("Terms of use")
                        .accessibilityHint("Opens the Apple standard end user license agreement")
                    
                    //MARK: Open Support request
                    Button {
                        openSupportRequest()
                    } label: {
                        HStack {
                            Text(" Get Help")
                            Spacer()
                        }
                        //                        Image(systemName: "chevron.right")
                    }.kiokuButton()
                        .accessibilityLabel("Contact support")
                        .accessibilityHint("Opens a support form to request help")
                    
                    //MARK: About Us
                    Button {
                        activeSheet = .aboutUs
                    } label: {
                        HStack {
                            Text("About Us")
                            Spacer()
                        }
                    }
                    .kiokuButton()
                    .accessibilityLabel("About us")
                    .accessibilityHint("Learn about the story behind Mnimi")
                    
                    
                    Button {
                        activeSheet = .kEmbarkationView
                    } label: {
                        HStack {
                            Text("How Mnimi Works")
                            Spacer()
                        }
                    }.kiokuButton()
                        .accessibilityLabel("How Mnimi works")
                        .accessibilityHint("Replay the onboarding and learn how to use Mnimi")
                    
                    Button {
                        activeSheet = .deleteAccount
                    } label: {
                        HStack {
                            Text("Delete Account")
                            Spacer()
                        }
                    }.kiokuButton()
                        .accessibilityLabel("Delete account")
                        .accessibilityHint("Permanently delete your data and account from Mnimi")
                }
                .sheet(item: $activeSheet) { item in
                    switch item {
                        
                    case .aboutUs:
                        AboutUsView()
                    case .kEmbarkationView:
                        KEmbarkationView(onDone: {
                           activeSheet = nil }, isDemo: true)
                    case .deleteAccount:
                        KDeleteAccountView(onCancel: {self.activeSheet = nil} )
                    case .paywall:
                        CustomPaywallView(onCancel: {self.activeSheet = nil} )
                    }
                }
            }.scrollIndicators(.hidden)
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
    
    private func showPaywall() {
        activeSheet = .paywall
    }
    
    private func checkOpeningSubscriptions() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions"),
              UIApplication.shared.canOpenURL(url)
        else {
            withAnimation { canShowSubscription = false }
            return
        }
    }
    
//    private func checkSubscriptionStatus() async {
//        do {
//            let customerInfo = try await Purchases.shared.customerInfo()
//            if customerInfo.entitlements[Constants.entitlementID]?.isActive == true {
//                withAnimation {
//                    isActiveSubscriber = true }
//            } else {
//                withAnimation {
//                    isActiveSubscriber = false }
//            }
//        } catch {
//            // Handle error
//            debugLog("KSettings :: Error fetching customer info: \(error)")
//        }
//    }
    
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
            .font(.custom(NewYorkFont.regular.rawValue, size: 18))
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
            .foregroundColor(.black)
    }
}

#Preview {
    let api = ApiCallUsageManager()
    KSettings()
        .environmentObject(api)
}



// MARK: – PermissionButtonGroup
@MainActor
struct PermissionButtonGroup: View {
    
    @AppStorage("calendarPermissionGranted") var calendarPermissionGranted: Bool?
    @AppStorage("reminderPermissionGranted") var reminderPermissionGranted: Bool?
    @AppStorage("microphonePermissionGranted") var microphonePermissionGranted: Bool?
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        if calendarPermissionGranted != true || reminderPermissionGranted != true || microphonePermissionGranted != true {

            VStack(spacing: 16) {
                if calendarPermissionGranted != true {
                    Button("Enable Calendar Access !") {
                        openAppSettings()
                    }
                    .kiokuButton()
                }
                
                if reminderPermissionGranted != true {
                    Button("Enable Reminders Access !") {
                        openAppSettings()
                    }
                    .kiokuButton()
                }
                
                if microphonePermissionGranted != true {
                    Button("Enable Microphone !") {
                        openAppSettings()
                    }
                    .kiokuButton()
                    
                }
            }
            
            .onChange(of: scenePhase) { _, newPhase in //Check the permissions again when the app returns from background (user went to settings and returned)
                if newPhase == .active {
                    refreshPermissionsFromSystem()
                }
            }
        }

    }
    
    private func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString),
                 UIApplication.shared.canOpenURL(settingsURL) {
                  UIApplication.shared.open(settingsURL)
              }
    }
    
    @MainActor
    private func refreshPermissionsFromSystem() {
        // Microphone
        let micStatus = AVAudioApplication.shared.recordPermission
        microphonePermissionGranted = micStatus == .granted

        // Calendar
        let eventAuth = EKEventStore.authorizationStatus(for: .event)
        calendarPermissionGranted = eventAuth == .fullAccess

        // Reminders
        let reminderAuth = EKEventStore.authorizationStatus(for: .reminder)
        reminderPermissionGranted = reminderAuth == .fullAccess
    }

}

