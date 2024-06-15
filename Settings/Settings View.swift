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
            VStack {
                Button {
                    Task {
                    
                            if let recordID = cloudKit.fetchedNamespaceDict.keys.first {
                                try await cloudKit.deleteNamespaceItem(recordID: recordID)
                            }
                        }} label: {
                            Text("Delete Namespace.")
                        }
                    
                if errorString != "" {
                    Text(errorString)
                }
                List {
                    NavigationLink(destination: PromptLanguageView()) { Text("Prompt Language") }
                }
            }
            .navigationTitle("Settings ⚙️")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            showSettings.toggle() }
                    } label: {
                        Circle()
                        
                            .foregroundStyle(.white)
                            .frame(height: 30)
                            .shadow(radius: toolbarButtonShadow)
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
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .shadow(radius: toolbarButtonShadow)
                            Text("🚪")
                        }.padding()
                            .accessibilityLabel("Log out from Mynd Vault app")
                    }
                    
                }
                
            }
        }.statusBar(hidden: true)
        
    }
}


#Preview {
    SettingsView(showSettings: .constant(true))
}
