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
                            message: error.localizedDescription,
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
            "description": "Lunch with Leo next Friday. Lunch with Leo next Friday. Lunch with Leo next Friday.Lunch with Leo next Friday. Lunch with Leo next Friday. Lunch with Leo next Friday. Lunch with Leo next Friday .Lunch with Leo next Friday. Lunch with Leo next Friday. Lunch with Leo next Friday. Lunch with Leo next Friday .Lunch with Leo next Friday.",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
    )
    let cloudKit = CloudKitViewModel.shared

    let pineconeActor = PineconeActor(cloudKitViewModel: cloudKit)
    let openAIActor = OpenAIActor()

    let pineconeViewModel = PineconeViewModel(pineconeActor: pineconeActor, CKviewModel: cloudKit)
    
    let viewModel = KEditInfoViewModel(vector: vector)
    
    return KEditInfoView(
        viewModel: viewModel,
        onSave: {},
        onCancel: {}
    ).environmentObject(pineconeViewModel)
}
