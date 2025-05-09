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

            KiokuBackgroundView()

            VStack(spacing: 27) {
                Spacer()

                if deletionSuccess == false {
                    Text("Are you sure?")
                        .font(.custom("New York", size: 24))
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
                        .font(.custom("New York", size: 24))
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
                            .foregroundColor(.black)
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
                            .padding(.vertical, 16)
                    }.disabled(isDeleting)
                    
                    if showError, let error = pineconeManager.pineconeErrorOnDel {
                        Text(error.localizedDescription)
                            .font(.custom("New York", size: 16))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
//            .onAppear {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
//                    withAnimation {
//                        deletionSuccess.toggle() }
//                }
//            }
            .transition(.opacity)
        }
        .statusBarHidden()
    }
}

#Preview {
    KDeleteAccountView(onCancel: {
        
    })
}
