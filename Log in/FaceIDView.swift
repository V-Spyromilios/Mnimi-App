//
//  FaceIDView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 18.05.24.
//

import SwiftUI
import LocalAuthentication

struct FaceIDView: View {

    @Binding var isPresented: Bool
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var cloudKitViewModel: CloudKitViewModel
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var openAiManager: OpenAIViewModel
    @EnvironmentObject var pinecone: PineconeViewModel
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
    @State private var shouldShowMainView = false
    
    enum BiometricType {
        case none
        case touchID
        case faceID
    }

    @State private var biometricType: BiometricType = .none
    
    var body: some View {
        //        Group {
        //            if shouldShowMainView {
        //                MainView()
        //                    .environmentObject(openAiManager)
        //                    .environmentObject(pinecone)
        //                    .environmentObject(keyboardResponder)
        //                    .environmentObject(language)
        //                    .environmentObject(speechManager)
        //            } else if authManager.isLoggedOut {
        //                LoggedOutView()
        //            } else {
        ZStack {
            
            LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                .opacity(0.4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            VStack {
                
                LottieRepresentable(filename: "Image Recognition", loopMode: .loop).padding()
                    .frame(height: 400)
                    .padding(.top)

                Spacer()
            }
            Button {
                authenticate()
            } label: {
                Image(systemName: "faceid")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(Color.white).shadow(radius: 4, x: -3, y: -3)
            }

            
        }
        .statusBar(hidden: true)
        .fullScreenCover(isPresented: $showPasswordAuth) {
            UsernamePasswordLoginView(showPasswordAuth: $showPasswordAuth, username: $username, password: $password, showFaceID: $isPresented)
                .environmentObject(keyboardResponder)
                .environmentObject(authManager)
                .environmentObject(cloudKitViewModel)
        }
        .onAppear {
            detectBiometricType()
            authenticate()
            checkAuthenticationStatus()
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
        .onChange(of: authManager.isAuthenticated) {

            debugLog("isAuthenticated: \(authManager.isAuthenticated)")

        }
        .onChange(of: cloudKitViewModel.userIsSignedIn) { _, newValue in
            debugLog("cloudKitViewModel.userIsSignedIn changed to \(newValue)")
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
    }
    private func detectBiometricType() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            debugLog("Thread -detectBiometricType-: \(Thread.isMainThread ? "Main" : "Background")")

            let biometryType = context.biometryType
            DispatchQueue.main.async {
                switch biometryType {
                case .faceID:
                    biometricType = .faceID
                case .touchID:
                    biometricType = .touchID
                default:
                    biometricType = .none
                }
            }
        } else {
            DispatchQueue.main.async {
                biometricType = .none
            }
        }
    }
    
    private func checkAuthenticationStatus() {

        if authManager.isAuthenticated && cloudKitViewModel.userIsSignedIn {
            shouldShowMainView = true

            debugLog("Calling checkAuthenticationStatus OK !")
        } else {
           debugLog("Calling checkAuthenticationStatus again...")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                checkAuthenticationStatus()
            }
        }
    }
    
    
    private func authenticate() {
        DispatchQueue.global(qos: .userInitiated).async {
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "We need to confirm it's you."
                
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                    DispatchQueue.main.async {
                        if success {
                            authManager.login()
                            UserDefaults.standard.set(false, forKey: "isFirstLaunch")
                            cloudKitViewModel.isFirstLaunch = false
                            isPresented = false
                            debugLog("Authentication succeeded, calling authManager.login()")
                        } else {
                            handleAuthenticationError(error: authenticationError)

                            debugLog("Authentication failed, calling handleAuthenticationError()")
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    authAttempts += 1
                    if authAttempts >= 2 {
                        showPasswordAuth = true
                    }
                }
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
            isPresented = false
            return
//            errorMessage = "You canceled the authentication."
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
    
}

struct UsernamePasswordLoginView: View {
    @Binding var showPasswordAuth: Bool
    @Binding var username: String
    @Binding var password: String
    @Binding var showFaceID: Bool
    
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var cloudKitViewModel: CloudKitViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var alertPasswordMessage = ""
    @State private var showPasswordError = false
    
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
                    .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                
                
                FloatingLabelTextField(text: $password, title: "Password", isSecure: true, isFocused: $isPasswordFieldFocused)
                    .modifier(NeumorphicStyle(cornerRadius: 10, color: Color.clear))
                    .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                
                CoolButton(title: "Login", systemImage: "door.sliding.right.hand.open") {
                    if password.isEmpty { return }
                    authenticateWithPassword()
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.horizontal)
                .animation(.easeInOut, value: keyboardResponder.currentHeight)
                .padding(.bottom, keyboardResponder.currentHeight > 0 ? 15 : 0)
                .opacity(password.isEmpty ? 0.5 : 1.0)
                .disabled(password.isEmpty)
                .accessibility(label: Text("Login"))
                .accessibility(hint: Text("Login to MyndVault app with the provided username and password."))
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
            
            
        } // -ZStack
        .alert(isPresented: $showPasswordError) {
            Alert(
                title: Text(alertPasswordMessage),
                message: Text(""),
                dismissButton: .cancel(Text("OK"), action: { showPasswordAuth = true })
            )
        }
        
    }
    
    private func authenticateWithPassword() {
        guard let savedUsername     = KeychainManager.standard.readUsername(),
              let savedPasswordData = KeychainManager.standard.read(service: "dev.chillvibes.MyndVault", account: savedUsername),
              let savedPassword     = String(data: savedPasswordData, encoding: .utf8) else {
            alertPasswordMessage   = "Invalid username."
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
        UserDefaults.standard.set(false, forKey: "isFirstLaunch")
        cloudKitViewModel.isFirstLaunch = false
        showFaceID = false
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
            password: $password, showFaceID: .constant(false)
        )
        .environmentObject(AuthenticationManager())
        .environmentObject(KeyboardResponder())
    }
}
