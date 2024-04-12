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
    @State private var vectorsAreLoading = false
    
    
    var body: some View {
        
        NavigationStack {

                if !pineconeManger.pineconeFetchedVectors.isEmpty {
                    ScrollView {
                        ForEach(pineconeManger.pineconeFetchedVectors, id: \.self) { data in
                            NavigationLink(destination: EditInfoView(viewModel: EditInfoViewModel(vector: data))) {
                                
                                InfosViewListCellView(data: data).padding()
                            }
                        }
                    }
                } else if vectorsAreLoading {
                    ProgressView()
                }
                else {
                    ProgressView()
//                    ContentUnavailableView(label: {
//                        Label("No Saved Info", systemImage: "tray.2").foregroundStyle(.yellow)
//                    }, description: {
//                        Text(" Saved Info will be shown here.")}
//                                           
//                    ).offset(y: -60)
//                    
                }
            
        }.background {
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
            fetchPineconeEntries()
        }
    }
    
    private func fetchPineconeEntries() {
        self.vectorsAreLoading = true
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
                    // Assuming `deleteVector` removes the vector by its ID and returns a boolean indicating success
                    let result = try await pineconeManger.deleteVector(id: id)
                    if result {
                        DispatchQueue.main.async {
                            // Safely remove the item from the local data to reflect the change
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

