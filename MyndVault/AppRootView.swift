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
    @State private var launchURL: URL? = nil

    var body: some View {
        KView(launchURL: $launchURL)
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
                debugLog("📬 Received URL: \(url)")
                launchURL = url // 👈 forward URL
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
    AppRootView(showOnboarding: .constant(false), hasSeenOnboarding: .constant(true))
}
