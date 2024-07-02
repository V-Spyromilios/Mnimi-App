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
    @State private var greenHeight: CGFloat = UIScreen.main.bounds.height + (UIScreen.main.bounds.height * 0.15)
    @State private var showError = false
    @State private var showPasswordAuth = false
    @State private var username = ""
    @State private var password = ""
    @State private var showMainView = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated && cloudKitViewModel.userIsSignedIn {
           
                MainView()
            } else if authManager.isLoggedOut {
                LoggedOutView()
            } else {
                ZStack {
                    Color.britishRacingGreen
                        .frame(height: greenHeight)
                        .ignoresSafeArea()
                    VStack {
                        
                        Text("")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.buttonText)
                            .fontDesign(.rounded)
                            .padding(.top, 14)
                        
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
                .environmentObject(keyboardResponder)
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
    
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.colorScheme) var colorScheme
    @State private var alertPasswordMessage = ""
    @State private var showPasswordError = false
    
    var body: some View {
        ZStack {
            Color.britishRacingGreen.ignoresSafeArea()
            VStack {
                Text("Mynd Vault 🗃️").font(.largeTitle).fontWeight(.semibold).foregroundStyle(.white).fontDesign(.rounded).padding()
                Text("Continue with\nUsername and Password")
                    .foregroundStyle(Color.buttonText)
                    .font(.title2)
                    .padding()
                Spacer()
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.0)
                            .stroke(lineWidth: 1)
                            .opacity(colorScheme == .light ? 0.3 : 0.7)
                            .foregroundColor(Color.gray)
                    )
                    
                    .padding()
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.0)
                            .stroke(lineWidth: 1)
                            .opacity(colorScheme == .light ? 0.3 : 0.7)
                            .foregroundColor(Color.gray)
                    )
                    .padding()
                Button(action:  {
                        authenticateWithPassword()
                }
    ) {
                    ZStack {
                        RoundedRectangle(cornerRadius: rectCornerRad)
                            .fill(Color.primaryAccent)
                            .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                            .frame(height: 60)
                            
                        Text("Save").font(.title2).bold()
                            .foregroundColor(Color.buttonText)
                            .accessibilityLabel("save")
                    }
                    .contentShape(Rectangle())
                   
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.horizontal)
                .animation(.easeInOut, value: keyboardResponder.currentHeight)
                .id("SubmitButton")
                .padding(.bottom, keyboardResponder.currentHeight > 0 ? 15 : 0)
                Spacer()
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
    @State static var showPasswordAuth = true
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
