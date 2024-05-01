//
//  ContentView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 06.04.24.
//

import SwiftUI
//import SwiftData
import Network

struct ContentView: View {
   
    @ObservedObject var networkManager = NetworkManager()
    
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
    
    @EnvironmentObject private var keyboardResponder: KeyboardResponder
    @State var keyboardAppeared: Bool = false
    @State var hideKyeboardButton: Bool = false
    @State var tabSelection: Int = 1
    @State var showEditors: Bool = true
    @State var showNetworkError = false
    @EnvironmentObject var speechManager: SpeechRecognizerManager
    
    // for the Question view:
    @State var question: String = ""
    @State var thrownError: String = "" //common with NewAddInfo
    
    //for the NewAddInfo
    @State var newInfo: String = ""
    @State var apiCallInProgress: Bool = false
    @State var relevantFor: String = ""
    @State var showAlert = false
    @State var showTopBar: Bool = false
    @State var topBarMessage: String = ""
    
    var body: some View {
           
                TabView(selection: $tabSelection) {

                    QuestionView(question: $question, thrownError: $thrownError).tag(1)
                    
                    NewAddInfoView(newInfo: $newInfo, relevantFor: $relevantFor, apiCallInProgress: $apiCallInProgress, thrownError: $thrownError, showAlert: $showAlert, showTopBar: $showTopBar, topBarMessage: $topBarMessage).tag(2)
                        .environmentObject(openAiManager)
                        .environmentObject(pineconeManager)
                        .environmentObject(progressTracker)
                        .environmentObject(keyboardResponder)
                    
                    VaultView().tag(3)
                    NotificationsView().tag(4)
                }
                .overlay(alignment: .bottom) {
                    if !keyboardAppeared {
                        CustomTabBarView(tabSelection: $tabSelection)
                            .transition(.move(edge: .bottom))
                            .edgesIgnoringSafeArea(.bottom)
                            .animation(.easeInOut, value: keyboardAppeared)
                            .padding(.horizontal)
                            .shadow(radius: 8)
                    }
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
