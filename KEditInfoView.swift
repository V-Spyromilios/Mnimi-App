//
//  KEditInfoView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 25.04.25.
//

import SwiftUI

struct KEditInfoView: View {
    @EnvironmentObject var pineconeVm: PineconeViewModel
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @ObservedObject var viewModel: KEditInfoViewModel
    @State private var isReady: Bool = false
    var onSave: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Image("oldPaper")
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 1)
                    .opacity(0.8)
                    .ignoresSafeArea()
                
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.8), Color.clear]),
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Description
                        if isReady && !viewModel.description.isEmpty {
                            TextEditor(text: $viewModel.description)
                                .font(.custom("New York", size: 18))
                                .padding()
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .foregroundStyle(.black)
                                .frame(height: 100)
                                .lineSpacing(5)
                                .multilineTextAlignment(.leading)
                        }
                       else if let error = pineconeVm.pineconeErrorFromEdit {
                            KErrorView(
                                title: error.title,
                                message: error.localizedDescription,
                                retryAction: retrySaving
                            )
                            .transition(.scale.combined(with: .opacity))
                            .animation(.easeOut(duration: 0.2), value: pineconeVm.pineconeErrorFromEdit?.id)
                        }
                        
                        // Timestamp (non-editable)
                        Text(viewModel.timestamp)
                            .font(.custom("New York", size: 14))
                            .italic()
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .transition(.opacity)
                    .padding(.horizontal, 42)
                    .padding(.top, 24)
                    .kiokuShadow()
                    .frame(maxWidth: UIScreen.main.bounds.width)
                }.scrollIndicators(.hidden)
            }
            .onAppear {
                debugLog("onAppear: description is: \(viewModel.description)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isReady = true
                }
            }
//            .navigationTitle("Edit Info")
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: upsert)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", action: delete)
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                }
            }
            .ignoresSafeArea(.keyboard)
        }
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
            try await openAiManager.requestEmbeddings(for: metadata["description"] ?? "Default from upsertEditedInfo", isQuestion: false)
            if !openAiManager.embeddings.isEmpty {
                pineconeVm.upsertData(id: viewModel.id, vector: openAiManager.embeddings, metadata: metadata, from: .editInfo)
                
                //Update the local fetched vectors
                if let index = pineconeVm.pineconeFetchedVectors.firstIndex(where: { $0.id == viewModel.id }) {
                    withAnimation {
                        pineconeVm.pineconeFetchedVectors[index].metadata = metadata }
                }
                onSave()
            } else {
                debugLog("KEDitInfoView: No embeddings...")
            }
        } catch {
            debugLog(error.localizedDescription)
           
        }
    }
}

#Preview {
    let vector = Vector(
        id: UUID().uuidString,
        metadata: [
            "description": "Lunch with Leo next Friday.",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
    )
    
    let viewModel = KEditInfoViewModel(vector: vector)
    
    return KEditInfoView(
        viewModel: viewModel,
        onSave: {},
        onCancel: {}
    )
}
