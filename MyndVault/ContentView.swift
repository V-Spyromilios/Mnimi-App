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
    
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
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
    @State private var isNewSubscriber: Bool = false
    
    @State var customerInfo: CustomerInfo? //to allow change in task
   
    
    var body: some View {
        ZStack {
            TabView(selection: $tabSelection) {
                
                NewAddInfoView().tag(1)
                    .environmentObject(openAiManager)
                    .environmentObject(pineconeManager)
                    .environmentObject(progressTracker)
                    .environmentObject(keyboardResponder)
                    .environmentObject(languageSettings)
                
                QuestionView().tag(2)
                
                VaultView().tag(3)
                    .environmentObject(languageSettings)
                //                NotificationsView().tag(4)
            }
            .ignoresSafeArea(edges: .bottom)
            .overlay(
                CustomTabBarView(tabSelection: $tabSelection)
                    .ignoresSafeArea()
                    .animation(.easeInOut, value: keyboardAppeared),
                alignment: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
            .ignoresSafeArea(edges: .horizontal)
            if isNewSubscriber {
                LottieRepresentable(filename: "Confetti").frame(maxHeight: .infinity)
            }
        }
        .onAppear {
            speechManager.requestSpeechAuthorization()
            onAppearGetInfo()
           
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
            if isActive {
                print("is Now Active Subscription: \(isActive) and was \(wasActive)")
                withAnimation { showPayWall = false }
            }
            else {
                print("Now is Not Active Subscription: \(isActive), and was: \(wasActive)")
                withAnimation { showPayWall = true }
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
            CustomPayWall()
        }
    }

    
    
    private func onAppearGetInfo() {
        print("onAppear is Active: \(RCviewModel.isActiveSubscription)")
        
        
        Task {
                        do {
                            customerInfo = try await Purchases.shared.customerInfo()
                        } catch {
                            // handle error
                        }
                        guard let customerInfo = customerInfo else { return }
                        let entitlements = customerInfo.entitlements
                        let entitlement = entitlements[Constants.entitlementID]
                        let activationDate = entitlement?.latestPurchaseDate
                        let hasSubscribed =  entitlement?.isActive ?? false
            
           
                print("OnAppear with urchases.shared.customerInfo() : hasSubscribed: \(hasSubscribed)")
            
            if !hasSubscribed {
                print("Has not subscribed, opening full screen cover...")
                showPayWall = true
            }
            
        }
        
    }
//    private func getCustomersInfo() {
//      
//        
//        if !RCViewModel.shared.isActiveSubscription {
//            showPayWall = true
//        }
//       
//        
////        Task {
////            do {
////                customerInfo = try await Purchases.shared.customerInfo()
////            } catch {
////                // handle error
////            }
////            guard let customerInfo = customerInfo else { return }
////            let entitlements = customerInfo.entitlements
////            let entitlement = entitlements[Constants.entitlementID]
////            let activationDate = entitlement?.latestPurchaseDate
////            let hasSubscribed =  entitlement?.isActive ?? false
////
////            if !hasSubscribed {
////                withAnimation {
////                    showPayWall.toggle()
////                }
////            }
////            if activationDate != nil {
////                let now = Date()
////                let calendar = Calendar.current
////                let activationComponents = calendar.dateComponents([.year, .month, .day], from: activationDate!)
////                let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
////                
////                if activationComponents == todayComponents {
////                    isNewSubscriber.toggle()
////                }
////            }
////            
////        }
//    }
}


#Preview {
    ContentView()
}
