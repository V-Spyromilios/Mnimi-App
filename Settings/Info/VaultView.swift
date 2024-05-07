//
//  Vault.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 13.02.24.
//

import SwiftUI

struct VaultView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var pineconeManger: PineconeManager
    @EnvironmentObject var audioManager: AudioManager
    @State private var vectorsAreLoading = true
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationStack {
            
            ScrollView {
                if vectorsAreLoading {
                    ProgressView().font(.title).bold().padding(.top, 40)
                }
                if !pineconeManger.pineconeFetchedVectors.isEmpty {
                    
                    ForEach(pineconeManger.pineconeFetchedVectors, id: \.self) { data in
                        
                        NavigationLink(destination: EditInfoView(viewModel: EditInfoViewModel(vector: data))) {
                            InfosViewListCellView(data: data).padding()
                            
                        }
                    }
                }
                
                else if !vectorsAreLoading {
                   
                    ContentUnavailableView(label: {
                        Label("No Saved Info", systemImage: "tray.2")
                    }, description: {
                        Text(" Saved Info will be shown here.")}
                                           
                    )
                   
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
            .navigationTitle("Vault 🗃️")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error fetching Info"),
                message: Text(alertMessage),
                dismissButton: .cancel()
            )
        }
        .onAppear {
            self.vectorsAreLoading = true
            fetchPineconeEntries()
        }
    }
    
    private func fetchPineconeEntries() {
        Task {
            do {
                try await pineconeManger.fetchAllNamespaceIDs()
            } catch(let error) {
                alertMessage = error.localizedDescription
                showAlert.toggle()
            }
            DispatchQueue.main.async {
                
                self.vectorsAreLoading = false
            }
        }
    }

    private func deleteInfo(at offsets: IndexSet) {
        // Extract the IDs of the vectors to delete based on the offsets
        let idsToDelete = offsets.compactMap { offset -> String? in
            return pineconeManger.pineconeFetchedVectors[offset].id
        }
        
        // deletion from Pinecone and ViewModel
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
    VaultView()
}

