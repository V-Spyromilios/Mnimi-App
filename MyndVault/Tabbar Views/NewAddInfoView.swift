//
//  NewAddInfoView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 30.04.24.
//

import SwiftUI
import CloudKit

struct NewAddInfoView: View {
    @State private var newInfo: String = ""
    @State private var apiCallInProgress: Bool = false
    @State private var thrownError: String = ""
    
    @State private var clearButtonIsVisible: Bool = false
    @State private var saveButtonIsVisible: Bool = true
    @State private var showSettings: Bool = false
    
    @State private var isLoading: Bool = false //used just for the button
    @State private var shake: Bool = false
    @State private var showNoInternet: Bool = false
    
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var cloudKit: CloudKitViewModel
    @StateObject private var photoPicker = ImagePickerViewModel()
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var networkManager: NetworkManager
    
    var body: some View {
        
        GeometryReader { geometry in
            NavigationStack {
                ScrollView {
                    
                    VStack {
                        
                        HStack {
                            Image(systemName: "plus.bubble").bold()
                            Text("info").bold()
                            Spacer()
                        }.font(.callout).padding(.top,12).padding(.bottom, 8).padding(.horizontal, standardCardPadding)
                        
                        HStack {
                            TextEditor(text: $newInfo)
                                .fontDesign(.rounded)
                                .font(.title2)
                                .multilineTextAlignment(.leading)
                                .frame(height: textEditorHeight)
                                .frame(maxWidth: idealWidth(for: geometry.size.width))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10.0)
                                        .stroke(lineWidth: 1)
                                        .opacity(colorScheme == .light ? 0.3 : 0.7)
                                        .foregroundColor(Color.gray)
                                )
                                .padding(.bottom)
                            
                        }
                        Button(action: {
                            photoPicker.presentPicker()
                        }) {
                            HStack {
                                Text(photoPicker.selectedImage == nil ? "Add photo" : "Change photo")
                                Spacer()
                                if let image = photoPicker.selectedImage {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 160)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                                            .overlay(alignment: .center) {
                                                RoundedRectangle(cornerRadius: 10.0)
                                                    .stroke(lineWidth: 1)
                                                    .opacity(colorScheme == .light ? 0.3 : 0.7)
                                                    .foregroundColor(Color.gray)
                                            }
                                        Button(action: {
                                            withAnimation {
                                                photoPicker.selectedImage = nil
                                            }
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
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding()
                        .frame(maxWidth: idealWidth(for: geometry.size.width))
                        .background(colorScheme == .light ? Color.cardBackground : Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10.0)
                                .stroke(lineWidth: 1)
                                .opacity(colorScheme == .light ? 0.3 : 0.7)
                                .foregroundColor(Color.gray)
                        )
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
                                    LottieRepresentable(filename: "Vertical Dot Menu", loopMode: .playOnce, speed: 0.5)
                                        .frame(width: 45, height: 45)
                                        .padding(.bottom, 5)
                                        .shadow(color: colorScheme == .dark ? .gray : .clear, radius: colorScheme == .dark ? 4 : 0)
                                        .opacity(0.8)
                                    .accessibilityLabel("Settings") }
                            }
                            
                        }
                    }
                    .sheet(isPresented: $photoPicker.isPickerPresented) {
                        PHPickerViewControllerRepresentable(viewModel: photoPicker)
                    }
                    
                    if self.thrownError != "" {
                        //                        ErrorView(thrownError: thrownError)
                        //                            .padding(.top)
                        //                            .padding(.horizontal)
                        ClearButton
                            .offset(y: keyboardResponder.currentHeight > 0 ? 70: 0 )
                    }
                    //                    else if pineconeManager.receivedError != nil {
                    ////                        ErrorView(thrownError: thrownError)
                    ////                            .padding(.top)
                    ////                            .padding(.horizontal)
                    //                        ClearButton
                    //                            .offset(y: keyboardResponder.currentHeight > 0 ? 70: 0 )
                    //                    }
                    //                    else if openAiManager.thrownError != "" {
                    ////                        ErrorView(thrownError: thrownError)
                    ////                            .padding(.top)
                    ////                            .padding(.horizontal)
                    //                        ClearButton
                    //                            .offset(y: keyboardResponder.currentHeight > 0 ? 70: 0 )
                    //                    }
                    else if saveButtonIsVisible && pineconeManager.receivedError == nil {
                        SaveButton
                        
                    }
                    if apiCallInProgress && progressTracker.progress < 0.99 && thrownError == "" && pineconeManager.receivedError == nil {
                        CircularProgressView(progressTracker: progressTracker).padding()
                        LottieRepresentable(filename: "Brain Configurations", loopMode: .loop, speed: 0.8).frame(width: 220, height: 220).id(UUID())
                    }
                    Spacer()
                    
                }.padding(.horizontal, standardCardPadding) //TODO: No padding !?!
                    .background {
                        LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: backgroundSpeed, contentMode: .scaleAspectFill)
                            .opacity(0.4)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .ignoresSafeArea()
                    }
                    .navigationBarTitleView {
                        HStack {
                            Text("Add New Info").font(.title2).bold().foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded).padding(.trailing, 6)
                            LottieRepresentableNavigation(filename: "UploadingFile").frame(width: 45, height: 50).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0) } //TODO: Check how it looks
                    }
            }
            
            .onChange(of: shake) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            shake = false }
                    }
                }
            }
            //            .onChange(of: openAiManager.thrownError) { _, errorMessage in
            ////                if errorMessage != "" {
            //                withAnimation {
            //                    self.thrownError = errorMessage }
            ////                }
            //            }
            .onChange(of: networkManager.hasInternet) { _, hasInternet in
                if !hasInternet {
                    showNoInternet = true
                }
            }
            .alert(isPresented: $showNoInternet) {
                Alert(
                    title: Text("You are not connected to the Internet"),
                    message: Text("Please check your connection"),
                    dismissButton: .cancel(Text("OK"))
                )
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(showSettings: $showSettings)
        }
        .onDisappear {
            if thrownError != "" || pineconeManager.receivedError != nil {
                performClearTask()
            }
        }
    }
    private var SaveButton: some View {
        Button(action: addNewInfoAction) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(Color.primaryAccent)
                    .frame(height: buttonHeight)
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                Text("Save").font(.title2).bold().foregroundColor(Color.buttonText)
                    .accessibilityLabel("save")
            }
            .contentShape(Rectangle())
            
        }
        .frame(maxWidth: .infinity)
        .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
        .padding(.top, 12)
        .padding(.horizontal)
        .animation(.easeInOut, value: keyboardResponder.currentHeight)
    }
    
    private var ClearButton: some View {
        Button(action: performClearTask) {
            ZStack {
                RoundedRectangle(cornerRadius: rectCornerRad)
                    .fill(Color.primaryAccent)
                    .frame(height: buttonHeight)
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                
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
                await pineconeManager.clearManager()
            }
            self.apiCallInProgress = false
            self.saveButtonIsVisible = true
        }
    }
    
    private func addNewInfoAction() {
        
        if shake || isLoading { return }
        if newInfo.count < 5 {
            withAnimation { shake = true }
            return
        }
        
        isLoading = true
        hideKeyboard()
        self.saveButtonIsVisible = false
        self.apiCallInProgress = true
        progressTracker.reset()
        Task { await addInfoOperations() }
    }
    
    private func addInfoOperations() async {
        
        do {
            //MARK: TEST THROW
            //                let miaMalakia = AppCKError.UnableToGetNameSpace
            //                throw miaMalakia
            
            try await openAiManager.requestEmbeddings(for: self.newInfo, isQuestion: false)
            
            if openAiManager.embeddingsCompleted {
                let metadata = toDictionary(desc: self.newInfo)
                
                let uniqueID = UUID().uuidString
                
                try await pineconeManager.upsertDataToPinecone(id: uniqueID, vector: openAiManager.embeddings, metadata: metadata)
                if pineconeManager.upsertSuccesful {
                    if let image = photoPicker.selectedImage {
                        try await cloudKit.saveImageItem(image: image, uniqueID: uniqueID)
                    }
                }
                await MainActor.run {
                    apiCallInProgress = false
                    saveButtonIsVisible = true
                    isLoading = false
                }
            }
        }
        catch let error as AppNetworkError {
            await MainActor.run {
                apiCallInProgress = false
                isLoading = false
                self.thrownError = error.errorDescription }
        }
        catch let error as AppCKError {
            await MainActor.run {
                apiCallInProgress = false
                isLoading = false
                self.thrownError = error.errorDescription }
        }
        catch let error as CKError {
            await MainActor.run {
                apiCallInProgress = false
                isLoading = false
                self.thrownError = error.customErrorDescription }
        }
        catch {
            await MainActor.run {
                apiCallInProgress = false
                isLoading = false
                self.thrownError = error.localizedDescription }
        }
        
    }
}


struct NewAddInfoView_Previews: PreviewProvider {
    static var previews: some View {
        let responder = KeyboardResponder()
        let progress = ProgressTracker()
        let openAI = OpenAIManager()
        let pinecone = PineconeManager()
        NewAddInfoView()
        .environmentObject(pinecone)
        .environmentObject(openAI)
        .environmentObject(progress)
        .environmentObject(responder)
    }
}
