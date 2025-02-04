//
//  FaceIDView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 18.05.24.
//

import SwiftUI
import LocalAuthentication
import CloudKit

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
    @State private var authAttempts: Int = 0
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showAccountDeleted: Bool = false
    
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
        .fullScreenCover(isPresented: $showAccountDeleted) {
            AccountDeletedView()
        }
        .onAppear {
            detectBiometricType()
            authenticate()
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
                showPasswordAuth = true
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
            showPasswordAuth = true
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
            showPasswordAuth = true
        case .biometryNotEnrolled:
            showPasswordAuth = true
        case .biometryLockout:
            attemptDeviceOwnerAuthentication()
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
    private func attemptDeviceOwnerAuthentication() {

        let context = LAContext()
        let reason = "FaceID/ ToucID are locked. Please authenticate using your device passcode.\n Wrong passcode will delete your account."
        
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    authManager.login()
                    UserDefaults.standard.set(false, forKey: "isFirstLaunch")
                    cloudKitViewModel.isFirstLaunch = false
                    isPresented = false
                    self.errorMessage = ""
                    self.showErrorAlert = false
                }
                 else {
//                   DeleteAccount()
                }
            }
        }
    }
    private func deleteAccount() {

        Task {
            await deleteNamespaceFromICloud()
            await pinecone.deleteAllVectorsInNamespace()
            await cloudKitViewModel.deleteAllImageItems()
            removeUserDefaults()
            deleteKeyChain()
        }
        showAccountDeleted = true
    }
    
    private func deleteNamespaceFromICloud() async {

                let container = CKContainer.default()
                let privateDatabase = container.privateCloudDatabase
                guard let recordIDDelete = KeychainManager.standard.readRecordID(account: "recordIDDelete") else {
//                    self.errorString = "Could not retrieve recordID from keychain."
//                    self.showError.toggle()
                    return
                }
                debugLog("Before Deleting: \(String(describing: recordIDDelete))")
                await cloudKitViewModel.deleteRecordFromICloud(recordID: recordIDDelete, from: privateDatabase)
        
    }
    
    func deleteKeyChain() {
        
        var keychainDeleteRetryCount = 0
        let keychainDeletemaxRetries = 3
        
        guard let username = KeychainManager.standard.readUsername() else {
            debugLog("deleteKeyChain::No username found in keychain.")
//            isKeychainDeleted = false
            return
        }
        
        let success = KeychainManager.standard.delete(service: "dev.chillvibes.MyndVault", account: username)
        
        if success {
            debugLog("Successfully deleted keychain for username: \(username)")
//            isKeychainDeleted = true
        } else {
            debugLog("deleteKeyChain::Failed to delete keychain.")
//            isKeychainDeleted = false
            
            if keychainDeleteRetryCount < keychainDeletemaxRetries {
                keychainDeleteRetryCount += 1
                debugLog("Retrying deletion... Attempt \(keychainDeleteRetryCount)")
                deleteKeyChain()
            }
        }
    }
    
    private func removeUserDefaults() {

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "isFirstLaunch")
        defaults.removeObject(forKey: "monthlyApiCalls")
        defaults.removeObject(forKey: "selectedPromptLanguage")
        defaults.removeObject(forKey: "APITokenUsage")
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

                //TODO: all below mmust be localized...
                TypingTextView(fullText: String(localized: "faceIDView_please_provide_username"))
                    .shadow(radius: 1)
                    .frame(height: 100)
                    .padding(.horizontal)
                
                FloatingLabelTextField(text: $username, title: String(localized: "username"), isSecure: false, onSubmit: switchFocusToPass, isFocused: $isUsernameFieldFocused)
                    .modifier(NeumorphicStyle(cornerRadius: 10, color: Color.clear))
                    .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                
                
                FloatingLabelTextField(text: $password, title: String(localized: "password"), isSecure: true, onSubmit: authenticateWithPassword, isFocused: $isPasswordFieldFocused)
                    .modifier(NeumorphicStyle(cornerRadius: 10, color: Color.clear))
                    .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                
                CoolButton(title: "Login", systemImage: "door.sliding.right.hand.open") {
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
    
//    private func authenticateWithPassword() {
//        guard let savedUsername     = KeychainManager.standard.readUsername(),
//              let savedPasswordData = KeychainManager.standard.read(service: "dev.chillvibes.MyndVault", account: savedUsername),
//              let savedPassword     = String(data: savedPasswordData, encoding: .utf8) else {
//            alertPasswordMessage   = "Invalid username."
//            showPasswordAuth = false
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                showPasswordError = true
//            }
//            return
//        }
//        if savedPassword != password {
//            alertPasswordMessage = "Invalid password."
//            showPasswordAuth = false
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                showPasswordError = true
//            }
//            return
//        }
//        
//        authManager.login()
//        self.password = ""
//        self.username = ""
//        showPasswordAuth = false
//        UserDefaults.standard.set(false, forKey: "isFirstLaunch")
//        cloudKitViewModel.isFirstLaunch = false
//        showFaceID = false
//    }
    
    func switchFocusToPass() {
        isUsernameFieldFocused = false
        isPasswordFieldFocused = true
    }
    
    private func authenticateWithPassword() {
        
        if password.isEmpty { return }

        guard let savedUsername = KeychainManager.standard.readUsername(),
              let savedPasswordData = KeychainManager.standard.read(service: "dev.chillvibes.MyndVault", account: savedUsername),
              let savedPassword = String(data: savedPasswordData, encoding: .utf8) else {
            alertPasswordMessage = String(localized: "invalid_username_or_password.")
            showPasswordError = true
            return
        }
        
        if savedPassword != password {
            alertPasswordMessage = String(localized: "invalid_password")
            showPasswordError = true
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
