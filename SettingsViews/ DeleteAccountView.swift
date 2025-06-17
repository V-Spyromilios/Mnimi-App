//
//   DeleteAccountView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 06.05.25.
//

import SwiftUI
import SwiftData

struct KDeleteAccountView: View {
    @EnvironmentObject var pineconeManager: PineconeViewModel
    @State private var isDeleting = false
    @State private var showError = false
    @State private var deletionSuccess = false
    @State private var swiftDataError: String? = nil
    
    @AppStorage("accountDeleted") private var accountDeleted: Bool = false
    
    @Environment(\.modelContext) private var context
    var onCancel: () -> Void

    var body: some View {
        ZStack {

            KiokuBackgroundView()

            VStack(spacing: 27) {
                Spacer()

                if deletionSuccess == false {
                    Text("Are you sure?")
                        .font(.custom("NewYorkMedium-Heavy", size: 24))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .kiokuShadow()
                    
                    Text("This will permanently delete all your saved information from Mnimi.")
                        .font(.custom("New York", size: 18))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .lineSpacing(7)
                        .padding(.horizontal, 30)
                    
                    Spacer()
                } else {
                    Text("Your account was deleted.")
                        .font(.custom("NewYorkMedium-Heavy", size: 24))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .kiokuShadow()
                    
                    Text("You can safely uninstall the app")
                        .font(.custom("New York", size: 18))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .lineSpacing(7)
                        .padding(.horizontal, 30)
                    Spacer()
                }
                VStack(spacing: 16) {
                    if !deletionSuccess && !accountDeleted {
                        Button(action: {
                            Task {
                                isDeleting = true
                                let success = await pineconeManager.deleteAllVectorsInNamespace()
                                
                                if success {
                                    // Delete all VectorEntity objects from SwiftData
                                    do {
                                        let fetchDescriptor = FetchDescriptor<VectorEntity>()
                                        let localVectors = try context.fetch(fetchDescriptor)
                                        for vector in localVectors {
                                            context.delete(vector)
                                        }
                                        try context.save()
                                    } catch {
                                        await MainActor.run {
                                            swiftDataError = "Error deleting local data."
                                        }
                                        debugLog("DeleteAccountView :: Error deleting local SwiftData vectors: \(error)")
                                    }
                                }
                                
                                await MainActor.run {
                                    isDeleting = false
                                    if success {
                                        deletionSuccess = true
                                        accountDeleted = true
                                    } else {
                                        showError = true
                                    }
                                }
                            }
                        }) {
                            Text("Delete My Account")
                                .font(.custom(NewYorkFont.italic.rawValue, size: 20))
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .accessibilityLabel("Delete my account")
                                .accessibilityHint("This will erase all your saved data from Mnimi permanently")

                        }
                    }
                    if !deletionSuccess && !isDeleting {
                        Button(action: {
                            if !isDeleting {
                                onCancel()
                            }
                        }) {
                            Text("Cancel")
                                .font(.custom(NewYorkFont.regular.rawValue, size: 18))
                                .foregroundColor(.black)
                                .padding(.vertical, 16)
                        }
                        .disabled(isDeleting)
                        .accessibilityLabel("Cancel deletion")
                        .accessibilityHint("Go back without deleting your account")
                    }
                    
                    if showError, let error = pineconeManager.pineconeErrorOnDel {
                        Text(error.message)
                            .font(.custom(NewYorkFont.regular.rawValue, size: 17))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }
                    else if let error = swiftDataError {
                        Text(error)
                            .font(.custom(NewYorkFont.regular.rawValue, size: 17))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
            .transition(.opacity)
        }
        .statusBarHidden()
    }
}

#Preview {
    KDeleteAccountView(onCancel: {
        
    })
//    KAccountDeletedView()
}


struct KAccountDeletedView: View {
    var body: some View {
        ZStack {
            KiokuBackgroundView()
            VStack(spacing: 20) {
                Spacer()
                Text("Your account has been deleted.")
                    .font(.custom(NewYorkFont.heavy.rawValue, size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                Text("You can safely uninstall the app.")
                    .font(.custom(NewYorkFont.regular.rawValue, size: 18))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            .padding()
        }
    }
}
