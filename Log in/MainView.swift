//
//  MainView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 18.05.24.
//

import SwiftUI

struct MainView: View {
    
    @EnvironmentObject var cloudKitViewModel: CloudKitViewModel
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var notificationsManager: NotificationViewModel
    @EnvironmentObject var speechManager: SpeechRecognizerManager
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    
    var body: some View {

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
                    Text("Signing in with iCloud...").font(.title3).fontWeight(.semibold)
                }
                else if cloudKitViewModel.CKError != "" {

                    let error = cloudKitViewModel.CKError
                    
                    
                    contentError(error: error.description)
//                    ContentUnavailableView(title: "iCloud Unavailable.\n\(error.description)", systemImage: "exclamationmark.icloud.fill")

                }
            }
        
    }
    private func contentError(error: String) -> some View {
        VStack{
            Image(systemName: "exclamationmark.icloud.fill").resizable().padding(.bottom).frame(width: 110, height: 90)
            Text("iCloud Error").font(.title).padding(.vertical)
            Text(error).font(.title3).italic()
        }.foregroundStyle(.gray)
    }

}

#Preview {
    MainView()
}
