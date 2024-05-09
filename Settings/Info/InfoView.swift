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
            }.font(.callout).padding(.top, 12).padding(.bottom, 8).padding(.horizontal, 7)
                
            HStack {
                TextEditor(text: $viewModel.description)
                    .fontDesign(.rounded)
                    .font(.title2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 110)
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
            }.padding(.bottom)
            .padding(.horizontal, 7)
            
            HStack {
                Image(systemName: "person.bubble").bold()
                Text("Relevant For:").bold()
                Spacer()
            }.font(.callout).padding(.horizontal, 7)
                .padding(.bottom, 8)
            
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
                .padding(.bottom)
                .padding(.horizontal, 7)
                .onSubmit {
                    focusField = nil
                }
                .focused($focusField, equals: .relevantFor)
           
            Button(action:  {
                DispatchQueue.main.async {
                    self.viewModel.activeAlert = .editConfirmation
                }
            }
) {
                ZStack {
                    RoundedRectangle(cornerRadius: rectCornerRad)
                        .fill(Color.customDarkBlue)
                        .shadow(radius: 7)
                        .frame(height: 60)
                        
                    Text("Save").font(.title2).bold().foregroundColor(.white)
                        .accessibilityLabel("save")
                }
                .contentShape(Rectangle())
                .shadow(radius: 7)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .padding(.horizontal)
            .animation(.easeInOut, value: keyboardResponder.currentHeight)
            .id("SubmitButton")
            .padding(.bottom, keyboardResponder.currentHeight > 0 ? 15 : 0)
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
                    self.viewModel.activeAlert = .deleteWarning
                   
                }, label: {
                    Circle()
                        .foregroundStyle(.white)
                        .frame(height: 30)
                        .shadow(radius: toolbarButtonShadow)
                        .overlay {
                            Text("🗑️")
                                .accessibilityLabel("Delete info")
                        }
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
