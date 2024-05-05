//
//  InfoView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 12.04.24.
//

import SwiftUI

struct InfoView: View {
    
    @ObservedObject var viewModel: EditInfoViewModel
    
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @FocusState private var focusField: Field?
    @State var thrownError: String = ""
    @State var apiCallInProgress: Bool = false
    

    private enum Field {
        case edit
        case relevantFor
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "rectangle.and.pencil.and.ellipsis").bold()
                Text("Edit Info:").bold()
                Spacer() //or .frame(alignment:) in the hstack
            }.font(.callout)
                .padding(.bottom, 12).padding(.top, 12)
            HStack {
                TextEditor(text: $viewModel.description)
                    .fontDesign(.rounded)
                    .font(.title2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
                    .overlay{
                        RoundedRectangle(cornerRadius: 10.0)
                            .stroke(lineWidth: 1)
                            .opacity(0.3)
                            .foregroundColor(Color.gray)
                    }
                    .padding(.bottom)
                    .onAppear { focusField = .edit }
                    .onSubmit { focusField = .relevantFor }
                    .focused($focusField, equals: .edit)
            }
            HStack {
                Image(systemName: "person.bubble").bold()
                Text("Relevant For:").bold()
                Spacer()
            }.font(.callout)
                .padding(.bottom, 12)
            
            TextEditor(text: $viewModel.relevantFor)
                .fontDesign(.rounded)
                .font(.title2)
                .multilineTextAlignment(.leading)
                .frame(height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 5)
                .overlay{
                    RoundedRectangle(cornerRadius: 10.0)
                        .stroke(lineWidth: 1)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                }
                .padding(.bottom, 50)
                .onSubmit {
                    focusField = nil
                }
                .focused($focusField, equals: .relevantFor)
           
            HStack {
                Button(action: {
                    hideKeyboard()
                    DispatchQueue.main.async {
                        viewModel.showEditConfirmation = true
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: rectCornerRad)
                            .fill(Color.customDarkBlue)
                            .frame(height: 60)
                            .shadow(radius: 7)
                        Text("Save").font(.title2).bold().foregroundColor(.white)
                    } .shadow(radius: 7)
                }.frame(maxWidth: .infinity)
                    .padding(.bottom, keyboardResponder.currentHeight > 0 ? 25: 0)
            }
            Spacer()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button {
                        hideKeyboard()
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                
                Button(action: {
                    viewModel.showDeleteWarning = true
                   
                }, label: {
                    Image(systemName: "trash").foregroundStyle(.red)
                        .imageScale(.large)
                        .accessibilityLabel("Delete info")
                })
            }
        }
        
    }
}

#Preview {
    InfoView(viewModel: EditInfoViewModel(vector: Vector(id: "1234", metadata: ["Test":"test"])))
        .environmentObject(OpenAIManager())
        .environmentObject(PineconeManager())
        .environmentObject(ProgressTracker())
        .environmentObject(KeyboardResponder())
}
