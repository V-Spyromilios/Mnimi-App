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
        @EnvironmentObject var pineconeVm: PineconeViewModel
        @State private var vectorsAreLoading: Bool = true
        @State private var showEmpty: Bool = false
        @State private var showNoInternet = false
        @State private var searchText: String = ""
        @State private var selectedInfo : Vector?
        @State private var showEdit: Bool = false

        var filteredVectors: [Vector] {
            if searchText.isEmpty {
                return pineconeVm.pineconeFetchedVectors
            } else {
                return pineconeVm.pineconeFetchedVectors.filter { vector in
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
                            
                            if pineconeVm.accountDeleted {
                                VStack {
                                    HStack(alignment: .center) {
                                        Spacer()
                                        TypingTextView(fullText: "Account Deleted.", isTitle: true)
                                        Spacer()
                                    }
                                    LottieRepresentable(filename: "Woman_vault").frame(height: 280).padding(.bottom)
                                        .padding(.horizontal)
                                }
                                .transition(.opacity)
                            }
                            else if vectorsAreLoading {
                               LoadingDotsView()
                                    .if(isIPad()) { loadingDots in
                                        loadingDots.padding(.top, 40)
                                    }
                                    .if(!isIPad()) { loadingDots in
                                        loadingDots.padding(.top, 20)
                                    }
                                    .transition(.opacity)
    //                                .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                            }
                            
                            else if !vectorsAreLoading && !pineconeVm.pineconeFetchedVectors.isEmpty && pineconeVm.pineconeError == nil {
                                ForEach(Array(filteredVectors.enumerated()), id: \.element.id) { index, data in
                                    NavigationLink(destination: EditInfoView(viewModel: EditInfoViewModel(vector: data))) {
                                        InfosViewListCellView(data: data)
                                            .padding(.horizontal, Constants.standardCardPadding)
                                            .padding(.vertical)
                                            .transition(.opacity)
    //                                        .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                                    }
                                }
                            }
                            
                            else if  pineconeVm.pineconeFetchedVectors.isEmpty && !vectorsAreLoading && pineconeVm.pineconeError == nil {
                                VStack {
                                    LottieRepresentable(filename: "Woman_vault").frame(height: 280).padding(.bottom)
                                    TypingTextView(fullText: "No Info has been saved. Add whatever you want to remember!")
                                        .shadow(radius: 1)
                                        .padding(.horizontal)
                                }
                                .transition(.opacity)
    //                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                            }
                            
                            else if pineconeVm.pineconeError != nil && !pineconeVm.accountDeleted {
                                ErrorView(thrownError: pineconeVm.pineconeError!.localizedDescription) {
                                    pineconeVm.pineconeError = nil
                                }
                                .transition(.opacity)
    //                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                            }
                        }
                        .searchable(text: $searchText) //Do not move outside of the Scroll. makes top padding when return from EditView
                    }
    //                .padding(.top, 12)
                    .refreshable {
                        if pineconeVm.accountDeleted { return }
                        withAnimation {
                            vectorsAreLoading = true
                            pineconeVm.refreshNamespacesIDs()
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
                            
                            LottieRepresentableNavigation(filename: "smallVault").frame(width: 55, height: 55)
                                .shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0)
                                .padding(.top, 7)
                        }
                        .padding(.top, isIPad() ? 15: 0)
                        .padding(.bottom)
                    }
                }
                
            }
            
            .onAppear {
                if pineconeVm.pineconeFetchedVectors.isEmpty && !pineconeVm.accountDeleted {
                    withAnimation {
                        self.vectorsAreLoading = true
                    }
                    fetchPineconeEntries()
                }
                
            }
            .onReceive(pineconeVm.$pineconeFetchedVectors) { vectors in
                withAnimation {
                    self.vectorsAreLoading = false
                }
                if vectors.isEmpty {
                    withAnimation {
                        showEmpty = true
                    }
                } else {
                    withAnimation {
                        showEmpty = false
                    }
                }
            }
            .onReceive(pineconeVm.$pineconeError) { error in
                if error != nil {
                    withAnimation {
                        self.vectorsAreLoading = false
                    }
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
                    withAnimation {
                        showNoInternet = true
                    }
                }
            }
            
        }
        
    //    private func clearSelectedInfo() {
    //        self.selectedInfo = nil
    //    }
        
        
        private func fetchPineconeEntries() {
            if pineconeVm.accountDeleted { return }

            vectorsAreLoading = true
            pineconeVm.refreshNamespacesIDs()
        }
        
//        private func deleteInfo(at offsets: IndexSet) {
//            let idsToDelete = offsets.compactMap { offset -> String? in
//                return pineconeVm.pineconeFetchedVectors[offset].id
//            }
//
//            for id in idsToDelete {
//                pineconeVm.deleteVectorFromPinecone(id: id)
//            }
//        }
        
    }

    struct VaultView_Previews: PreviewProvider {
        
        
        static var previews: some View {
            VaultView()
            
        }
    }
