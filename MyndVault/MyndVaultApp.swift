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

    @ObservedObject var cloudKitViewModel : CloudKitViewModel = CloudKitViewModel.shared
    var openAiManager = OpenAIManager()
    var pineconeManager = PineconeManager()
    var audioManager = AudioManager.shared
    var progressTracker = ProgressTracker.shared
    var notificationsManager = NotificationViewModel()
    var speechManager = SpeechRecognizerManager()
    var keyboardResponder = KeyboardResponder()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    
    var body: some Scene {

        WindowGroup(content: {
            
            Group {
                if cloudKitViewModel.userIsSignedIn {

                    ContentView()
                        .environmentObject(openAiManager)
                        .environmentObject(pineconeManager)
                        .environmentObject(audioManager)
                        .environmentObject(progressTracker)
                        .environmentObject(notificationsManager)
                        .environmentObject(cloudKitViewModel)
                        .environmentObject(speechManager)
                        .environmentObject(keyboardResponder)
                }
                
                else if cloudKitViewModel.isLoading {
                    LoadingView()
                }
                else if cloudKitViewModel.CKError != "" {

                    ContentUnavailableView("iCloud Error", systemImage: "exclamationmark.icloud.fill")
                }
            }
        })
    }
}
