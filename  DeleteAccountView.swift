//
//   DeleteAccountView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 06.05.25.
//

import SwiftUI

struct KDeleteAccountView: View {
    @EnvironmentObject var pineconeManager: PineconeViewModel
    @State private var isDeleting = false
    @State private var showError = false
    @State private var deletionSuccess = false
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            // Background
            KiokuBackgroundView()

            VStack(spacing: 27) {
                Spacer()

                Text("Are you sure?")
                    .font(.custom("New York", size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .kiokuShadow()

                Text("This will permanently delete all your saved information from Kioku.")
                    .font(.custom("New York", size: 18))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .lineSpacing(7)
                    .padding(.horizontal, 30)

                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        Task {
                            isDeleting = true
                            let success = await pineconeManager.deleteAllVectorsInNamespace()
                            await MainActor.run {
                                isDeleting = false
                                if success {
                                    deletionSuccess = true
                                } else {
                                    showError = true
                                }
                            }
                        }
                    }) {
                        Text("Delete My Account")
                            .font(.custom("New York", size: 20))
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }

                    Button(action: {
                        if !isDeleting {
                            onCancel()
                        }
                    }){
                        Text("Cancel")
                            .font(.custom("New York", size: 18))
                            .foregroundColor(.black)
                            .padding(.vertical, 12)
                    }.disabled(isDeleting)
                    
                    if showError, let error = pineconeManager.pineconeErrorOnDel {
                        Text(error.localizedDescription)
                            .font(.custom("New York", size: 16))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }

                    if deletionSuccess {
                        Text("Your account was deleted.")
                            .font(.custom("New York", size: 18))
                            .foregroundColor(.black)
                            .padding(.top)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    KDeleteAccountView(onCancel: {
        
    })
}
