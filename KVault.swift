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
                VStack(spacing: 24) {
                    if vectorsAreLoading {
                       Text("Loading...")
                            .font(.custom("New York", size: 20))
                            .foregroundColor(.black)
                            .italic()
                            .padding(.top, 40)
                    } else if !pineconeVm.pineconeFetchedVectors.isEmpty && pineconeVm.pineconeErrorFromEdit == nil {
                        ForEach(Array(filteredVectors.enumerated()), id: \.element.id) { index, data in
                            Button {
                                selectedVector = data
                                showEditSheet = true
                            } label: {
                                VaultCellView(data: data)
                                    .padding(.horizontal, 16)
                            }
                            .buttonStyle(PlainButtonStyle()) // Removes default button tint
                        }
                    } else if pineconeVm.pineconeFetchedVectors.isEmpty && pineconeVm.pineconeErrorFromEdit == nil {
                        Text("Nothing saved...")
                             .font(.custom("New York", size: 20))
                             .foregroundColor(.black)
                             .italic()
                             .padding(.top, 40)
                    } else if let error = pineconeVm.pineconeErrorFromEdit {
                        errorView(error.localizedDescription)
                        }
                }
                .searchable(text: $searchText)
                .padding(.top, 32)
                .padding(.horizontal, 42)
                .sheet(isPresented: $showEditSheet) {
                    if let vector = selectedVector {
                        EditInfoView(viewModel: EditInfoViewModel(vector: vector))
                    }
                }
            }
        }
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

            (
                Text("\"\(note)\"")
                    .font(.custom("New York", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                +
                Text("\n\n   (\(dateText))")
                    .font(.custom("New York", size: 14))
                    .italic()
                    .foregroundColor(.black.opacity(0.8))
                    
            )
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
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

//#Preview {
//    // Create lightweight actor stubs
//    let mockCK = CloudKitViewModel.shared // okay for preview if not used deeply
//    let mockPineconeActor = PineconeActor(cloudKitViewModel: mockCK)
//
//    // Mock PineconeViewModel with static data
//    class MockPineconeViewModel: PineconeViewModel {
//        override init(pineconeActor: PineconeActor, CKviewModel: CloudKitViewModel) {
//            super.init(pineconeActor: pineconeActor, CKviewModel: CKviewModel)
//            self.pineconeFetchedVectors = [
//                Vector(
//                    id: UUID().uuidString,
//                    metadata: [
//                        "description": "Meeting with Alice about the new design pitch.",
//                        "timestamp": ISO8601DateFormatter().string(from: Date())
//                    ]
//                ),
//                Vector(
//                    id: UUID().uuidString,
//                    metadata: [
//                        "description": "Dentist appointment on Monday morning.",
//                        "timestamp": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400))
//                    ]
//                )
//            ]
//        }
//    }
//
//    let pineconeVM = MockPineconeViewModel(pineconeActor: mockPineconeActor, CKviewModel: mockCK)
//    let networkManager = NetworkManager()
//
//    KVault()
//        .environmentObject(pineconeVM)
//        .environmentObject(networkManager)
//        .environmentObject(mockCK)
//}




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
