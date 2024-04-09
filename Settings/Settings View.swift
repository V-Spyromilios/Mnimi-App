//
//  Settings View.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 10.02.24.
//

import SwiftUI

struct SettingsView: View {
    var viewModel = PineconeManager()
    
    var body: some View {
        
            NavigationView {
                List {
                    NavigationLink(destination: PromptLanguageView()) { Text("Prompt Language") }
                    
                    NavigationLink(destination: InfosView()) { Text("Saved info") }
                    
                    NavigationLink(destination: DeveloperView()) { Text("Developer") }
                    
                    NavigationLink(destination: RecordingsSettingsView()) { Text("Recordings") }
                }
                .navigationTitle("Settings")
                .toolbar {
                                // Define specific toolbar items for this view or leave it empty to not show any.
                            }
            }
            
        }
}

#Preview {
    SettingsView()
}
