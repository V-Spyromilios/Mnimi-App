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
    @State private var searchText: String = ""
    @State private var selectedInfo : Vector?
    @State private var showEdit: Bool = false
   
    
    var filteredVectors: [Vector] {
        if searchText.isEmpty {
            return pineconeManger.pineconeFetchedVectors
        } else {
            return pineconeManger.pineconeFetchedVectors.filter { vector in
                if let description = vector.metadata["description"] {
                    return description.lowercased().contains(searchText.lowercased())
                }
                return false
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
               
                ScrollView {
                    LazyVStack {
                        
                        if pineconeManger.accountDeleted {
                            VStack {
                                HStack(alignment: .center) {
                                    Spacer()
                                    TypingTextView(fullText: "Account Deleted.", isTitle: true)
                                    Spacer()
                                }
                                LottieRepresentable(filename: "Woman_vault").frame(height: 280).padding(.bottom)
                                    .padding(.horizontal)
                            }.transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                        }
                        else if vectorsAreLoading {
                            ProgressView()
                                .font(.title)
                                .scaleEffect(1.5)
                                .bold()
                                .background(Color.clear.ignoresSafeArea())
                                .foregroundStyle(Color.customLightBlue)//TODO: Replace with Lottie
                                .padding(.top, 20)
                                .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                        }
                        
                        else if !vectorsAreLoading && !pineconeManger.pineconeFetchedVectors.isEmpty && errorMessage == "" {
                            ForEach(filteredVectors.indices.indices, id: \.self) { index in
                                let data = filteredVectors[index]
                                
                                NavigationLink(destination: EditInfoView(viewModel: EditInfoViewModel(vector: data))) {
                                    InfosViewListCellView(data: data)
                                        .padding(.horizontal, Constants.standardCardPadding)
                                        .padding(.vertical)
                                       
                                }
                            } .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                            .searchable(text: $searchText)
                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                        }
                        //TODO: Empty the Vault to check:
                        else if  pineconeManger.pineconeFetchedVectors.isEmpty && !vectorsAreLoading  && errorMessage == "" {
                            VStack {
                                LottieRepresentable(filename: "Woman_vault").frame(height: 280).padding(.bottom)
                                TypingTextView(fullText: "No Info has been saved. Add whatever you want to remember!")
                                    .shadow(radius: 1)
                                    .padding(.horizontal)
                            }.transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                        }
                        
                        else if errorMessage != "" && !pineconeManger.accountDeleted {
                            ErrorView(thrownError: errorMessage) {
                                self.errorMessage = ""
                            }
                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                        }
                    }
                 

                }
                .padding(.top, 12)
                .refreshable {
                    if pineconeManger.accountDeleted { return }
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
                .background {
                    LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                        .opacity(0.4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                }
                .navigationBarTitleView {
                    HStack {
                        Text("Vault").font(.title2).bold().foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded).padding(.trailing, 6)
                        LottieRepresentableNavigation(filename: "smallVault").frame(width: 55, height: 55).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0) }
                  
                    //TODO: Check how it looks
                    .padding(.bottom)
                }
                }
           
        }

        .onAppear {
            if pineconeManger.pineconeFetchedVectors.isEmpty && !pineconeManger.accountDeleted {
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

    private func clearSelectedInfo() {
        self.selectedInfo = nil
    }


    private func fetchPineconeEntries() {
        
        if pineconeManger.accountDeleted { return }
        
        Task {
            do {
                try await pineconeManger.fetchAllNamespaceIDs()
                await MainActor.run {  self.vectorsAreLoading = false }
            }
            catch let error as AppNetworkError {
                print("APPNetworlError: \(error.errorDescription)")
                await MainActor.run {
                    self.vectorsAreLoading = false
                    self.errorMessage = error.errorDescription }
            }
            catch let error as AppCKError {
                await MainActor.run {
                    print("APPCKError: \(error.errorDescription)")
                    self.vectorsAreLoading = false
                    self.errorMessage = error.errorDescription }
            }
            catch {
                await MainActor.run {
                    print("otehr lError: \(error.localizedDescription)")
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

struct VaultView_Previews: PreviewProvider {
   
    
    static var previews: some View {
        VaultView()
     
    }
}
