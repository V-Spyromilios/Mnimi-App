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
    @State private var vectorsAreLoading = true
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showErrorUnavailable: Bool = false
    @State private var showUnavailable: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack() {
                    if vectorsAreLoading {
                        ProgressView().font(.title).bold().padding(.top, 40)
                    }
                    
                    else if !vectorsAreLoading && !pineconeManger.pineconeFetchedVectors.isEmpty {
                        ForEach(pineconeManger.pineconeFetchedVectors.indices, id: \.self) { index in
                                                       let data = pineconeManger.pineconeFetchedVectors[index]
                            GeometryReader { geometryProxy in
                            NavigationLink(destination: EditInfoView(viewModel: EditInfoViewModel(vector: data))) {
                                InfosViewListCellView(data: data).padding(.horizontal, 7)
                                    .visualEffect(geometryProxy: geometryProxy, height: 80)
                                    .padding(.top, 50)
                                    .zIndex(Double(pineconeManger.pineconeFetchedVectors.count - index)) // Ensure the correct z-index
                                
                            }
                            }.frame(height: 80)
                        }
                    }
                    
                    else if showUnavailable {
                        
                        ContentUnavailableView(label: {
                            Label("No Saved Info", systemImage: "tray.2")
                        }, description: {
                            Text(" Saved Info will be shown here.")}
                                               
                        ).offset(y: contentUnaivalableOffset)
                        
                    }
                    else if !vectorsAreLoading && !pineconeManger.pineconeFetchedVectors.isEmpty {
                        ForEach(pineconeManger.pineconeFetchedVectors, id: \.self) { data in
                            GeometryReader { geometryProxy in
                                
                                NavigationLink(destination: EditInfoView(viewModel: EditInfoViewModel(vector: data))) {
                                    InfosViewListCellView(data: data)
                                        .frame(height: 80).padding()
                                    
                                }
                            }.frame(height: 80)
                        }
                    }
                    
                    else if showErrorUnavailable && pineconeManger.pineconeFetchedVectors.isEmpty {
                        ContentUnavailableView(label: {
                            Label("Unable to fetch data", systemImage: "tray.2")
                        }, description: {
                            Text(" please check your connection.")}
                                               
                        ).offset(y: contentUnaivalableOffset)
                    }
                }
            }
            .refreshable {
                Task {
                    do {
                        try await pineconeManger.refreshNamespacesIDs()
                    } catch  {
                        showErrorUnavailable  = true
                        print("Error refreshing: \(error.localizedDescription)")
                    }
                }
            }
            .navigationTitle("Vault 🗃️")
            .navigationBarTitleDisplayMode(.large)
            .background { Color.primaryBackground.ignoresSafeArea() }
        }
        //        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error fetching Info"),
                message: Text("\(alertMessage), Scroll down to retry!"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            if pineconeManger.pineconeFetchedVectors.isEmpty {
                self.vectorsAreLoading = true
                fetchPineconeEntries()
            }
        }
        .onReceive(pineconeManger.$pineconeFetchedVectors) { _ in
            print("onReceive :: Fetched Vectors changed.")
            if pineconeManger.pineconeFetchedVectors.isEmpty {
                showUnavailable = true
            }
        }
    }

        func minY(_ proxy: GeometryProxy) -> CGFloat {
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            return minY < 0 ? -minY : 0
        }
        

        func scale(_ proxy: GeometryProxy, scale: CGFloat = 0.1) -> CGFloat {
            let val = 1.0 - (progress(proxy) * scale)
            return val
        }
        
        
        func excessTop(_ proxy: GeometryProxy, offset: CGFloat = 12) -> CGFloat {
            let p = progress(proxy)
            return -p * offset
        }
        
        
         func brightness(_ proxy: GeometryProxy) -> CGFloat {
            let progress = progress(proxy)
            let variation = 0.2
            let threshold = -0.2
            let value = -progress * variation
            return value < threshold ? threshold : value
        }
        
       
         func progress(_ proxy: GeometryProxy) -> CGFloat {
            // when a card reached its top, start to calculate its progress
            if (minY(proxy) == 0) {
                return 0
            }
            // start to calculate progress
            let maxY = proxy.frame(in: .scrollView(axis: .vertical)).maxY
            let height = 80.0 //card height
            let progress = 1.0 - ((maxY / height))
            return progress
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
                    try await pineconeManger.deleteVectorFromPinecone(id: id)
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

