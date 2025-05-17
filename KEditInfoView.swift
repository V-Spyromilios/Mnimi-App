//
//  KEditInfoView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 25.04.25.
//

import SwiftUI
import SwiftData

struct KEditInfoView: View {
    
    @EnvironmentObject var pineconeVm: PineconeViewModel
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @ObservedObject var viewModel: KEditInfoViewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var isReady: Bool = false
    var onSave: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Background
                KiokuBackgroundView()
                
                VStack(spacing: 20) {
                    // Description
                    if isReady && !viewModel.description.isEmpty {
                        TextEditor(text: $viewModel.description)
                            .font(.custom("New York", size: 18))
                            .padding(.leading)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .foregroundStyle(.black)
                            .lineSpacing(5)
                            .frame(width: UIScreen.main.bounds.width * 0.9, height: 140)
                            .multilineTextAlignment(.leading)
                            .kiokuShadow()
                            .animation(.easeOut(duration: 0.25), value: isReady)
                    }
                    else if let error = pineconeVm.pineconeErrorFromEdit {
                        KErrorView(
                            title: error.title,
                            message: error.message,
                            retryAction: retrySaving
                        )
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeOut(duration: 0.2), value: pineconeVm.pineconeErrorFromEdit?.id)
                        .kiokuShadow()
                    }
                    
                    // Timestamp (non-editable)
                    Text(viewModel.timestamp)
                        .font(.custom("New York", size: 14))
                        .italic()
                        .foregroundColor(.gray)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.6, alignment: .trailing)
                    Spacer()
                }
                .transition(.opacity)
                .padding(.top, 80)
                .frame(maxWidth: UIScreen.main.bounds.width)
                .ignoresSafeArea(.keyboard)
                
                VStack(spacing: 0) {
                    HStack {
                        Button("Cancel", action: onCancel)
                            .font(.custom("New York", size: 19))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button("Delete", action: delete)
                            .font(.custom("New York", size: 18))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        
                        Button("Save", action: upsert)
                            .font(.custom("New York", size: 18))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .edgesIgnoringSafeArea(.horizontal)
                }
            }
            .onAppear {
                debugLog("onAppear: description is: \(viewModel.description)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isReady = true
                }
            }
            
            .hideKeyboardOnTap()
        }  .ignoresSafeArea(.keyboard)
            .statusBarHidden()
        
    }
    
    private func delete() {
        Task {
            let success = await pineconeVm.deleteVectorFromPinecone(id: viewModel.id)
            
            if success {
                pineconeVm.deleteVector(withId: viewModel.id)
                await MainActor.run {
                    onSave()
                }
            } else {
                debugLog("Error deleting vector")
            }
        }
    }
    
    private func retrySaving() {
        pineconeVm.pineconeErrorFromEdit = nil
        Task {
            await upsertEditedInfo()
            
        }
    }
    
    private func upsert() {
        Task {
            await upsertEditedInfo()
        }
    }
    
    
    
    @MainActor
    private func upsertEditedInfo() async {
        
        let metadata = toDictionary(desc: viewModel.description)
        do {
            // 1.make embeddings and upsert to Pinecone
            try await openAiManager.requestEmbeddings(for: metadata["description"] ?? "Default from upsertEditedInfo", isQuestion: false)
            if !openAiManager.embeddings.isEmpty {
                let success = await pineconeVm.upsertData(id: viewModel.id, vector: openAiManager.embeddings, metadata: metadata, from: .editInfo)
                
                if success {
                    // 2. Update the local fetched vectors
                    if let index = pineconeVm.pineconeFetchedVectors.firstIndex(where: { $0.id == viewModel.id }) {
                        withAnimation {
                            pineconeVm.pineconeFetchedVectors[index].metadata = metadata }
                    }
                    
                    // 3. save to SwiftData
                    let targetID = viewModel.id
                    let fetch = FetchDescriptor<VectorEntity>(
                        predicate: #Predicate { $0.id == targetID }
                    )
                    if let entity = try? modelContext.fetch(fetch).first {
                        entity.descriptionText = metadata["description"] ?? ""
                        entity.timestamp = metadata["timestamp"] ?? ""
                    } else {
                        let new = VectorEntity(
                            id: viewModel.id,
                            descriptionText: metadata["description"] ?? "",
                            timestamp: metadata["timestamp"] ?? ""
                        )
                        modelContext.insert(new)
                    }
                    
                    // 4. Save SwiftData context
                    try await MainActor.run {
                        try modelContext.save()
                    }
                    onSave()
                }
            } else {
                debugLog("KEDitInfoView: upsertEditedInfo :: No embeddings...")
            }
        } catch {
            debugLog(error.localizedDescription)
            
        }
    }
}


#Preview {
    do {
        let vector = Vector(
            id: UUID().uuidString,
            metadata: [
                "description": "Lunch with Leo next Friday. Lunch with Leo next Friday. Lunch with Leo next Friday.",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        
        let container = try ModelContainer(for: VectorEntity.self)
        let context = ModelContext(container)
        
        let pineconeActor = PineconeActor()
        let pineconeViewModel = PineconeViewModel(pineconeActor: pineconeActor)
        pineconeViewModel.updateModelContext(to: context) // ⬅️ inject context
        
        let viewModel = KEditInfoViewModel(vector: vector)
        
        return KEditInfoView(
            viewModel: viewModel,
            onSave: {},
            onCancel: {}
        )
        .environmentObject(pineconeViewModel)
        .modelContainer(container)
        
    } catch {
        return Text("Preview failed: \(error.localizedDescription)")
    }
}
