//
//  InitialSetupView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 18.05.24.
//

import SwiftUI
import LocalAuthentication

struct InitialSetupView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var setupComplete = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.britishRacingGreen.ignoresSafeArea()
                
                VStack {
                    Text("Mynd Vault 🗃️").font(.largeTitle).fontWeight(.semibold).foregroundStyle(.white).fontDesign(.rounded).padding()
                    Text("Initial Setup").foregroundStyle(.white)
                        .font(.title2)
                        .padding()
                    Spacer()
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: idealWidth(for: geometry.size.width))
                        .padding()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: idealWidth(for: geometry.size.width))
                        .padding()
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: idealWidth(for: geometry.size.width))
                        .padding()
                    
                    Button(action: completeSetup) {
                        ZStack {
                            RoundedRectangle(cornerRadius: rectCornerRad)
                                .fill(Color.customDarkBlue)
                                .shadow(color: .white, radius: 7)
                                .frame(height: 60)
                            
                            Text("Save").font(.title2).bold().foregroundColor(.white)
                                .accessibilityLabel("save")
                        }
                        .contentShape(Rectangle())
                        .shadow(radius: 7)
                    }
                    .frame(maxWidth: idealWidth(for: geometry.size.width))
                    .padding(.top, 12)
                    .padding(.horizontal)
                    //            .animation(.easeInOut, value: keyboardResponder.currentHeight)
                    .padding()
                    Spacer()
                }.frame(maxWidth: .infinity)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Setup Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .fullScreenCover(isPresented: $setupComplete) {
                FaceIDView()
            }
        }
    }

    private func completeSetup() {
        guard !username.isEmpty && !password.isEmpty && password == confirmPassword else {
            alertMessage = "Please make sure all fields are filled and passwords match."
            showAlert = true
            return
        }

        let passwordData = Data(password.utf8)
        KeychainManager.standard.save(service: "dev.chillvibes.MyndVault", account: username, data: passwordData)
        // Save setup complete status

        UserDefaults.standard.set(false, forKey: "isFirstLaunch")
        setupComplete = true

        // Attempt to enable Face ID
//        let context = LAContext()
//        var error: NSError?
//        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
//            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Enable Face ID for faster login") { success, evaluationError in
//                DispatchQueue.main.async {
//                    if success {
//                        // Face ID setup complete, navigate to main view
//                        setupComplete = true
//                    } else {
//                        // Face ID setup failed, show alert
//                        alertMessage = "Face ID setup failed: \(evaluationError?.localizedDescription ?? "Unknown error")"
//                        showAlert = true
//                    }
//                }
//            }
//        } else {
//            // Device does not support Face ID
//            alertMessage = "Face ID is not available on this device."
//            showAlert = true
//        }
    }
}


#Preview {
    InitialSetupView()
}
