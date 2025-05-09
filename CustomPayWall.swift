//
//  CustomPayWall.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 09.05.25.
//

import SwiftUI

import SwiftUI
import RevenueCat

struct CustomPaywallView: View {
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            KiokuBackgroundView()

            VStack(spacing: 27) {
                Spacer()

                Text("You've reached your free limit.")
                    .font(.custom("New York", size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .kiokuShadow()

                Text("Upgrade to Mnimi Pro for unlimited usage and priority AI responses.")
                    .font(.custom("New York", size: 18))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .lineSpacing(7)
                    .padding(.horizontal, 30)

                Spacer()

                VStack(spacing: 16) {
                    Button(action: {
                        isPurchasing = true
                        Purchases.shared.getOfferings { offerings, error in
                            Purchases.shared.purchase(package: package) { _, _, userCancelled, error in
                                isPurchasing = false

                                if let error = error, !userCancelled {
                                    purchaseError = error.localizedDescription
                                }
                            
                            } else {
                                isPurchasing = false
                                purchaseError = "No packages available at this time."
                            }
                        }
                    }) {
                        Text("Upgrade Now")
                            .font(.custom("New York", size: 20))
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .disabled(isPurchasing)

                    Button(action: {
                        if !isPurchasing {
                            onCancel()
                        }
                    }) {
                        Text("Maybe Later")
                            .font(.custom("New York", size: 18))
                            .foregroundColor(.black)
                            .padding(.vertical, 16)
                    }
                    .disabled(isPurchasing)

                    if let error = purchaseError {
                        Text(error)
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
            .transition(.opacity)
        }
        .statusBarHidden()
    }
}

#Preview {
    CustomPaywallView(onCancel: {})
}
