//
//  NewAddInfoView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 30.04.24.
//

import SwiftUI

struct NewAddInfoView: View {
    @Binding var newInfo: String
    @Binding var apiCallInProgress: Bool
    
    @State var thrownError: String = ""
    @Binding var showAlert: Bool
    
    @State private var showPopUp: Bool = false
    @State private var popUpMessage: String = ""
    
    @State private var clearButtonIsVisible: Bool = false
    @State private var saveButtonIsVisible: Bool = true
    @State private var showSettings: Bool = false
    
    @State private var animateStep: Int = 0
    
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var cloudKit: CloudKitViewModel
    @StateObject private var photoPicker = ImagePickerViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        GeometryReader { geometry in
            NavigationStack {
                ScrollView {
                
                //                    ScrollView {
                VStack {
                    
                    HStack {
                        Image(systemName: "plus.bubble").bold()
                        Text("info").bold()
                        Spacer()
                    }.font(.callout).padding(.top,12).padding(.bottom, 8).padding(.horizontal, 7)
                    
                    HStack {
                        TextEditor(text: $newInfo)
                            .fontDesign(.rounded)
                            .font(.title2)
                            .multilineTextAlignment(.leading)
                            .frame(height: textEditorHeight)
                            .frame(maxWidth: idealWidth(for: geometry.size.width))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: colorScheme == .light ? 2: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10.0)
                                    .stroke(lineWidth: 1)
                                    .opacity(colorScheme == .light ? 0.3 : 0.7)
                                    .foregroundColor(Color.gray)
                            )
                            .padding(.bottom)
                            .padding(.horizontal, 7)
                    }
                    HStack {
                        
                        Button(action: {
                            photoPicker.presentPicker()
                        }) {
                            Text(photoPicker.selectedImage == nil ? "Add photo" : "Change photo")
                        }
                        
                        
                        //                        .padding()
                        Spacer()
                        if let image = photoPicker.selectedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10.0)
                                            .stroke(lineWidth: 1)
                                            .opacity(colorScheme == .light ? 0.3 : 0.7)
                                            .foregroundColor(Color.gray)
                                    )
                                Button(action: {
                                    withAnimation {
                                        photoPicker.selectedImage = nil }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .offset(x: 5, y: -5)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: idealWidth(for: geometry.size.width))
                    .background(colorScheme == .light ? Color.cardBackground : Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: colorScheme == .light ? 2: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.0)
                            .stroke(lineWidth: 1)
                            .opacity(colorScheme == .light ? 0.3 : 0.7)
                            .foregroundColor(Color.gray)
                    )
                    .padding(.horizontal, 7)
                    .padding(.bottom)
                    
                    .toolbar {
                        
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            if keyboardResponder.currentHeight > 0 {
                                Button {
                                    hideKeyboard()
                                } label: {
                                    HideKeyboardLabel()
                                }
                            }
                            Button {
                                showSettings.toggle()
                            } label: {
                                Circle()
                                    .foregroundStyle(Color.buttonText)
                                    .frame(height: 30)
                                    .shadow(color: Color.customShadow, radius: toolbarButtonShadow)
                                    .overlay {
                                        Text("⚙️")
                                        .accessibilityLabel("Settings") }
                            }
                            
                        }
                    }.popover(isPresented: $showPopUp, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
                        
                        popOverView(animateStep: $animateStep, show: $showPopUp)
                            .presentationCompactAdaptation(.popover)
                        
                    }
                    .sheet(isPresented: $photoPicker.isPickerPresented) {
                        PHPickerViewControllerRepresentable(viewModel: photoPicker)
                    }
                    
                    //MARK: Calls the addNewInfoAction. keeps track of apiCallInProgress
                    
                    
                    if self.thrownError != "" {
                        ErrorView(thrownError: thrownError)
                            .padding(.top)
                            .padding(.horizontal)
                        ClearButton
                            .offset(y: keyboardResponder.currentHeight > 0 ? 70: 0 )
                    }
                    else if pineconeManager.receivedError != nil {
                        ErrorView(thrownError: pineconeManager.receivedError.debugDescription.description)
                            .padding(.top)
                            .padding(.horizontal)
                        ClearButton
                            .offset(y: keyboardResponder.currentHeight > 0 ? 70: 0 )
                    }
                    else if openAiManager.thrownError != "" {
                        ErrorView(thrownError: openAiManager.thrownError)
                            .padding(.top)
                            .padding(.horizontal)
                        ClearButton
                            .offset(y: keyboardResponder.currentHeight > 0 ? 70: 0 )
                    }
                    else if saveButtonIsVisible && openAiManager.thrownError == "" && pineconeManager.receivedError == nil {
                        SaveButton
                        
                    }
                    if apiCallInProgress && progressTracker.progress < 0.99 && thrownError == "" && openAiManager.thrownError == "" && pineconeManager.receivedError == nil {
                        CircularProgressView(progressTracker: progressTracker).padding()
                    }
                    Spacer()
                        .navigationTitle("Add New 📝")
                        .navigationBarTitleDisplayMode(.large)
                }
            }.background {
                Color.primaryBackground.ignoresSafeArea()
            }
            }
        
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(showSettings: $showSettings)
        }
    }
    
    private var SaveButton: some View {
        Button(action: addNewInfoAction) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(Color.primaryAccent)
                    .frame(height: 60)
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 2)
                Text("Save").font(.title2).bold().foregroundColor(Color.buttonText)
                    .accessibilityLabel("save")
            }
            .contentShape(Rectangle())
           
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.horizontal)
        .animation(.easeInOut, value: keyboardResponder.currentHeight)
    }
    
    private var ClearButton: some View {
        Button(action: performClearTask) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(Color.primaryAccent)
                    .frame(height: 60)
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 2)
                
                Text("OK").font(.title2).bold().foregroundColor(Color.buttonText)
                    .accessibilityLabel("clear")
            }
            .contentShape(Rectangle())
        }
        .padding(.top, 12)
        .padding(.horizontal)
        .animation(.easeInOut, value: keyboardResponder.currentHeight)
        .frame(maxWidth: .infinity)
    }
    
    private func performClearTask() {
        
        withAnimation {
            progressTracker.reset()
            self.thrownError = ""
            self.clearButtonIsVisible = false
            Task {
                await openAiManager.clearManager()
                pineconeManager.clearManager()
            }
            self.apiCallInProgress = false
            self.saveButtonIsVisible = true
        }
    }
    
    private func addNewInfoAction() {
        
        if newInfo.count < 5 { return }
        
        hideKeyboard()
        self.saveButtonIsVisible = false
        self.apiCallInProgress = true
        progressTracker.reset()
        Task { await addInfoOperations() }
    }
    
    private func addInfoOperations() async {
        
        await openAiManager.requestEmbeddings(for: self.newInfo, isQuestion: false)
        
        if openAiManager.embeddingsCompleted {
            let metadata = toDictionary(desc: self.newInfo)
            do {
                //MARK: TEST THROW
                //                                let miaMalakia = AppCKError.UnableToGetNameSpace
                //                                throw miaMalakia
                let uniqueID = UUID().uuidString
                
                try await pineconeManager.upsertDataToPinecone(id: uniqueID, vector: openAiManager.embeddings, metadata: metadata)
                if pineconeManager.upsertSuccesful {
                    if let image = photoPicker.selectedImage {
                        try await cloudKit.saveImageItem(image: image, uniqueID: uniqueID)
                    }
                    await MainActor.run {
                        self.popUpMessage = "Info saved."
                        self.showPopUp = true
                        self.newInfo = ""
                    }
                }
            } catch(let error) {
                await MainActor.run {
                    //TODO: test if only one button appears after Error:
                    self.apiCallInProgress = false
                    self.thrownError = error.localizedDescription
                    self.showAlert = true
                    
                    print("Error while upserting catched by the View: \(error.localizedDescription)")
                }
            }
        } else { print("AddNewView :: ELSE blocked from openAiManager.EmbeddingsCompleted ") }
        
        await MainActor.run {
            self.apiCallInProgress = false
            //self.newInfo = ""
            self.saveButtonIsVisible = true
        }
    }
}

struct NewAddInfoView_Previews: PreviewProvider {
    static var previews: some View {
        let responder = KeyboardResponder()
        let progress = ProgressTracker()
        let openAI = OpenAIManager()
        let pinecone = PineconeManager()
        NewAddInfoView(newInfo: .constant("Test string"),
                       apiCallInProgress: .constant(false),
                       showAlert: .constant(false))
        .environmentObject(pinecone)
        .environmentObject(openAI)
        .environmentObject(progress)
        .environmentObject(responder)
    }
}
