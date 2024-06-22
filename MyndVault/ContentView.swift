//
//  ContentView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 06.04.24.
//

import SwiftUI
import Network

struct ContentView: View {
   
    @ObservedObject var networkManager = NetworkManager()
    
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject private var keyboardResponder: KeyboardResponder
    @State var keyboardAppeared: Bool = false
    @State var hideKyeboardButton: Bool = false
    @State private var tabSelection: Int = 1
    @State var showEditors: Bool = true
    @State var showNetworkError = false
    @EnvironmentObject var speechManager: SpeechRecognizerManager
    
    // for the Question view:
    @State var question: String = ""
    
    //for the NewAddInfo
    @State var newInfo: String = ""
    @State var apiCallInProgress: Bool = false
    @State var showAlert = false
//    @State var showTopBar: Bool = false
    @State var topBarMessage: String = ""
    
    var body: some View {
        ZStack {
            TabView(selection: $tabSelection) {
                
                
                
                NewAddInfoView(newInfo: $newInfo, apiCallInProgress: $apiCallInProgress, showAlert: $showAlert).tag(1)
                    .environmentObject(openAiManager)
                    .environmentObject(pineconeManager)
                    .environmentObject(progressTracker)
                    .environmentObject(keyboardResponder)
                
                QuestionView(question: $question).tag(2)
                
                VaultView().tag(3)
                NotificationsView().tag(4)
            } .ignoresSafeArea(edges: .bottom)
                .overlay(
                    CustomTabBarView(tabSelection: $tabSelection)
                        .ignoresSafeArea()
                        .animation(.easeInOut, value: keyboardAppeared),
                    alignment: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
                .ignoresSafeArea(edges: .horizontal)
                .shadow(color: .britishRacingGreen, radius: 10)
        }
                .onAppear {
                    speechManager.requestSpeechAuthorization()
                }
                .onChange(of: networkManager.hasInternet) { _, hasInternet in
                    if !hasInternet {
                        showNetworkError = true
                    }
                }
                .onChange(of: keyboardResponder.currentHeight) { _, height in
                        keyboardAppeared = height > 0
                    
                    withAnimation(.easeInOut(duration: 0.3).delay(height > 0 ? 0.3 : 0)) {
                        hideKyeboardButton = height > 0
                        }
                }
                .alert(isPresented: $showNetworkError) {
                    Alert(
                        title: Text("No Internet Connection"),
                        message: Text("Please check your internet connection and try again."),
                        dismissButton: .default(Text("OK"))
                    )
                }
    }
}
    

#Preview {
    ContentView()
}
