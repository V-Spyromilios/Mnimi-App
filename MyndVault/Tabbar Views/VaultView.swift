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
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var pineconeManger: PineconeManager
    @State private var vectorsAreLoading: Bool = true
    @State private var errorMessage: String = ""
    @State private var showEmpty: Bool = false
    @State private var showNoInternet = false

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
                            .padding(.top, 20)
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
                    //TODO: Empty the Vault to check:
                    else if showEmpty && !vectorsAreLoading  && errorMessage == "" {
                        VStack {
                            LottieRepresentable(filename: "Woman_vault").frame(height: 280).padding(.bottom)
                            TypingTextView(fullText: "No Info has been saved yet. Add whatever you want to remember!")
                                .padding(.horizontal)
                            
                        }
                    }
                    
                    else if errorMessage != "" {
                        ErrorView(thrownError: errorMessage,extraMessage: "Scroll down to try again!").padding(.horizontal, 7)
                    }
                }
            }
            .refreshable {
                vectorsAreLoading = true
                if errorMessage != "" {
                    errorMessage = ""
                }
                Task {
                    do {
//                        throw AppNetworkError.invalidOpenAiURL
                        try await pineconeManger.refreshNamespacesIDs()
                        await MainActor.run { vectorsAreLoading = false }
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
            //.navigationTitle("Vault 🗃️")
            .navigationBarTitleView { LottieRepresentable(filename: "smallVault").frame(width: 55, height: 55).padding(.bottom, 5).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0) } //TODO: Check how it looks
            //.navigationBarTitleDisplayMode(.large)
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
        .alert(isPresented: $showNoInternet) {
            Alert(
                title: Text("You are not connected to the Internet"),
                message: Text("Please check your connection"),
                dismissButton: .cancel(Text("OK"))
            )
        }
        .onChange(of: networkManager.hasInternet) { _, hasInternet in
            if !hasInternet {
                showNoInternet = true
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
                await MainActor.run {  self.vectorsAreLoading = false }
            }
            catch let error as AppNetworkError {
                await MainActor.run {
                    self.vectorsAreLoading = false
                    self.errorMessage = error.errorDescription }
            }
            catch let error as AppCKError {
                await MainActor.run {
                    self.vectorsAreLoading = false
                    self.errorMessage = error.errorDescription }
            }
            catch {
                await MainActor.run {
                    self.vectorsAreLoading = false
                    self.errorMessage = error.localizedDescription }
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

