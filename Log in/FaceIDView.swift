//
//  FaceIDView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 18.05.24.
//

import SwiftUI
import LocalAuthentication

struct FaceIDView: View {
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var cloudKitViewModel: CloudKitViewModel
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pinecone: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var language: LanguageSettings
    @EnvironmentObject var speechManager: SpeechRecognizerManager
    @State private var showError = false
    @State private var showNoInternet = false
    @State private var showPasswordAuth = false
    @State private var username = ""
    @State private var password = ""
    @State private var showMainView = false
    @State private var authAttempts: Int = 0
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        Group {
            if authManager.isAuthenticated && cloudKitViewModel.userIsSignedIn  {
                MainView()
                    .environmentObject(openAiManager)
                    .environmentObject(pinecone)
                    .environmentObject(progressTracker)
                    .environmentObject(keyboardResponder)
                    .environmentObject(language)
                    .environmentObject(speechManager)
            } else if authManager.isLoggedOut {
                LoggedOutView()
            } else {
                ZStack {
                    Color.customTiel
                        .ignoresSafeArea()
                    VStack {
                        
                        LottieRepresentable(filename: "Image Recognition", loopMode: .loop).padding()
                            .frame(height: 400)
                            .onTapGesture(perform: authenticate)
                        
                            .padding(.top)
                            .onAppear(perform: authenticate)
                        
                        
                        Button {
                            self.authenticate()
                        } label: {
                            Image(systemName: "faceid").resizable().frame(width: 100, height: 100)
                                .foregroundStyle(Color.cardBackground).shadow(radius: 4, x: -3, y: -3)
                            
                        }
                        Spacer()
                    }
                }
                .statusBar(hidden: true)
                .sheet(isPresented: $showPasswordAuth) {
                    UsernamePasswordLoginView(showPasswordAuth: $showPasswordAuth, username: $username, password: $password)
                        .environmentObject(keyboardResponder)
                }
            }
        }
        .alert(isPresented: $showNoInternet) {
            Alert(
                title: Text("You are not connected to the Internet"),
                message: Text("Please check your connection"),
                dismissButton: .cancel(Text("OK"))
            )
        }
        .onChange(of: networkManager.hasInternet) { _, hasInternet in
            if !hasInternet {
                showNoInternet = true
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Authentication Failed"),
                message: Text(errorMessage),
                primaryButton: .default(Text("Retry"), action: authenticate),
                secondaryButton: .default(Text("Enter Username/Password"), action: {
                    showPasswordAuth = true
                })
            )
        }
        //        .onChange(of: authAttempts) {
        //            if authAttempts >= 2 {
        //                showPasswordAuth = true
        //            }
        //        }
    }
    
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        // check whether biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // it's possible, so go ahead and use it
            let reason = "We need to unlock your data."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                // authentication has now completed
                if success {
                    // authenticated successfully
                    
                    withAnimation(.easeInOut) {
                        
                        authManager.login()
                    }
                    //
                } else {
                    //                    authAttempts += 1
                    //                    if authAttempts >= 2 {
                    //                        showPasswordAuth = true
                    //                    }
                    handleAuthenticationError(error: error)
                }
            }
        } else {
            authAttempts += 1
            if authAttempts >= 2 {
                showPasswordAuth = true
            }
        }
    }
    
    
    
    
    private func handleAuthenticationError(error: Error?) {
        guard let laError = error as? LAError else {
            errorMessage = "An unknown error occurred."
            showErrorAlert = true
            return
        }
        
        switch laError.code {
        case .authenticationFailed:
            errorMessage = "There was a problem verifying your identity."
        case .userCancel:
            errorMessage = "You canceled the authentication."
        case .userFallback:
            showPasswordAuth = true
            return
        case .systemCancel:
            errorMessage = "Authentication was canceled by the system."
        case .passcodeNotSet:
            errorMessage = "Passcode is not set on the device."
        case .biometryNotAvailable:
            errorMessage = "Biometric authentication is not available on this device."
        case .biometryNotEnrolled:
            errorMessage = "No biometric identities are enrolled."
        case .biometryLockout:
            errorMessage = "Biometric authentication is locked out."
        default:
            errorMessage = "An unknown error occurred."
        }
        
        authAttempts += 1
        if authAttempts >= 2 {
            showPasswordAuth = true
        } else {
            showErrorAlert = true
        }
    }
    
    //    private func authenticate() {
    //          let context = LAContext()
    //          context.localizedCancelTitle = "Enter Username/Password"
    //
    //          var authError: NSError?
    //          if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
    //              context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Log in with Face ID") { success, error in
    //                  DispatchQueue.main.async {
    //                      if success {
    //                          withAnimation(.easeInOut) {
    //                              authManager.login()
    //                          }
    //                      } else {
    //                          authAttempts += 1
    //                          if authAttempts >= 2 {
    //                              showPasswordAuth = true
    //                          }
    //                      }
    //                  }
    //              }
    //          } else {
    //              authAttempts += 1
    //              if authAttempts >= 2 {
    //                  showPasswordAuth = true
    //              }
    //          }
    //      }
}

struct UsernamePasswordLoginView: View {
    @Binding var showPasswordAuth: Bool
    @Binding var username: String
    @Binding var password: String
    
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.colorScheme) var colorScheme
    @State private var alertPasswordMessage = ""
    @State private var showPasswordError = false
    @State private var shake: Bool = false
    
    @FocusState private var isUsernameFieldFocused: Bool
    @FocusState private var isPasswordFieldFocused: Bool
    
    var body: some View {
        ZStack {
            LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                .opacity(0.4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            VStack {
                
                TypingTextView(fullText: "FaceID/ TouchID failed.\nPlease provide Username and\nPassword instead")
                    .shadow(radius: 1)
                    .frame(height: 100)
                    .padding(.horizontal)
                
                FloatingLabelTextField(text: $username, title: "Username", isSecure: false, isFocused: $isUsernameFieldFocused)
                    .modifier(NeumorphicStyle(cornerRadius: 10, color: Color.clear))
                
                
                FloatingLabelTextField(text: $password, title: "Password", isSecure: true, isFocused: $isPasswordFieldFocused)
                    .modifier(NeumorphicStyle(cornerRadius: 10, color: Color.clear))
                
                Button(action: {
                    if shake { return }
                    
                    if password.isEmpty {
                        withAnimation { shake = true }
                        return
                    }
                    authenticateWithPassword()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.customTiel)
                            .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                            .frame(height: Constants.buttonHeight)
                        
                        Text("Login").font(.title2).bold()
                            .foregroundColor(Color.buttonText)
                            .accessibilityLabel("Login")
                    }
                    .contentShape(Rectangle())
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.horizontal)
                .animation(.easeInOut, value: keyboardResponder.currentHeight)
                .padding(.bottom, keyboardResponder.currentHeight > 0 ? 15 : 0)
                .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
                Spacer()
                
            }// -VStack
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if isUsernameFieldFocused || isPasswordFieldFocused {
                        Button {
                            hideKeyboard()
                        } label: {
                            HideKeyboardLabel()
                        }
                    }
                }
            }
            //TODO: Check if this appears in the Keyboard, Check InitialSetUpView for correct implementation !
            
        } // -ZStack
        .alert(isPresented: $showPasswordError) {
            Alert(
                title: Text(alertPasswordMessage),
                message: Text(""),
                dismissButton: .cancel(Text("OK"), action: { showPasswordAuth = true })
            )
        }
        .onChange(of: shake) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shake = false
                }
            }
        }
        
    }
    
    private func authenticateWithPassword() {
        guard let savedUsername = KeychainManager.standard.readUsername(),
              let savedPasswordData = KeychainManager.standard.read(service: "dev.chillvibes.MyndVault", account: savedUsername),
              let savedPassword = String(data: savedPasswordData, encoding: .utf8) else {
            alertPasswordMessage = "Invalid username."
            showPasswordAuth = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showPasswordError = true
            }
            return
        }
            if savedPassword != password {
            alertPasswordMessage = "Invalid password."
            showPasswordAuth = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showPasswordError = true
            }
            return
        }
        
        authManager.login()
        self.password = ""
        self.username = ""
        showPasswordAuth = false
    }
}
//struct FaceIDView_Previews: PreviewProvider {
//    @State static var username = ""
//    @State static var password = ""
//
//    static var previews: some View {
//        FaceIDView()
//            .environmentObject(AuthenticationManager())
//            .environmentObject(KeyboardResponder())
//    }
//}

struct UsernamePasswordLoginView_Previews: PreviewProvider {
    @State static var showPasswordAuth = false
    @State static var username = ""
    @State static var password = ""
    
    static var previews: some View {
        UsernamePasswordLoginView(
            showPasswordAuth: $showPasswordAuth,
            username: $username,
            password: $password
        )
        .environmentObject(AuthenticationManager())
        .environmentObject(KeyboardResponder())
    }
}
