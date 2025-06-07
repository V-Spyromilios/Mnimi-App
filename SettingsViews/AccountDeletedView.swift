//
//  AccountDeletedView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 11.01.25.
//

import SwiftUI

struct AccountDeletedView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var pineconeVm: PineconeViewModel
    
    var body: some View {

        ZStack {
            Color.secondary.opacity(0.4).ignoresSafeArea()
            
        VStack(spacing: 24)
            {
                Image(systemName: "checkmark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.green)
                
                Text("Account Deleted")
                    .font(.title)
                    .bold()
                
                Text("All of your data has been removed.\nWe really value your thoughts—please share any feedback about your experience with MyndVault.")
                    .font(Font.custom("SF Mono Semibold", size: 16))
                    .fontDesign(.monospaced)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
//                if let url = URL(string: "https://polydactyl-drain-3f7.notion.site/MyndVault-d74ca5df50374eada3193a64c1cee7dc?pvs=4") {
//                    CoolButton(title: "Give Feedback", systemImage: "megaphone") {
//                        UIApplication.shared.open(url)
//                        
//                    }
                    .padding(.top, 20)
                }
            }
            .padding()
            .onAppear {
                UserDefaults.standard.set(false, forKey: "accountDeleted")
                pineconeVm.accountDeleted = false
            }
        }
    }

#Preview {
    AccountDeletedView()
}
