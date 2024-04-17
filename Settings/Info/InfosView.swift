//
//  RecordingsSettingsView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 13.02.24.
//

import SwiftUI

//TODO: pull down to refresh the view with progressView, scroll down to show search textField (look at printscreens for iMessages impl).

//TODO: Progress View when the view appears and Content Unavailable if there are no Entries.
struct InfosView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var pineconeManger: PineconeManager
    @EnvironmentObject var audioManager: AudioManager
    @State private var vectorsAreLoading = true
    
    var body: some View {
        NavigationStack {
            
            if !pineconeManger.pineconeFetchedVectors.isEmpty {
                ScrollView {
                    
                    ForEach(pineconeManger.pineconeFetchedVectors, id: \.self) { data in
                        
                        NavigationLink(destination: EditInfoView(viewModel: EditInfoViewModel(vector: data))) {
                            InfosViewListCellView(data: data).padding()
                        }
                    }
                }.refreshable {
                    Task {
                        do {
                            try await pineconeManger.refreshNamespacesIDs()
                        } catch  {
                            print("Error refreshing: \(error.localizedDescription)")
                        }
                    }
                    
                }
            } else if vectorsAreLoading {
                ProgressView()
            }
            else if !vectorsAreLoading {
                
                ContentUnavailableView(label: {
                    Label("No Saved Info", systemImage: "tray.2")
                }, description: {
                    Text(" Saved Info will be shown here.")}
                                       
                ).offset(y: -60)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color.gray.opacity(0.5).ignoresSafeArea()
        }
        
        .navigationTitle("Manage Info")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Settings")
                    }
                }
            }
        }
        //TODO: show loading/progress and if fetch fails then ContentUnavailableView..
        .onAppear {
            self.vectorsAreLoading = true
            fetchPineconeEntries()
        }
    }
    
    private func fetchPineconeEntries() {
        print("HERE try await pineconeManger.fetchAllNamespaceIDs()")
        Task {
            do {
                try await pineconeManger.fetchAllNamespaceIDs()
            } catch {
                print("Error :: try await pineconeManger.fetchAllNamespaceIDs():: \(error)")
            }
        }
        self.vectorsAreLoading = false
    }
    //TODO: swipe left to show alert dialog for confirmation and then to call this
    private func deleteInfo(at offsets: IndexSet) {
        // Extract the IDs of the vectors to delete based on the offsets
        let idsToDelete = offsets.compactMap { offset -> String? in
            return pineconeManger.pineconeFetchedVectors[offset].id
        }
        
        // Perform deletion from Pinecone and ViewModel
        for id in idsToDelete {
            Task {
                do {
                    try await pineconeManger.deleteVector(id: id)
                    if pineconeManger.vectorDeleted {
                        DispatchQueue.main.async {
                            pineconeManger.pineconeFetchedVectors.removeAll { $0.id == id }
                        }
                    }
                } catch {
                    print("Error deleting vector with ID \(id): \(error)")
                }
            }
        }
    }
    
}

#Preview {
    InfosView()
}

