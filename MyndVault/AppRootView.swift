//
//  AppRootView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 17.05.25.
//

import SwiftUI
import SwiftData

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var usageManager: ApiCallUsageManager
    @Environment(\.scenePhase) private var scenePhase

    @Binding var showOnboarding: Bool
    @Binding var hasSeenOnboarding: Bool

    @State private var didInitializeViewModel = false
    @StateObject private var pineconeViewModel = PineconeViewModel(
        pineconeActor: PineconeActor())
    
    //for widgets:
    @State private var launchURL: URL? = nil
    @State private var showVault = false
    
    @AppStorage("accountDeleted") private var accountDeleted: Bool = false

    var body: some View {
        if !accountDeleted {

        KView(launchURL: $launchURL, showVault: $showVault)
            .environmentObject(pineconeViewModel)
            .onAppear {
                if !hasSeenOnboarding {
                    showOnboarding = true
                }
                usageManager.refresh()
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                onboardingSheet
            }
            .onOpenURL { url in
                if url.absoluteString == "mnimi://add" {
                    launchURL = url
                } else if url.absoluteString == "mnimi://vault" {
                    showVault = true
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    usageManager.refresh()
                }
            }
        } else {
            KAccountDeletedView()
        }
    }

    @ViewBuilder
    var onboardingSheet: some View {
        if showOnboarding {

            KEmbarkationView(onDone: {
                hasSeenOnboarding = true
                showOnboarding = false }, isDemo: false)
        }
    }
}

#Preview {
    AppRootView(showOnboarding: .constant(true), hasSeenOnboarding: .constant(false))
}
