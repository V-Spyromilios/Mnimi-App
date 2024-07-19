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
    @Environment(\.colorScheme) var colorScheme
    @State var thrownError: String = ""
    @State var apiCallInProgress: Bool = false
    @State private var animateStep: Int = 0
    @State private var shake: Bool = false
    @State private var oldText: String = ""
    @Binding var showSuccess: Bool
    @Binding var inProgress: Bool

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
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.0)
                            .stroke(lineWidth: 1)
                            .opacity(colorScheme == .light ? 0.3 : 0.7)
                            .foregroundColor(Color.gray)
                    )
                    
                    .padding(.bottom)
//                    .onAppear { focusField = .edit }
                    .focused($focusField, equals: .edit)
            }
            .padding(.bottom)
            .padding(.horizontal, 7)
           
            Button(action:  {

                if shake { return }
                
                //TODO: if no change to the text -> Shake
                if viewModel.description.isEmpty || (oldText == viewModel.description) {
                    withAnimation { shake = true }
                    return
                }
                DispatchQueue.main.async {
                    withAnimation {
                        hideKeyboard()
                        self.viewModel.activeAlert = .editConfirmation }
                }
            }
) {
                ZStack {
                    RoundedRectangle(cornerRadius: rectCornerRad)
                        .fill(Color.primaryAccent)
                        .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                        .frame(height: buttonHeight)
                        
                    Text("Save").font(.title2).bold()
                        .foregroundColor(Color.buttonText)
                        .accessibilityLabel("save")
                }
                .contentShape(Rectangle())
               
            }
            .frame(maxWidth: .infinity)
            .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
            .padding(.top, 12)
            .padding(.horizontal)
            .animation(.easeInOut, value: keyboardResponder.currentHeight)
            .id("SubmitButton")
            .padding(.bottom, keyboardResponder.currentHeight > 0 ? 15 : 0)

            if inProgress {
                LottieRepresentable(filename: "Brain Configurations", loopMode: .loop, speed: 0.8).frame(width: 220, height: 220).id(UUID()).animation(.easeInOut, value: inProgress)
            }
            
            else if showSuccess {
                LottieRepresentable(filename: "Approved", loopMode: .playOnce).frame(height: 130).padding(.top, 15).id(UUID()).animation(.easeInOut, value: showSuccess)
            }
            Spacer()
        }.background { Color.primaryBackground.ignoresSafeArea() }
        .toolbar {

            ToolbarItemGroup(placement: .topBarTrailing) {
                
                if keyboardResponder.currentHeight > 0 {
                    Button {
                        hideKeyboard()
                    } label: {
                        HideKeyboardLabel()
                            }
                    }
                
                Button(action: {
                    self.viewModel.activeAlert = .deleteWarning
                   
                }, label: {
                    Circle()
                        .foregroundStyle(Color.gray.opacity(0.6))
                        .frame(height: 30)
                        .shadow(color: Color.customShadow, radius: toolbarButtonShadow)
                        .overlay {
                            Text("🗑️")
                                .accessibilityLabel("Delete info")
                        }
                })
            }
        }
        .onChange(of: shake) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shake = false
                }
            }
        }
        .onAppear {
            oldText = viewModel.description
        }
        
    }
}
