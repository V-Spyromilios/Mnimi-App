//
//  Settings View.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 10.02.24.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var cloudKit: CloudKitViewModel
    
    var viewModel = PineconeManager()
    @Binding var showSettings: Bool
    @State private var errorString = ""
    
    var body: some View {

        NavigationView {
            
            
            List {
                NavigationLink(destination: PromptLanguageView()) { Text("Prompt Language")
                    
                }
            }
            
            .padding(.top, 12)
            .navigationTitle("Settings ⚙️")
            
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            showSettings.toggle() }
                    } label: {
                        Circle()
                        
                            .foregroundStyle(Color.buttonText)
                            .frame(height: 30)
                            .shadow(color: Color.customShadow, radius: toolbarButtonShadow)
                            .accessibilityLabel("Close Settings")
                            .overlay {
                                Image(systemName: "xmark") }
                        
                    }.padding()
                        .accessibilityLabel("Close Settings")
                    
                }
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        withAnimation {
                            authManager.logout() }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(lineWidth: 1)
                                .foregroundColor(.red)
                                .frame(width: 30, height: 30)
                            
                            Circle()
                                .foregroundStyle(Color.buttonText)
                                .frame(width: 30, height: 30)
                                .shadow(color: Color.customShadow, radius: toolbarButtonShadow)
                            Text("🚪")
                        }.padding()
                            .accessibilityLabel("Log out.")
                    }
                    
                }
                
            }
            
        }.statusBar(hidden: true)
        
        
    }
}


#Preview {
    SettingsView(showSettings: .constant(true))
}
