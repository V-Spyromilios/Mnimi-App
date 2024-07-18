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
    @State private var errorMessage: String = ""
    @State private var showEmpty: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack() {
                    if vectorsAreLoading {
                        ProgressView()
                            .font(.title)
                            .scaleEffect(1.5)
                            .bold()
                            .background(Color.clear.ignoresSafeArea())
                            .foregroundStyle(Color.britishRacingGreen)//TODO: Replace with Lottie
                    }
                    
                    else if !vectorsAreLoading && !pineconeManger.pineconeFetchedVectors.isEmpty && errorMessage == "" {
                        ForEach(pineconeManger.pineconeFetchedVectors.indices, id: \.self) { index in
                                                       let data = pineconeManger.pineconeFetchedVectors[index]
                            
                            NavigationLink(destination: EditInfoView(viewModel: EditInfoViewModel(vector: data))) {
                                InfosViewListCellView(data: data)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 12)
                            }
                        }
                    }
                    
                    else if showEmpty && !vectorsAreLoading  && errorMessage == "" {
                        
                        ContentUnavailableView(label: {
                            Label("No Saved Info", systemImage: "tray.2")
                        }, description: {
                            Text(" Saved Info will be shown here.")}
                                               
                        ).offset(y: contentUnaivalableOffset)
                        
                    }
                    
                    else if errorMessage != "" {
                        ErrorView(thrownError: errorMessage,extraMessage: "Scroll down to try again!").padding(.horizontal, 7)
                    }
                }
            }
            .refreshable {
                Task {
                    do {
//                        throw AppNetworkError.invalidOpenAiURL
                        try await pineconeManger.refreshNamespacesIDs()
                    } 
                    catch let error as AppNetworkError {
                        await MainActor.run {
                            self.errorMessage = error.errorDescription }
                    }
                    catch let error as AppCKError {
                        await MainActor.run {
                            self.errorMessage = error.errorDescription }
                    }
                    catch {
                        await MainActor.run {
                            self.errorMessage = error.localizedDescription }
                    }
                }
            }
            .navigationTitle("Vault 🗃️")
            .navigationBarTitleDisplayMode(.large)
            .background { Color.primaryBackground.ignoresSafeArea() }
        }
        //        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .alert(isPresented: $showAlert) {
//            Alert(
//                title: Text("Error fetching Info"),
//                message: Text("\(alertMessage), Scroll down to retry!"),
//                dismissButton: .default(Text("OK"))
//            )
//        }
        .onAppear {
            if pineconeManger.pineconeFetchedVectors.isEmpty {
                self.vectorsAreLoading = true
                fetchPineconeEntries()
            }
        }
        .onReceive(pineconeManger.$pineconeFetchedVectors) { vectors in

            if vectors.isEmpty {
                showEmpty = true
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
            }
            catch let error as AppNetworkError {
                await MainActor.run {
                    self.errorMessage = error.errorDescription }
            }
            catch let error as AppCKError {
                await MainActor.run {
                    self.errorMessage = error.errorDescription }
            }
            catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription }
            }
            DispatchQueue.main.async {
                self.vectorsAreLoading = false
            }
        }
    }

    private func deleteInfo(at offsets: IndexSet) {

        let idsToDelete = offsets.compactMap { offset -> String? in
            return pineconeManger.pineconeFetchedVectors[offset].id
        }
        
        // delete from pinecone and viewModel
        for id in idsToDelete {
            Task {
                do {
                    try await pineconeManger.deleteVectorFromPinecone(id: id)
                    if pineconeManger.vectorDeleted {
                        DispatchQueue.main.async {
                            pineconeManger.pineconeFetchedVectors.removeAll { $0.id == id }
                        }
                    }
                }
                catch let error as AppNetworkError {
                    await MainActor.run {
                        self.errorMessage = error.errorDescription }
                }
                catch let error as AppCKError {
                    await MainActor.run {
                        self.errorMessage = error.errorDescription }
                }
                catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription }
                }
            }
        }
    }

}

#Preview {
    VaultView()
}

