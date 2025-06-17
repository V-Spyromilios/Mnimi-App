//
//  CustomPayWall.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 09.05.25.
//

import SwiftUI
import RevenueCat

struct CustomPaywallView: View {
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var monthly: Package?
    @State private var annual: Package?

    var onCancel: () -> Void

    var body: some View {
        ZStack {
            KiokuBackgroundView()

            VStack(spacing: 27) {
                Spacer()

                if purchaseError == nil {
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
                } else {
                    Text("Error completing purchase.")
                        .font(.custom("New York", size: 24))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .kiokuShadow()
                    
                    Text(purchaseError ?? "Please try again later.")
                        .font(.custom("New York", size: 18))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .lineSpacing(7)
                        .padding(.horizontal, 30)
                }

                Spacer()

                VStack(spacing: 22) {
                    if let annual = annual {
                        Button(action: {
                            purchase(package: annual)
                        }) {
//                            Text("Upgrade to Annual for €24.99")
                            Text("Upgrade to Annual for \(annual.localizedPriceString)")
                                .font(.custom("New York", size: 20))
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                        }
                        .opacity(isPurchasing ? 0.5 : 1.0)
                        .animation(.easeInOut, value: isPurchasing)
                    }

                    if let monthly = monthly {
                        Button(action: {
                            purchase(package: monthly)
                        }) {
                           
//                            Text("Upgrade to Monthly for  €2.99")
                            Text("Upgrade to Monthly for \(monthly.localizedPriceString)")
                                .font(.custom("New York", size: 20))
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                        }
                        .opacity(isPurchasing ? 0.5 : 1.0)
                        .animation(.easeInOut, value: isPurchasing)
                    }

                    Button(action: {
                        if !isPurchasing {
                            onCancel()
                        }
                    }) {
                        Text("Maybe Later")
                            .font(.custom("New York", size: 18))
                            .foregroundColor(.black)
                            .padding(.vertical, 20)
                    }
                    .disabled(isPurchasing)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
            .transition(.opacity)
        }
        .statusBarHidden()
        .onAppear {
            fetchPackages()
        }
    }

    private func fetchPackages() {
        Purchases.shared.getOfferings { offerings, error in
            if error != nil {
                debugLog("ERROR:")
                debugLog(error.debugDescription)
                debugLog(error?.localizedRecoverySuggestion ?? "DEgage")
            }
            if let current = offerings?.current {
                self.monthly = current.monthly
                self.annual = current.annual
                
                for pkg in current.availablePackages {
                    debugLog("Available package: \(pkg.identifier) - \(pkg.storeProduct.localizedTitle) - \(pkg.localizedPriceString)")
                }
            } else {
                purchaseError = "\(error?.localizedDescription ?? "Unknown error")"
            }
        }
    }

    private func purchase(package: Package) {
        isPurchasing = true
        Purchases.shared.purchase(package: package) { transaction, info, error, userCancelled in
            DispatchQueue.main.async {
                isPurchasing = false

                if let error = error {
                    purchaseError = error.localizedDescription
                } else if userCancelled {
                    purchaseError = "Purchase cancelled."
                } else if let transaction = transaction, let info = info {
                    // Purchase successful
                    onCancel() // Dismiss paywall
                } else {
                    purchaseError = "Unknown issue during purchase."
                }
            }
        }
    }
}

#Preview {
    CustomPaywallView(onCancel: {})
}
