//
//  InitialSetupView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 18.05.24.
//

import SwiftUI
import LocalAuthentication

struct InitialSetupView: View {
    @EnvironmentObject var cloudKitViewModel: CloudKitViewModel
    @EnvironmentObject var language: LanguageSettings
    @EnvironmentObject var speechManager: SpeechRecognizerManager
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @EnvironmentObject var pinecone: PineconeViewModel
    
    @Environment(\.colorScheme) var colorScheme
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var setupComplete = false
    @State private var isEditingUsername: Bool = false
    @State private var isEditingPassword: Bool = false
    @State private var isEditingPasswordRepait: Bool = false
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var authManager: AuthenticationManager
    
    @FocusState private var isUsernameFieldFocused: Bool
    @FocusState private var isPasswordFieldFocused: Bool
    @FocusState private var isRepairPasswordFieldFocused: Bool
    
    var body: some View {
        
        GeometryReader { geometry in
            
            ZStack {
                LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                    .opacity(0.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                
                VStack {
                    ScrollView {
                        
                        LottieRepresentable(filename: "Woman_vault")
                            .frame(height: 220)
                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                        TypingTextView(fullText: "Please provide Username\nand Password to be used if FaceID is not available.", isTitle: false)
                            .shadow(radius: 1)
                            .frame(height: 60)
                        
                        FloatingLabelTextField(text: $username, title: "Username", isSecure: false, onSubmit: {
                            isPasswordFieldFocused = true
                        }, isFocused: $isUsernameFieldFocused)
                        .modifier(NeumorphicStyle(cornerRadius: 10, color: Color.clear))
                        .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                        
                        FloatingLabelTextField(text: $password, title: "Password", isSecure: true, onSubmit: {
                            isRepairPasswordFieldFocused = true
                        }, isFocused: $isPasswordFieldFocused)
                        .modifier(NeumorphicStyle(cornerRadius: 10, color: Color.clear))
                        .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                        
                        FloatingLabelTextField(text: $confirmPassword, title: "Repeat Password", isSecure: true, onSubmit : { completeSetup() }, isFocused: $isRepairPasswordFieldFocused )
                            .modifier(NeumorphicStyle(cornerRadius: 10, color: Color.clear))
                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                        
                        
                        CoolButton(title: "Save", systemImage: "lock", action: completeSetup)
                            .frame(maxWidth: idealWidth(for: geometry.size.width))
                            .padding(.top, 12)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .animation(.easeInOut, value: keyboardResponder.currentHeight)
                            .opacity(username.isEmpty || password.isEmpty || password != confirmPassword ? 0.5 : 1.0)
                            .disabled(username.isEmpty || password.isEmpty || password != confirmPassword)
                        Spacer()
                    }.frame(maxWidth: .infinity)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                if isUsernameFieldFocused || isPasswordFieldFocused || isRepairPasswordFieldFocused {
                                    Button {
                                        hideKeyboard()
                                    } label: {
                                        HideKeyboardLabel()
                                    }
                                }
                            }
                        }
                }
            }
            
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Setup Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .fullScreenCover(isPresented: $setupComplete) {
                FaceIDView(isPresented: $setupComplete)
                    .environmentObject(openAiManager)
                    .environmentObject(pinecone)
                    .environmentObject(keyboardResponder)
                    .environmentObject(language)
                    .environmentObject(speechManager)
            }
        }
    }
    
    private func completeSetup() {
        
        guard !username.isEmpty && !password.isEmpty && password == confirmPassword else {
            
            alertMessage = "Please make sure all fields are filled and passwords match."
            withAnimation { showAlert = true }
            return
        }
        
        //        let passwordData = Data(password.utf8)
        //        KeychainManager.standard.save(service: "dev.chillvibes.MyndVault", account: username, data: passwordData)
        KeychainManager.standard.saveUsernameAndPassword(username: username, password: password)
        UserDefaults.standard.set(false, forKey: "isFirstLaunch")
        setupComplete = true
    }
}


#Preview {
    let ckViewModel = CloudKitViewModel.shared
    let pineconeActor = PineconeActor(cloudKitViewModel: ckViewModel)
    let pineconeViewModel = PineconeViewModel(pineconeActor: pineconeActor, CKviewModel: ckViewModel)

    let openAIActor = OpenAIActor()
    let openAiManager = OpenAIViewModel(openAIActor: openAIActor)

    InitialSetupView()
        .environmentObject(CloudKitViewModel())
        .environmentObject(LanguageSettings.shared)
        .environmentObject(LanguageSettings.shared)
        .environmentObject(SpeechRecognizerManager())
        .environmentObject(openAiManager)
        .environmentObject(pineconeViewModel)
        .environmentObject(KeyboardResponder())
        .environmentObject(AuthenticationManager())
}
