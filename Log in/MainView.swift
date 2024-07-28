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
    @EnvironmentObject var apiCallsViewModel: ApiCallViewModel
    
    @State private var navigateToQuestionView = false //for widget
    
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
                        .environmentObject(apiCallsViewModel)
                }
                
                else if cloudKitViewModel.isLoading {
                    Text("Signing in with iCloud...").font(.title3).fontWeight(.semibold)
                }
                else if cloudKitViewModel.CKErrorDesc != "" {
                    
                    let errorDesc = cloudKitViewModel.CKErrorDesc
                    let errorTitle = "CloudKit Error"
                    ErrorView(thrownError: errorTitle, extraMessage: errorDesc) {
                        self.cloudKitViewModel.CKErrorDesc = ""
                    }
                    
                }
            }
            .background {
                LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: backgroundSpeed, contentMode: .scaleAspectFill)
                    .opacity(0.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
        
    }

}

#Preview {
    MainView()
}
