//
//  MyndVaultApp.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 06.04.24.
//

import SwiftUI
import RevenueCat
import RevenueCatUI


class AppDelegate: NSObject, UIApplicationDelegate {
    
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    //    private func requestNotificationPermission() {
    //        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
    //            if granted {
    //                print("Permission granted")
    //            } else if let error = error {
    //                print("Permission denied: \(error.localizedDescription)")
    //            }
    //        }
    //    }
    
}

@main
struct MyndVaultApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var pineconeViewModel: PineconeViewModel
    @StateObject private var openAiManager: OpenAIViewModel
    
    @StateObject var cloudKitViewModel: CloudKitViewModel = .shared
    
    @StateObject var apiCallUsageManager = ApiCallUsageManager()
    
    @StateObject var speechManager = SpeechRecognizerManager()
    @StateObject var authManager = AuthenticationManager()
    @StateObject private var networkManager = NetworkManager()
    @StateObject var apiCallsViewModel = ApiCallViewModel()
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var showOnboarding: Bool = false
    
    init() {
        let ckViewModel = CloudKitViewModel.shared
        _pineconeViewModel = StateObject(wrappedValue: PineconeViewModel(
            pineconeActor: PineconeActor(cloudKitViewModel: ckViewModel),
            CKviewModel: ckViewModel
        ))
        
        _openAiManager = StateObject(wrappedValue: OpenAIViewModel(openAIActor: OpenAIActor()))

        configureRevenueCat()

        Task {
            await ckViewModel.startCloudKit()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            KView()
                .environmentObject(openAiManager)
                .environmentObject(pineconeViewModel)
                .environmentObject(networkManager)
                .environmentObject(cloudKitViewModel)
                .environmentObject(apiCallUsageManager)
                .onAppear {
//                    if !hasSeenOnboarding {
                        showOnboarding = true
//                    }
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    onboardingSheet
                }
        }
    }
    
    private func configureRevenueCat() {
#if DEBUG
        Purchases.logLevel = .debug
#else
        Purchases.logLevel = .verbose
#endif
        if let catKey = ApiConfiguration.catKey {
            Purchases.configure(with: .init(withAPIKey: catKey)
                .with(storeKitVersion: .storeKit2))
        }
        else {
            debugLog("Failed to configure RCat key.")
        }
        Purchases.shared.delegate = PurchasesDelegateHandler.shared
    }
    
    @ViewBuilder
    var onboardingSheet: some View {
        if showOnboarding {
            KEmbarkationView {
                hasSeenOnboarding = true
                showOnboarding = false
            }
        }
    }

}
