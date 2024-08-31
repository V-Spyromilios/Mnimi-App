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
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pinecone: PineconeManager
    
    @Environment(\.colorScheme) var colorScheme
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var setupComplete = false
    @State private var shake = false
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
                    TypingTextView(fullText: "Please provide Username\nand Password to be used if FaceID is not available.", isTitle: false).shadow(radius: 1)
                    
                        .frame(height: 60)
                    
                    
                        FloatingLabelTextField(text: $username, title: "Username", isSecure: false, isFocused: $isUsernameFieldFocused)
                        .modifier(NeumorphicStyle(cornerRadius: 10, color: Color.clear))
                    
                        FloatingLabelTextField(text: $password, title: "Password", isSecure: true, isFocused: $isPasswordFieldFocused)
                        .modifier(NeumorphicStyle(cornerRadius: 10, color: Color.clear))
                    
                        FloatingLabelTextField(text: $confirmPassword, title: "Repait Password", isSecure: true, isFocused: $isRepairPasswordFieldFocused)
                        .modifier(NeumorphicStyle(cornerRadius: 10, color: Color.clear))
                    
                    
                    Button(action:  {
                        completeSetup()
                    }
                    ) {
                        ZStack {
                            RoundedRectangle(cornerRadius: Constants.rectCornerRad)
                                .fill(Color.customLightBlue)
                                .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                                .frame(height: Constants.buttonHeight)
                            
                            Text("Save").font(.title2).bold()
                                .foregroundColor(Color.buttonText)
                                .accessibilityLabel("save")
                        }
                        .contentShape(Rectangle())
                        
                    }
                    .frame(maxWidth: idealWidth(for: geometry.size.width))
                    .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
                    .padding(.top, 12)
                    .padding(.horizontal)
                    .padding(.horizontal)
                    .animation(.easeInOut, value: keyboardResponder.currentHeight)
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
                .onChange(of: shake) { _, newValue in
                    if newValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            shake = false
                        }
                    }
                }
                .fullScreenCover(isPresented: $setupComplete) {
                    FaceIDView()
//                        .environmentObject(<#T##object: ObservableObject##ObservableObject#>)
                        .environmentObject(openAiManager)
                        .environmentObject(pinecone)
                        .environmentObject(progressTracker)
                        .environmentObject(keyboardResponder)
                        .environmentObject(language)
                        .environmentObject(speechManager)
                }
            }
        
            
}

    private func completeSetup() {

        if shake { return }

        guard !username.isEmpty && !password.isEmpty && password == confirmPassword else {
            withAnimation { shake = true }
            alertMessage = "Please make sure all fields are filled and passwords match."
            showAlert = true
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
    InitialSetupView()
}
