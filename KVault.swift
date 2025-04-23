//
//  KVault.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 23.04.25.
//

import SwiftUI

struct KVault: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var pineconeVm: PineconeViewModel
    @EnvironmentObject var openAiManager: OpenAIViewModel
    
    @State private var vectorsAreLoading: Bool = true
    @State private var showEmpty: Bool = false
    @State private var showNoInternet = false
    @State private var searchText: String = ""
    
    @State private var selectedVector: Vector? = nil
    @State private var showEditSheet = false

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
        ZStack {
            Image("oldPaper")
                .resizable()
                .scaledToFill()
                .blur(radius: 1)
                .opacity(0.85)
                .ignoresSafeArea()

            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.6), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .center, spacing: 24) {
                    if vectorsAreLoading {
                        Text("Loading...")
                            .font(.custom("New York", size: 20))
                            .foregroundColor(.black)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                            .padding(.horizontal, 24)
                    } else if !pineconeVm.pineconeFetchedVectors.isEmpty && pineconeVm.pineconeErrorFromEdit == nil {
                        ForEach(Array(filteredVectors.enumerated()), id: \.element.id) { _, data in
                            Button {
                                selectedVector = data
                                showEditSheet = true
                            } label: {
                                VaultCellView(data: data)
                                    .padding(.horizontal, 24)
                            }
                            .buttonStyle(.plain)
                        }
                    } else if pineconeVm.pineconeFetchedVectors.isEmpty && pineconeVm.pineconeErrorFromEdit == nil {
                        Text("Nothing saved...")
                            .font(.custom("New York", size: 20))
                            .foregroundColor(.black)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                            .padding(.horizontal, 24)
                    } else if let error = pineconeVm.pineconeErrorFromEdit {
                        errorView(error.localizedDescription)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 32)
            }
            .frame(maxWidth: 600) // soft constraint for tablets
            .padding(.horizontal)
            .sheet(isPresented: $showEditSheet) {
                if let vector = selectedVector {
                    EditInfoView(viewModel: EditInfoViewModel(vector: vector))
                } else {
                    Text("vector is nil").bold()
                }
            }
        }.frame(maxWidth: 400)
        .onAppear {
            if pineconeVm.pineconeFetchedVectors.isEmpty && !pineconeVm.accountDeleted {
                vectorsAreLoading = true
                fetchPineconeEntries()
            }
        }
        .onReceive(pineconeVm.$pineconeFetchedVectors) { vectors in
            vectorsAreLoading = false
            showEmpty = vectors.isEmpty
        }
        .onReceive(pineconeVm.$pineconeErrorFromEdit) { error in
            if error != nil {
                vectorsAreLoading = false
            }
        }
        .onChange(of: networkManager.hasInternet) { _, hasInternet in
            if !hasInternet {
                showNoInternet = true
            }
        }
        .alert(isPresented: $showNoInternet) {
            Alert(
                title: Text("You are not connected to the Internet"),
                message: Text("Please check your connection"),
                dismissButton: .cancel(Text("OK"))
            )
        }
    }

    private func fetchPineconeEntries() {
        if pineconeVm.accountDeleted { return }
        vectorsAreLoading = true
        
        pineconeVm.refreshNamespacesIDs()
    }
    private func errorView(_ message: String) -> some View {
        VStack {
            Text(message).multilineTextAlignment(.leading) .padding(.top, 40)
                .padding(.leading, 30)
            Button("Cancel") {
                withAnimation { pineconeVm.clearManager() }
            }.underline().padding(.top, 20)
        }
        .buttonStyle(.plain)
        .underline()
        .font(.custom("New York", size: 20))
        .foregroundColor(.black)
    }
}


struct VaultCellView: View {
    let data: Vector
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            let note = data.metadata["description"] ?? "Empty note."
            let dateText = dateFromISO8601(isoDate: data.metadata["timestamp"] ?? "").map { formatDateForDisplay(date: $0) } ?? ""

            VStack(alignment: .leading, spacing: 8) {
                Text("\"\(note)\"")
                    .font(.custom("New York", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                Text("(\(dateText))")
                    .font(.custom("New York", size: 14))
                    .italic()
                    .foregroundColor(.black.opacity(0.8))
            }
            .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: 350, alignment: .leading)
        .background(
            Image("oldPaper2")
                .resizable()
                .scaledToFill()
                .clipped()
                .opacity(0.2)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    let cloudKit = CloudKitViewModel.shared
    let pineconeActor = PineconeActor(cloudKitViewModel: cloudKit)
    let openAIActor = OpenAIActor()
    let languageSettings = LanguageSettings.shared
    let pineconeViewModel = PineconeViewModel(pineconeActor: pineconeActor, CKviewModel: cloudKit)
    let networkManager = NetworkManager()
    
    KVault()
        .environmentObject(pineconeViewModel)
        .environmentObject(networkManager)
}




//#Preview {
//    
//    let formatter = ISO8601DateFormatter()
//    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
//    
//    let mockVector = Vector(
//        id: UUID().uuidString,
//        metadata: [
//            "description": "Lunch with Leo on Friday. Don’t forget the location is Café Central.",
//            "timestamp":  formatter.string(from: Date())
//        ]
//    )
//    
//    return VaultCellView(data: mockVector)
//        
//        .padding()
//        .background(Color.white)
//}
