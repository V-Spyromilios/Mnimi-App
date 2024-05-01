//
//  Settings View.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 10.02.24.
//

import SwiftUI

struct SettingsView: View {
    var viewModel = PineconeManager()
    @Binding var showSettings: Bool
    var body: some View {
        
        NavigationView {
            List {
                NavigationLink(destination: PromptLanguageView()) { Text("Prompt Language") }
                
                NavigationLink(destination: VaultView()) { Text("Saved info") }
                
                NavigationLink(destination: DeveloperView()) { Text("Developer") }
                
                NavigationLink(destination: RecordingsSettingsView()) { Text("Recordings") }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            showSettings.toggle() }
                    } label: {
                        Circle()
                          
                            .foregroundStyle(.white)
                            .frame(height: 30)
                            .shadow(radius: 10)
                            .overlay {
                                Image(systemName: "xmark") }
                            
                    }.padding(.trailing)
                }
            }
        }
        }
}

#Preview {
    SettingsView(showSettings: .constant(true))
}
