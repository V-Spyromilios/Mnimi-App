//
//  MyndVaultApp.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 06.04.24.
//

import SwiftUI
//import SwiftData
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

    @AppStorage("isFirstLaunch") var isFirstLaunch: Bool = true
    
    @ObservedObject var cloudKitViewModel : CloudKitViewModel = CloudKitViewModel.shared
    var openAiManager = OpenAIManager()
    var pineconeManager = PineconeManager()
    var progressTracker = ProgressTracker.shared
    var notificationsManager = NotificationViewModel()
    var speechManager = SpeechRecognizerManager()
    var keyboardResponder = KeyboardResponder()
    var authManager = AuthenticationManager()
    
    
    
    var body: some Scene {
        
        WindowGroup(content: {
            
            if isFirstLaunch {
                InitialSetupView()
                    .environmentObject(openAiManager)
                    .environmentObject(pineconeManager)
                    .environmentObject(progressTracker)
                    .environmentObject(notificationsManager)
                    .environmentObject(cloudKitViewModel)
                    .environmentObject(speechManager)
                    .environmentObject(keyboardResponder)
                    .environmentObject(authManager)
                    .statusBar(hidden: true)
            } else  {
                
                if cloudKitViewModel.userIsSignedIn {
                    
                    FaceIDView()
                        .environmentObject(openAiManager)
                        .environmentObject(pineconeManager)
                        .environmentObject(progressTracker)
                        .environmentObject(notificationsManager)
                        .environmentObject(cloudKitViewModel)
                        .environmentObject(speechManager)
                        .environmentObject(keyboardResponder)
                        .environmentObject(authManager)
                        .statusBar(hidden: true)
                }
                
                else if cloudKitViewModel.isLoading {
                    Text("Signing in with iCloud...").font(.title3).fontWeight(.semibold)
                }
                else if cloudKitViewModel.CKError != "" {
                    
                    let error = cloudKitViewModel.CKError
                    contentError(error: error)
                }
                
            }
        })
    }
    
    private func contentError(error: String) -> some View {
        VStack{
            Image(systemName: "exclamationmark.icloud.fill").resizable() .scaledToFit().padding(.bottom).frame(width: 90, height: 90)
            Text("iCloud Error").font(.title).padding(.vertical)
            Text(error).font(.title3).italic()
        }.foregroundStyle(.gray)
    }
}


