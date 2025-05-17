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

    var body: some View {
        KView()
            .environmentObject(pineconeViewModel)
            .onAppear {
                if !didInitializeViewModel {
                    pineconeViewModel.updateModelContext(to: modelContext)
                    didInitializeViewModel = true
                }

                if !hasSeenOnboarding {
                    showOnboarding = true
                }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                onboardingSheet
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
