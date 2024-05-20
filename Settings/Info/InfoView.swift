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
    @State private var animateStep: Int = 0
    @Binding var showPop: Bool
    @Binding var presentationMode: PresentationMode
    

    private enum Field {
        case edit
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
                    .frame(height: textEditorHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
                    .overlay{
                        RoundedRectangle(cornerRadius: 10.0)
                            .stroke(lineWidth: 1)
                            .opacity(0.3)
                            .foregroundColor(Color.gray)
                    }
                    .padding(.bottom)
//                    .onAppear { focusField = .edit }
                    .focused($focusField, equals: .edit)
            }.padding(.bottom)
            .padding(.horizontal, 7)
           
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
            .popover(isPresented: $showPop, attachmentAnchor: .point(.top), arrowEdge: .top) {
                
                popOverView(animateStep: $animateStep, show: $showPop)
                
                .onDisappear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        $presentationMode.wrappedValue.dismiss()
                        
                    }
                }.presentationCompactAdaptation(.popover)
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

//#Preview {
//    InfoView(viewModel: EditInfoViewModel(vector: Vector(id: "1234", metadata: ["Test":"test"])))
//        .environmentObject(OpenAIManager())
//        .environmentObject(PineconeManager())
//        .environmentObject(ProgressTracker())
//        .environmentObject(KeyboardResponder())
//}
