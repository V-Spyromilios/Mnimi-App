//
//  RecordingsSettingsView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 13.02.24.
//

import SwiftUI


struct InfosView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var modelContext
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var pineconeManger: PineconeManager
    
    @ObservedObject var viewModel = RecordingsViewModel()
    @EnvironmentObject var audioManager: AudioManager
    @State var isEditViewPresented: Bool = false
    
    let dateFormatter = DateFormatter()
    //    @State var upsertedData: [[String: String]] = [[:]]
    
    @State var ids:[String] = []
    
    init() {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    }
    
    var body: some View {
        NavigationStack {
            if !pineconeManger.pineconeFetchedVectors.isEmpty {
                List {
                    ForEach(pineconeManger.pineconeFetchedVectors, id: \.self) { data in
                        NavigationLink(destination: EditInfoView(viewModel: EditInfoViewModel(vector: data))) {
                            VStack {
                                InfosViewListCellView(data: data)
                              
                            }
                        }
                    }
                    .onDelete(perform: deleteInfo)
                }
            } else {
                ContentUnavailableView(label: {
                    Label("No Saved Info", systemImage: "tray.2").foregroundStyle(.yellow)
                }, description: {
                    Text(" Saved Info will be shown here.")}
                                       
                ).offset(y: -60)
            }
        }

        .navigationTitle("info")
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
            Task {
                do {
                    try await pineconeManger.fetchAllNamespaceIDs()
                } catch {
                    print("Error :: try await pineconeManger.fetchAllNamespaceIDs():: \(error)")
                }
            }
        }
        
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

