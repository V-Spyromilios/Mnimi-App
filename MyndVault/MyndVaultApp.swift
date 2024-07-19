//
//  MyndVaultApp.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 06.04.24.
//

import SwiftUI
import Firebase


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        requestNotificationPermission()
        return true
    }
    
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Permission granted")
            } else if let error = error {
                print("Permission denied: \(error.localizedDescription)")
            }
        }
    }
    
    
}



@main
struct MyndVaultApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject var cloudKitViewModel : CloudKitViewModel = CloudKitViewModel.shared
    @StateObject var openAiManager = OpenAIManager()
    @StateObject var pineconeManager = PineconeManager()
    @StateObject var progressTracker = ProgressTracker.shared
    @StateObject var notificationsManager = NotificationViewModel()
    @StateObject var speechManager = SpeechRecognizerManager()
    @StateObject var keyboardResponder = KeyboardResponder()
    @StateObject var authManager = AuthenticationManager()
    @StateObject private var networkManager = NetworkManager()
    @State var showSplash: Bool = true
    
    
    
    var body: some Scene {
        
        WindowGroup(content: {
            if showSplash {
                SplashScreen(showSplash: $showSplash)
                    .environmentObject(cloudKitViewModel)
                    .environmentObject(networkManager)
            }
            
            else if cloudKitViewModel.isFirstLaunch {
                InitialSetupView()
                    .environmentObject(openAiManager)
                    .environmentObject(pineconeManager)
                    .environmentObject(progressTracker)
                    .environmentObject(notificationsManager)
                    .environmentObject(cloudKitViewModel)
                    .environmentObject(speechManager)
                    .environmentObject(keyboardResponder)
                    .environmentObject(authManager)
                    .environmentObject(networkManager)
                    .statusBar(hidden: true)
            } else  {
                
                if cloudKitViewModel.userIsSignedIn && !cloudKitViewModel.fetchedNamespaceDict.isEmpty {
                    
                    FaceIDView()
                        .environmentObject(openAiManager)
                        .environmentObject(pineconeManager)
                        .environmentObject(progressTracker)
                        .environmentObject(notificationsManager)
                        .environmentObject(cloudKitViewModel)
                        .environmentObject(speechManager)
                        .environmentObject(keyboardResponder)
                        .environmentObject(authManager)
                        .environmentObject(networkManager)
                        .statusBar(hidden: true)
                }
                
                else if cloudKitViewModel.isLoading {
                    Text("Signing in with iCloud...").font(.title3).fontWeight(.semibold)
                }
                else if cloudKitViewModel.CKErrorDesc != "" {
                    
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


