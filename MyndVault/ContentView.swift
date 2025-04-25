//
//  ContentView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 06.04.24.
//

import SwiftUI
import Network
import RevenueCat
import RevenueCatUI

struct ContentView: View {
    
    @ObservedObject var networkManager = NetworkManager()
    
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @EnvironmentObject var pineconeManager: PineconeViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject private var keyboardResponder: KeyboardResponder
    @EnvironmentObject var speechManager: SpeechRecognizerManager
    @EnvironmentObject var languageSettings: LanguageSettings
    
    @State var keyboardAppeared: Bool = false
    @State var hideKyeboardButton: Bool = false
    @State private var tabSelection: Int = 1
    @State var showEditors: Bool = true
    @StateObject var RCviewModel = RCViewModel.shared
    @State var showNetworkError = false
    @State private var showPayWall: Bool = false
    
    @State var customerInfo: CustomerInfo? //to allow change in task
    
    
    var body: some View {
        ZStack {
            TabView(selection: $tabSelection) {
                
                LazyView(NewAddInfoView())
                    .tag(1)
                    .environmentObject(openAiManager)
                    .environmentObject(pineconeManager)
                    .environmentObject(keyboardResponder)
                    .environmentObject(languageSettings)
                    .transition(.opacity)
                
//                LazyView(QuestionView())
//                    .tag(2)
//                    .environmentObject(openAiManager)
//                    .environmentObject(pineconeManager)
//                    .environmentObject(keyboardResponder)
//                    .environmentObject(languageSettings)
//                    .transition(.opacity)
                
//                LazyView(VaultView())
//                    .tag(3)
//                    .environmentObject(openAiManager)
//                    .environmentObject(pineconeManager)
//                    .environmentObject(keyboardResponder)
//                    .environmentObject(languageSettings)
//                    .transition(.opacity)
            } //TODO: Pass the enviromentObjects outside od the ZSstack. they get passed to everyview once.
            .ignoresSafeArea(edges: .bottom)
            .overlay(
                CustomTabBarView(tabSelection: $tabSelection)
                    .ignoresSafeArea()
                    .animation(.easeInOut, value: keyboardAppeared),
                alignment: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
            .ignoresSafeArea(edges: .horizontal)
            
        }
        .onAppear {
            speechManager.checkSpeechAuthorizationStatus()
            debugLog("isActiveSubscription onAppear of ContentView: \(RCviewModel.isActiveSubscription)")
               if !RCviewModel.isActiveSubscription {
                   showPayWall = true
               }
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
        .onChange(of: RCviewModel.isActiveSubscription) { wasActive, isActive in
            let previous = wasActive
            
            if isActive {
                debugLog("is Now Active Subscription: \(isActive) and was \(previous)")
                withAnimation(.easeInOut(duration: 0.5)) { showPayWall = false }
            } else {
                debugLog("Now is Not Active Subscription: \(isActive), and was: \(previous)")
                withAnimation(.easeInOut(duration: 0.5)) { showPayWall = true }
            }
        }
        .alert(isPresented: $showNetworkError) {
            Alert(
                title: Text("No Internet Connection"),
                message: Text("Please check your internet connection and try again."),
                dismissButton: .default(Text("OK"))
            )
        }
        .fullScreenCover(isPresented: $showPayWall) {
            PaywallView(displayCloseButton: false)
        }
    }
    
//    private func checkIfNewSubscriber() {
//        
//        Task {
//            do {
//                customerInfo = try await Purchases.shared.customerInfo()
//            }
//            catch {
//                debugLog("Error from checkIfNewSubscriber() : \(error.localizedDescription)")
//            }
//        }
//        
//        guard let customerInfo = customerInfo else { return }
//        let entitlements = customerInfo.entitlements
//        let entitlement = entitlements[Constants.entitlementID]
//        let activationDate = entitlement?.latestPurchaseDate
//        
//        if activationDate != nil {
//            let now = Date()
//            let calendar = Calendar.current
//            let activationComponents = calendar.dateComponents([.year, .month, .day], from: activationDate!)
//            let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
//            
//            if activationComponents == todayComponents {
//                isNewSubscriber.toggle()
//            }
//        }
//    }
}


#Preview {
    ContentView()
}

/// This defers view creation until needed, reducing memory.
struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: some View {
        build()
    }
}
