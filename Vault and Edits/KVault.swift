//
//  KVault.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 23.04.25.
//
import SwiftData
import SwiftUI
import WidgetKit

struct KVault: View {

    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var pineconeVm: PineconeViewModel
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @EnvironmentObject var usageManager: ApiCallUsageManager
    
    @Environment(\.modelContext) private var ctx
    
    @State private var showEmpty: Bool = false
    @State private var showNoInternet = false
    @State private var searchText: String = ""
    
    @State private var selectedVector: Vector? = nil
    @State private var inputedDescription: String = ""
    
    @StateObject var editViewModel = KEditInfoViewModel.empty
    @State private var isEditing = false
    
    @Query(sort: \VectorEntity.timestamp, order: .reverse)
    private var entities: [VectorEntity] {
        didSet {              // ← prints every time the query updates
               debugLog("KVault now sees \(entities.count) entities")
           }
    }

    
//    var filteredVectors: [Vector] {
//        if searchText.isEmpty {
//            return pineconeVm.pineconeFetchedVectors
//        } else {
//            return pineconeVm.pineconeFetchedVectors.filter { vector in
//                if let description = vector.metadata["description"] {
//                    return description.lowercased().contains(searchText.lowercased())
//                }
//                return false
//            }
//        }
//    }
    
    var body: some View {
        
        ZStack {
            KiokuBackgroundView()
            contentView

                .padding(.horizontal)

            if showNoInternet {
                Color.black.opacity(0.4).ignoresSafeArea()
                
                KAlertView(
                    title: "You are not connected to the Internet",
                    message: "Please check your connection",
                    dismissAction: {
                        withAnimation {
                            showNoInternet = false
                        }
                    }
                )
                .transition(.scale)
                .zIndex(1)
                
            }
        }
        .frame(width: UIScreen.main.bounds.width)
        .animation(.easeOut(duration: 0.2), value: showNoInternet)
        .onChange(of: networkManager.hasInternet) { _, hasInternet in
            if !hasInternet {
                withAnimation {
                    showNoInternet = true
                }
            }
        }
        .onChange(of: entities) { _, newEntities in
            updateRecentNotesSharedDefaults(from: newEntities)
        }
        .ignoresSafeArea(.keyboard, edges: .all)
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
    
    private func closeSheet() {
        selectedVector = nil
        
    }
    
    private func updateRecentNotesSharedDefaults(from entities: [VectorEntity]) {
        let notes = entities
            .prefix(5)
            .map { $0.descriptionText }
        UserDefaults(suiteName: "group.app.mnimi.shared")?
            .set(notes, forKey: "recent_notes")
        
        WidgetCenter.shared.reloadTimelines(ofKind: "RecentNotesWidget") // refresh homescreen widget
    }
    
    private var backgroundView: some View {
        ZStack {
            KiokuBackgroundView()

        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
               
                if !allVectors.isEmpty && pineconeVm.pineconeErrorFromEdit == nil {
                    KSearchBar(text: $searchText)
                        .frame(maxWidth: 380)
                    ForEach(Array(filteredVectors.enumerated()), id: \.element.id) { _, data in
                        Button {
                            editViewModel.update(with: data)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                isEditing = true }
                        } label: {
                            VaultCellView(data: data)
                        }
                        .buttonStyle(.plain)
                    }
                } else if allVectors.isEmpty && pineconeVm.pineconeErrorFromEdit == nil && pineconeVm.pineconeErrorFromRefreshNamespace == nil {
                    emptyView()
                }
                if let error = pineconeVm.pineconeErrorFromRefreshNamespace {
                    KErrorView(
                        title: error.title,
                        message: error.message, ButtonText: "Retry",
                        retryAction: retryLoading
                    )
                    .transition(.opacity.combined(with: .scale))
                    .animation(.easeOut(duration: 0.2), value: error.message)
                }
            }
            .padding(.top, 32)
            .transition(.opacity)
            .animation(.easeOut(duration: 0.25), value: entities.count)
            
        }.scrollIndicators(.hidden)
            .frame(maxWidth: UIScreen.main.bounds.width)
            .clipped()
            .contentShape(Rectangle())
            .sheet(isPresented: $isEditing) {
                KEditInfoView(
                    viewModel: editViewModel,
                    onSave: {
                        isEditing = false
                    },
                    onCancel: {
                        isEditing = false
                    }
                ) .id(editViewModel.id)
            }
            .onChange(of: isEditing) { _, newValue in
                if newValue == false {
                    // Sheet was dismissed manually or programmatically
                    editViewModel.update(with: .empty)
                }
            }
    }
    
    private func retryLoading() {
        pineconeVm.pineconeErrorFromEdit = nil
        pineconeVm.pineconeErrorFromRefreshNamespace = nil
        pineconeVm.refreshNamespacesIDs()
    }
}

// MARK: helpers
private extension KVault {
    
    var allVectors: [Vector] { entities.map(\.toVector) }
    
//    var allVectorsCounter: Int { allVectors.count }
    
    // old `filteredVectors`, rewritten to use `allVectors`
    var filteredVectors: [Vector] {
        guard !searchText.isEmpty else { return allVectors }
        return allVectors.filter {
            $0.metadata["description"]?
                .localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

}

private func loadingView() -> some View {
    Text("Loading...")
        .font(.custom("New York", size: 20))
        .foregroundColor(.black)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 40)
        .padding(.horizontal, 24)
}

private func emptyView() -> some View {
    Text("Saved information will appear here.")
        .font(.custom("New York", size: 20))
        .foregroundColor(.black)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 42)
        .padding(.horizontal, 24)
}


struct VaultCellView: View {
    let data: Vector
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            let note = data.metadata["description"] ?? "Empty note."
            let dateText = dateFromISO8601(isoDate: data.metadata["timestamp"] ?? "").map { formatDateForDisplay(date: $0) } ?? ""
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\"\(note)\"")
                    .font(.custom("New York", size: 18))
                    .fontWeight(.semibold)
                    .lineSpacing(5)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.black)
                
                Text("(\(dateText))")
                    .font(.custom("New York", size: 14))
                    .italic()
                    .foregroundColor(.black.opacity(0.8))
            }
            .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        .drawingGroup()
    }
}

extension Vector {
    static var empty: Vector {
        Vector(id: UUID().uuidString, metadata: [:])
    }
}

struct KSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text("Search saved info...")
                        .font(.custom(NewYorkFont.italic.rawValue, size: 15))
                        .foregroundColor(.gray)
                        .padding(.leading, 5)
                }

                TextField("", text: $text)
                    .font(.custom(NewYorkFont.italic.rawValue, size: 15))
                    .foregroundColor(.black)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .background(Color.clear)
                    .submitLabel(.done)
            }
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }.ignoresSafeArea(.keyboard, edges: .all)
        .padding(12)
        .onTapGesture {
            withAnimation {
                isFocused.toggle()
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: VectorEntity.self)
        let context = ModelContext(container)

        let pineconeActor = PineconeActor()
        let pineconeViewModel = PineconeViewModel(pineconeActor: pineconeActor)
        let networkManager = NetworkManager()

        return KVault()
            .environmentObject(pineconeViewModel)
            .environmentObject(networkManager)
            .modelContainer(container)
    } catch {
        return Text("Failed to initialize preview: \(error.localizedDescription)")
    }
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


// Preview for the KAlert
//
//struct KAlertView_Previews: PreviewProvider {
//    static var previews: some View {
//        VStack{
//            KAlertView(
//                title: "You are not connected to the Internet",
//                message: "Please check your connection",
//                dismissAction: {}
//            )
//        }
//        .previewDisplayName("Kioku Alert Preview")
//        .kiokuBackground().ignoresSafeArea()
//    }
//}
