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
    @StateObject private var languageSettings = LanguageSettings.shared
    
    @StateObject var speechManager = SpeechRecognizerManager()
    @StateObject var keyboardResponder = KeyboardResponder()
    @StateObject var authManager = AuthenticationManager()
    @StateObject private var networkManager = NetworkManager()
    @StateObject var apiCallsViewModel = ApiCallViewModel()
    @State var showSplash: Bool = true
    
    init() {
        let ckViewModel = CloudKitViewModel.shared
        let pineconeActor = PineconeActor(cloudKitViewModel: ckViewModel)
        _pineconeViewModel = StateObject(wrappedValue: PineconeViewModel(pineconeActor: pineconeActor, CKviewModel: ckViewModel))
        
        let openAIActor = OpenAIActor()
        _openAiManager = StateObject(wrappedValue: OpenAIViewModel(openAIActor: openAIActor))
        
        configureRevenueCat()
    }
    
    var body: some Scene {
        WindowGroup {
            
            if showSplash {
                SplashScreen(showSplash: $showSplash)
                    .environmentObject(cloudKitViewModel)
                    .environmentObject(networkManager)
                    .environmentObject(apiCallsViewModel)
                    .statusBar(hidden: true)
            }
            else if cloudKitViewModel.isFirstLaunch {
                InitialSetupView()
                    .environmentObject(cloudKitViewModel)
                    .environmentObject(networkManager)
                    .environmentObject(apiCallsViewModel)
                    .environmentObject(keyboardResponder)
                    .environmentObject(authManager)
                    .environmentObject(openAiManager)
                    .environmentObject(pineconeViewModel)
                    .environmentObject(languageSettings)
                    .environmentObject(speechManager)
                    .statusBar(hidden: true)
            }
            else {
                RootView()
                    .environmentObject(cloudKitViewModel)
                    .environmentObject(networkManager)
                    .environmentObject(apiCallsViewModel)
                    .environmentObject(authManager)
                    .environmentObject(openAiManager)
                    .environmentObject(pineconeViewModel)
                    .environmentObject(keyboardResponder)
                    .environmentObject(languageSettings)
                    .environmentObject(speechManager)
                    .statusBar(hidden: true)
                    .transition(.opacity)
            }
        }
    }
    
    private func configureRevenueCat() {
        
#if DEBUG
        Purchases.logLevel = .debug
#else
        Purchases.logLevel = .info
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
    
    private func contentError(error: String) -> some View {
        VStack{
            Image(systemName: "exclamationmark.icloud.fill").resizable() .scaledToFit().padding(.bottom).frame(width: 90, height: 90)
            Text("iCloud Error").font(.title).bold().padding(.vertical)
            Text("\(error).\nPlease check your iCloud status and restart the Mynd Vault app").font(.title3).italic()
        }.foregroundStyle(.gray)
            .statusBarHidden()
    }
}
