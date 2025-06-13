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
    @EnvironmentObject var usageManager: ApiCallUsageManager
    @ObservedObject var viewModel: KEditInfoViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showPaywall: Bool = false
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
                            message: error.message, ButtonText: "Retry",
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
                        
                        #if DEBUG
                        Spacer()
                        
                        
                        Button("Paywall", action: showDebugPaywall)
                            .font(.custom("New York", size: 18))
                            .foregroundColor(.black)
                        #endif
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
            .fullScreenCover(isPresented: $showPaywall) {
                CustomPaywallView(onCancel: {} )
            }
            
            .hideKeyboardOnTap()
        }  .ignoresSafeArea(.keyboard)
            .statusBarHidden()
        
    }
    @MainActor
    private func showDebugPaywall() {
        showPaywall = true
    }
    
    @MainActor
    private func delete() {
        Task {
            guard await pineconeVm.deleteVectorFromPinecone(id: viewModel.id) else {
                debugLog("Delete failed on Pinecone")
                return
            }

            // ───────── SwiftData delete ─────────
            let targetID = viewModel.id         // ← plain String value

            let fetch = FetchDescriptor<VectorEntity>(
                predicate: #Predicate<VectorEntity> { entity in
                    entity.id == targetID       // key-path == value
                }
            )

            if let entity = try? modelContext.fetch(fetch).first {
                modelContext.delete(entity)
                try? modelContext.save()
            }

            onSave()    // close sheet / refresh UI
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
       
#if !DEBUG
            if !usageManager.canMakeApiCall() {
                showPaywall = true
                return
            }
#endif
        
        // 1. Prepare metadata
        let cleanText = clean(text: viewModel.description)
        let metadata = toDictionary(desc: cleanText)
        let targetID = viewModel.id

        // 2. Upsert to Pinecone
        do {
            try await openAiManager.requestEmbeddings(
                for: metadata["description"] ?? "Default",
                isQuestion: false
            )

            guard !openAiManager.embeddings.isEmpty else {
                debugLog("upsertEditedInfo: No embeddings")
                return
            }
            guard await pineconeVm.upsertData(
                id: targetID,
                vector: openAiManager.embeddings,
                metadata: metadata,
                from: .editInfo
            ) else { return }

            // 3. Upsert locally (SwiftData)
            let fetch = FetchDescriptor<VectorEntity>(
                predicate: #Predicate { $0.id == targetID }
            )
            if let entity = try modelContext.fetch(fetch).first {
                entity.descriptionText = metadata["description"] ?? ""
                entity.timestamp       = metadata["timestamp"] ?? ""
            } else {
                let newEntity = VectorEntity(
                    id: targetID,
                    descriptionText: metadata["description"] ?? "",
                    timestamp: metadata["timestamp"] ?? ""
                )
                modelContext.insert(newEntity)
            }

            try modelContext.save()     // 4. Commit once
            onSave()                    // 5. Dismiss sheet
            usageManager.trackApiCall()
        } catch {
            debugLog("Edit-upsert failed: \(error.localizedDescription)")
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
