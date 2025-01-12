//
//  ToorView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 01.12.24.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var cloudKitViewModel: CloudKitViewModel
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var apiCallsViewModel: ApiCallViewModel
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @EnvironmentObject var pineconeViewModel: PineconeViewModel
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var languageSettings: LanguageSettings
    @EnvironmentObject var speechManager: SpeechRecognizerManager
    @State var showFaceIDView: Bool  = true
    
    var body: some View {
        if authManager.isAuthenticated && cloudKitViewModel.userIsSignedIn {
                    MainView()
                        .environmentObject(cloudKitViewModel)
                        .environmentObject(networkManager)
                        .environmentObject(apiCallsViewModel)
                        .environmentObject(authManager)
                        .environmentObject(openAiManager)
                        .environmentObject(pineconeViewModel)
                        .environmentObject(keyboardResponder)
                        .environmentObject(languageSettings)
                        .environmentObject(speechManager)
                        .transition(.opacity)
        } else if cloudKitViewModel.userIsSignedIn && !cloudKitViewModel.fetchedNamespaceDict.isEmpty && showFaceIDView {
                    FaceIDView(isPresented: $showFaceIDView)
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
                } else if cloudKitViewModel.isLoading {
                    LoadingDotsView(text: "Signing in with iCloud")
                         .if(isIPad()) { view in //TODO: Check if padding is needed for iphones
                             view.padding(.top, 40)
                         }
                } else if !cloudKitViewModel.CKErrorDesc.isEmpty {
                    let error = cloudKitViewModel.CKErrorDesc
                    contentError(error: error)
                        .padding(.horizontal)
                } else {
                    // Handle other cases if necessary
                    LoadingDotsView(text: "Initializing")
                         .if(isIPad()) { view in //TODO: Check if padding is needed for iphones
                             view.padding(.top, 40)
                         }
                }
    }
    
    private func contentError(error: String) -> some View {
            VStack {
                Image(systemName: "exclamationmark.icloud.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(.bottom)
                    .frame(width: 90, height: 90)
                Text("iCloud Error")
                    .font(.title)
                    .bold()
                    .padding(.vertical)
                Text("\(error).\nPlease check your iCloud status and restart the Mynd Vault app")
                    .font(.title3)
                    .italic()
            }
            .foregroundStyle(.gray)
            .statusBarHidden()
        }
}

#Preview {
    RootView()
}
