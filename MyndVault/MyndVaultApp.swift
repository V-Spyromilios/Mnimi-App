//
//  MyndVaultApp.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 06.04.24.
//

import SwiftUI
import RevenueCat
import RevenueCatUI
import SwiftData


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
    
    @StateObject private var openAiManager = OpenAIViewModel(openAIActor: OpenAIActor())
    @StateObject private var apiCallUsageManager = ApiCallUsageManager()
    @StateObject private var speechManager = SpeechRecognizerManager()
    @StateObject private var networkManager = NetworkManager()
    @StateObject private var audioRecorder: AudioRecorder = AudioRecorder()
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var showOnboarding: Bool = false
    
    static let sharedContainer: ModelContainer = {
        try! ModelContainer(for: VectorEntity.self)
    }()
    
    init() {
        configureRevenueCat()
        
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView(
                showOnboarding: $showOnboarding,
                hasSeenOnboarding: $hasSeenOnboarding
            )
            .modelContainer(Persistence.container)
            .environmentObject(openAiManager)
            .environmentObject(networkManager)
            .environmentObject(apiCallUsageManager)
            .environmentObject(speechManager)
            .environmentObject(audioRecorder)
        }
    }
    
    private func configureRevenueCat() {
#if DEBUG
        Purchases.logLevel = .debug
#else
        Purchases.logLevel = .warn
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
    
}
