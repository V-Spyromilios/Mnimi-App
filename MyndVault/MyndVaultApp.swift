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
    
    init() {
        Purchases.logLevel = .debug
        
        if let catKey = ApiConfiguration.catKey {
            Purchases.configure(with: .init(withAPIKey: catKey)
                .with(storeKitVersion: StoreKitVersion.storeKit2))
                
                
//                withAPIKey: catKey)
                
        } else { print("Failed to configure RCat key.") }
        
        Purchases.shared.delegate = PurchasesDelegateHandler.shared
        
        self.pineconeActor = PineconeActor()
        let ckViewModel = CloudKitViewModel.shared
        let pineconeActor = PineconeActor(cloudKitViewModel: ckViewModel)
        _pineconeViewModel = StateObject(wrappedValue: PineconeViewModel(pineconeActor: pineconeActor, CKviewModel: ckViewModel))
        
        let openAIActor = OpenAIActor()
        _openAiManager = StateObject(wrappedValue: OpenAIViewModel(openAIActor: openAIActor))
    }
    
    @StateObject private var pineconeViewModel: PineconeViewModel
    @StateObject private var openAiManager: OpenAIViewModel
    
    private let pineconeActor: PineconeActor
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var cloudKitViewModel : CloudKitViewModel = CloudKitViewModel.shared
    
    @StateObject var progressTracker = ProgressTracker.shared
//    @StateObject var notificationsManager = NotificationViewModel()
    @StateObject var speechManager = SpeechRecognizerManager()
    @StateObject var keyboardResponder = KeyboardResponder()
    @StateObject var authManager = AuthenticationManager()
    @StateObject private var networkManager = NetworkManager()
    @StateObject var apiCallsViewModel = ApiCallViewModel()
    @StateObject private var languageSettings = LanguageSettings.shared
    @State var showSplash: Bool = true
   

    var body: some Scene {
            WindowGroup(content: {

                if showSplash {
                    SplashScreen(showSplash: $showSplash)
                        .environmentObject(cloudKitViewModel)
                        .environmentObject(networkManager)
                        .environmentObject(apiCallsViewModel)
                } 
                else if cloudKitViewModel.isFirstLaunch {
                    InitialSetupView()
                        .environmentObject(cloudKitViewModel)
                        .environmentObject(networkManager)
                        .environmentObject(apiCallsViewModel)
                        .environmentObject(keyboardResponder)
                        .environmentObject(authManager)
                        .environmentObject(progressTracker)
                        .environmentObject(openAiManager)
                        .environmentObject(pineconeViewModel)
                        .environmentObject(languageSettings)
                        .environmentObject(speechManager)
                        .statusBar(hidden: true)
                        
                }
                else  {
                    if cloudKitViewModel.userIsSignedIn && !cloudKitViewModel.fetchedNamespaceDict.isEmpty {
                        FaceIDView()
                            .environmentObject(cloudKitViewModel)
                            .environmentObject(networkManager)
                            .environmentObject(apiCallsViewModel)
                            .environmentObject(authManager)
                            .environmentObject(openAiManager)
                            .environmentObject(pineconeViewModel)
                            .environmentObject(progressTracker)
                            .environmentObject(keyboardResponder)
                            .environmentObject(languageSettings)
                            .environmentObject(speechManager)
                            .statusBar(hidden: true)
                    } else if cloudKitViewModel.isLoading {
                        Text("Signing in with iCloud...")
                            .font(.title3)
                            .fontWeight(.semibold)
                    } else if cloudKitViewModel.CKErrorDesc != "" {
                        let error = cloudKitViewModel.CKErrorDesc
                        contentError(error: error).padding(.horizontal)
                    }
                }
            })
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


