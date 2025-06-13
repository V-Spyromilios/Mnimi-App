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

    @Binding var showOnboarding: Bool
    @Binding var hasSeenOnboarding: Bool

    @State private var didInitializeViewModel = false
    @StateObject private var pineconeViewModel = PineconeViewModel(
        pineconeActor: PineconeActor())
    
    //for widgets:
    @State private var launchURL: URL? = nil
    @State private var showVault = false

    var body: some View {
        KView(launchURL: $launchURL, showVault: $showVault)
            .environmentObject(pineconeViewModel)
            .onAppear {
                if !hasSeenOnboarding {
                    showOnboarding = true
                }
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
    }

    @ViewBuilder
    var onboardingSheet: some View {
        if showOnboarding {
            KEmbarkationView {
                hasSeenOnboarding = true
                showOnboarding = false
            }
        }
    }
}

#Preview {
    AppRootView(showOnboarding: .constant(true), hasSeenOnboarding: .constant(false))
}
