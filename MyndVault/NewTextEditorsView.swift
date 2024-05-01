//
//  NewTextEditorsView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 14.03.24.
//

import SwiftUI


//MARK: DEPRICATED
struct NewTextEditorsView: View {
    
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManger: PineconeManager
//    @Environment(\.modelContext) var modelContext
    
    @Binding var showtextEditorsAndButtonView: Bool
    @Binding  var showProgressView: Bool
    
    @State private var type: String = ""
    @State private var description: String = ""
    @State private var relevantFor: String = ""
    @State var selectedType: typeOptions
    
    var roundedRectRadius: CGFloat = 25
    @FocusState private var focusField: Field?
    
    private enum Field {
        case type
        case question
        case relevantFor
    }
    
    enum typeOptions: String, CaseIterable, Identifiable {
        case question = "Let me ask you something.."
        case addNew = "Remember this info.."
        case reminder = "Remind me.."
        var id: Self { self }
    }

    
    
    var body: some View {
        
            VStack {
                HStack {
                    Text("📝")
                    Spacer()
                    Picker("Type", selection: $selectedType) {
                        ForEach(typeOptions.allCases) { type in
                            Text(type.rawValue.capitalized)
                        }
                    }
                }
                .padding(.bottom)
                HStack {
                    Text(selectedType == .addNew ? "Add info" : "Your question").font(.caption).foregroundStyle(.gray.opacity(0.7))
                    Spacer()
                }
                TextField("", text: $type)
                    .padding(4)
                    .frame(minHeight: 40)
                    .foregroundColor(.black)
                    .background(Color.clear, ignoresSafeAreaEdges: .all)
                    .clipShape(RoundedRectangle(cornerRadius: roundedRectRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: roundedRectRadius)
                            .stroke(Color.green, lineWidth: 4)
                    )
                    .padding(.bottom)
                    .onAppear { focusField = .type }
                    .onSubmit { focusField = .question }
                    .focused($focusField, equals: .type)
                HStack {
                    Text("Question:").font(.caption).foregroundStyle(.gray.opacity(0.7))
                    Spacer()
                }
                TextEditor(text: $description)
                    .padding(4)
                    .frame(minHeight: 60)
                    .foregroundColor(.black)
                    .background(Color.clear, ignoresSafeAreaEdges: .all)
                    .clipShape(RoundedRectangle(cornerRadius: roundedRectRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: roundedRectRadius)
                            .stroke(Color.green, lineWidth: 4)
                    )
                    .onSubmit { focusField = .relevantFor }
                    .focused($focusField, equals: .question)
                    .padding(.bottom)
                HStack {
                    Text("Relevant For:").font(.caption).foregroundStyle(.gray.opacity(0.7))
                    Spacer()
                }
                TextEditor(text: $relevantFor)
                    .padding(4)
                    .frame(minHeight: 40)
                    .foregroundColor(.black)
                    .background(Color.clear, ignoresSafeAreaEdges: .all)
                    .clipShape(RoundedRectangle(cornerRadius: roundedRectRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: roundedRectRadius)
                            .stroke(Color.green, lineWidth: 4)
                    )
                    .focused($focusField, equals: .relevantFor)
                    .padding(.bottom)
                
            }.padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding()
                .onTapGesture {
                    hideKeyboard()
                }
              
            
            
//            Button(action: {
//                
//                Task {
//                    await openAiManager.updateMetadataResponse(type: type, description: description, relevantFor: relevantFor)
//                    withAnimation {
//                        showtextEditorsAndButtonView.toggle()
//                    }
//                    if let textToEmbeddings = openAiManager.gptMetadataResponseOnQuestion?.description {
//                        withAnimation {
//                            showProgressView = true
//                        }
//                        ProgressTracker.shared.setProgress(to: 0.05)
//                        
//                        await openAiManager.requestEmbeddings(for: textToEmbeddings, isQuestion: true)
//                        
//                        ProgressTracker.shared.setProgress(to: 0.2)
//                        
//                        if openAiManager.questionEmbeddingsCompleted {
//                            if let metadata = openAiManager.gptMetadataResponseOnQuestion?.toDictionary() {
//                                await pineconeManger.queryPinecone(vector: openAiManager.embeddingsFromQuestion, metadata: metadata)
//                                ProgressTracker.shared.setProgress(to: 0.4)
//                            }
//                        } else { print("AskView :: ELSE blocked from openAiManager.questionEmbeddingsCompleted ")}
//                        
//                        if let pineconeResponse = pineconeManger.pineconeQueryResponse, let question = openAiManager.gptMetadataResponseOnQuestion?.description {
//                            
//                            try await openAiManager.getGptResponseAndConvertTextToSpeech(queryMatches: pineconeResponse.getMatchesDescription(), question: question)
//                        } else {
//                            print("AskView :: ELSE blocked from getGptResponseAndConvertTextToSpeech()")
//                            print("\(String(describing: pineconeManger.pineconeQueryResponse))")
//                            print("\(String(describing: openAiManager.gptMetadataResponseOnQuestion?.description))")
//                        }
//                    } else { print("Ask View ELSE textToEmbeddings") }
//                    if let metadata = openAiManager.gptMetadataResponseOnQuestion, let fileUrl = metadata.fileUrl {
//                        let model = ResponseModel(timestamp: Date(), id: UUID(), type: metadata.type, desc: metadata.description, relevantFor: metadata.relevantFor, recordingPath: fileUrl)
//                        modelContext.insert(model)
//                        
//                    } else { print("ELSE on .insert: \(String(describing: openAiManager.gptMetadataResponseOnQuestion?.fileUrl))") }
//                    
//                }
//            }) {
//                Text("OK")
//                    .font(.headline)
//                    .fontDesign(.rounded)
//                    .foregroundColor(.white)
//                    .padding()
//                    .background(Color.blue)
//                    .cornerRadius(roundedRectRadius)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: roundedRectRadius)
//                            .stroke(Color.blue, lineWidth: 4)
//                    )
//            }
            .onAppear {
//                type = response.type
//                description = response.description
//                relevantFor = response.relevantFor
            }
            .sensoryFeedback(.start, trigger: showProgressView)
           
    }
}
    
    #Preview {
        NewTextEditorsView(showtextEditorsAndButtonView: .constant(true), showProgressView: .constant(false), selectedType: .addNew)
            .environmentObject(OpenAIManager())
           .environmentObject(PineconeManager())
    }
