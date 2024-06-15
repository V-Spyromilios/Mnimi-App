//
//  FaceIDView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 18.05.24.
//

import SwiftUI
import LocalAuthentication

//struct FaceIDView: View {
//
//    @EnvironmentObject var authManager: AuthenticationManager
//    @State private var showError = false
//    @State private var alertPasswordMessage = ""
//    @State private var showPasswordError = false
//    @State private var showPasswordAuth = false
//    @State private var username = ""
//    @State private var password = ""
//    @State private var showMainView = false
//
//    var body: some View {
//        Group {
//            if authManager.isAuthenticated {
//                MainView()
//
//            } else if authManager.isLoggedOut {
//                LoggedOutView()
//
//            } else {
//                ZStack {
//                    Color.britishRacingGreen.ignoresSafeArea()
//                    VStack {
//                    Text("Mynd Vault 🗃️")
//                        .font(.largeTitle)
//                        .fontWeight(.semibold)
//
//                        .foregroundStyle(.white)
//                        .fontDesign(.rounded)
//Spacer()
//                        Image(systemName: "faceid")
//                            .resizable()
//                            .frame(width: 80, height: 80)
//                            .foregroundStyle(.blue)
//                            .padding(.bottom, 12)
//                        Text("Face ID")
//                            .font(.title3)
//                            .fontWeight(.semibold)
//                            .fontDesign(.rounded)
//                            .foregroundStyle(.gray)
//                        Spacer()
//                    }.padding(.top)
//                    .onAppear(perform: authenticate)
//                    .onTapGesture(perform: authenticate)
//                }
//                .statusBar(hidden: true)
//
//            }
//        }
//        .alert(isPresented: $showError) {
//            Alert(
//                title: Text("Face ID authentication Failed"),
//                message: Text("Please try again."),
//                primaryButton: .default(Text("Retry"), action: authenticate),
//                secondaryButton: .default(Text("Enter Username/Password"), action: {
//                    showPasswordAuth = true
//                })
//            )
//        }
//        .alert(isPresented: $showPasswordError) {
//            Alert(
//                title: Text(alertPasswordMessage),
//                message: Text(""),
//                dismissButton: .cancel(Text("OK"), action: {showPasswordAuth = true })
//            )
//        }
//        .sheet(isPresented: $showPasswordAuth) {
//            ZStack {
//                Color.britishRacingGreen.ignoresSafeArea()
//                Text("Continue with Username and Password")
//                    .font(.title2)
//                    .fontWeight(.semibold)
//                    .offset(y: -170)
//                    .foregroundStyle(.white)
//                    .fontDesign(.rounded)
//                    .padding(.bottom, 50)
//
//                VStack {
//                    TextField("Username", text: $username)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .padding()
//
//                    SecureField("Password", text: $password)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .padding()
//
//                    Button(action: authenticateWithPassword) {
//                        ZStack {
//                            RoundedRectangle(cornerRadius: rectCornerRad)
//                                .fill(Color.customDarkBlue)
//                                .shadow(color: .gray, radius: 7)
//                                .frame(height: 60)
//
//                            Text("Log in").font(.title2).bold().foregroundColor(.white)
//                                .accessibilityLabel("log in")
//                        }
//                        .contentShape(Rectangle())
//                        .shadow(color: .gray, radius: 7)
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding(.top, 12)
//                    .padding(.horizontal)
//                    .padding()
//                }
//                .frame(maxWidth: .infinity)
//                .statusBar(hidden: true)
//            }
//
//        }
//    }
//
//    private func authenticate() {
//        let context = LAContext()
//        context.localizedCancelTitle = "Enter Username/Password"
//
//        var authError: NSError?
//        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
//            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Log in with Face ID") { success, error in
//                DispatchQueue.main.async {
//                    if success {
//
//                        authManager.login()
////                        self.showMainView = true
//                    } else {
//                        if let laError = error as? LAError {
//                            switch laError.code {
//                            case .userCancel, .systemCancel, .appCancel, .authenticationFailed, .biometryNotAvailable, .biometryNotEnrolled, .biometryLockout:
//                                // canceled Face ID, show username/password option
//                                self.showPasswordAuth = true
//                            default:
//                                self.showError = true
//                            }
//                        } else {
//                            self.showError = true
//                        }
//                    }
//                }
//            }
//        } else {
//            self.showError = true
//        }
//    }
//
//    private func authenticateWithPassword() {
//        guard let savedPasswordData = KeychainManager.standard.read(service: "dev.chillvibes.MyndVault", account: username),
//              let savedPassword = String(data: savedPasswordData, encoding: .utf8),
//              savedPassword == password else {
//            alertPasswordMessage = "Invalid username or password."
//            showPasswordAuth = false
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                showPasswordError = true
//            }
//            return
//        }
//
//        // password ok
//        authManager.login()
//        self.password = ""
//        self.username = ""
//        showPasswordAuth = false
////        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
////            showMainView = true }
//    }
//}

struct FaceIDView: View {
    
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var cloudKitViewModel: CloudKitViewModel
    @State private var greenHeight: CGFloat = UIScreen.main.bounds.height + (UIScreen.main.bounds.height * 0.15)
    @State private var showError = false
    @State private var showPasswordAuth = false
    @State private var username = ""
    @State private var password = ""
    @State private var showMainView = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated && cloudKitViewModel.userIsSignedIn && !cloudKitViewModel.fetchedNamespaceDict.isEmpty {
           
                MainView()
            } else if authManager.isLoggedOut {
                LoggedOutView()
            } else {
                ZStack {
                    Color.britishRacingGreen
                        .frame(height: greenHeight)
                        .ignoresSafeArea()
                    VStack {
                        Text("Mynd Vault 🗃️")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .fontDesign(.rounded)
                        Spacer()
                        Image(systemName: "faceid")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.blue)
                            .padding(.bottom, 12)
                        Text("Face ID")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .foregroundStyle(.gray)
                        Spacer()
                    }.padding(.top)
                        .onAppear(perform: authenticate)
                        .onTapGesture(perform: authenticate)
                }
                .statusBar(hidden: true)
            }
        } // for the alert, perhaps Use VStack
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Face ID authentication Failed"),
                message: Text("Please try again."),
                primaryButton: .default(Text("Retry"), action: authenticate),
                secondaryButton: .default(Text("Enter Username/Password"), action: {
                    showPasswordAuth = true
                })
            )
        }
        .sheet(isPresented: $showPasswordAuth) {
            UsernamePasswordLoginView(showPasswordAuth: $showPasswordAuth, username: $username, password: $password)
        }
    }
    
    private func authenticate() {
        let context = LAContext()
        context.localizedCancelTitle = "Enter Username/Password"
        
        var authError: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Log in with Face ID") { success, error in
                DispatchQueue.main.async {
                    if success {
                        withAnimation(.easeInOut(duration: 1.5)) {
                            authManager.login()
                            greenHeight = 0
                        }
                        
                    } else {
                        self.showError = true
                    }
                }
            }
        } else {
            self.showError = true
        }
    }
}


struct UsernamePasswordLoginView: View {
    @Binding var showPasswordAuth: Bool
    @Binding var username: String
    @Binding var password: String
    
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var alertPasswordMessage = ""
    @State private var showPasswordError = false
    
    var body: some View {
        ZStack {
            Color.britishRacingGreen.ignoresSafeArea()
            VStack {
                Text("Continue with Username and Password")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.bottom, 50)
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button(action: authenticateWithPassword) {
                    Text("Log in")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: 60)
                        .background(Color.customDarkBlue)
                        .cornerRadius(10)
                        .shadow(color: .gray, radius: 7)
                        .padding(.horizontal)
                        .padding(.top, 12)
                }
            }
        }
        .alert(isPresented: $showPasswordError) {
            Alert(
                title: Text(alertPasswordMessage),
                message: Text(""),
                dismissButton: .cancel(Text("OK"), action: { showPasswordAuth = true })
            )
        }
    }
    
    private func authenticateWithPassword() {
        
        guard let savedPasswordData = KeychainManager.standard.read(service: "dev.chillvibes.MyndVault", account: username),
              let savedPassword = String(data: savedPasswordData, encoding: .utf8),
              savedPassword == password else {
            alertPasswordMessage = "Invalid username or password."
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

#Preview {
    FaceIDView()
}
