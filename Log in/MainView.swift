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
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var notificationsManager: NotificationViewModel
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    
    var body: some View {
        
        Group {
            if cloudKitViewModel.userIsSignedIn && !cloudKitViewModel.fetchedNamespaceDict.isEmpty {
                
                ContentView()
                    .environmentObject(openAiManager)
                    .environmentObject(pineconeManager)
                    .environmentObject(progressTracker)
                    .environmentObject(notificationsManager)
                    .environmentObject(cloudKitViewModel)
                    .environmentObject(keyboardResponder)
            }
            
            else if cloudKitViewModel.isLoading {
                Text("Signing in with iCloud...").font(.title3).fontWeight(.semibold)
            }
            else if cloudKitViewModel.CKErrorDesc != "" {
                
                let error = cloudKitViewModel.CKErrorDesc
                ErrorView(thrownError: "CloudKit Error", extraMessage: error)
                
            }
        }
    }

}

#Preview {
    MainView()
}
