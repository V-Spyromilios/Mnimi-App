//
//  SignUpWithPasswordView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 18.05.24.
//

import SwiftUI
import Security

struct SignUpWithPasswordView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var hasSignedUp = false

    var body: some View {
        ZStack {
            Color.britishRacingGreen.ignoresSafeArea()
            VStack {
            Text("Mynd Vault 🗃️").font(.largeTitle).fontWeight(.semibold).foregroundStyle(.white).fontDesign(.rounded)

                Spacer()
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: signUp) {
               
                ZStack {
                    RoundedRectangle(cornerRadius: rectCornerRad)
                        .fill(Color.customDarkBlue)
                        .shadow(color: .gray, radius: 7)
                        .frame(height: 60)
                        
                    Text("Sign Up").font(.title2).bold().foregroundColor(.white)
                        .accessibilityLabel("save")
                }
                .contentShape(Rectangle())
                .shadow(color: .gray, radius: 7)
            }.padding(.top)
            .padding()
                Spacer()
        }.frame(maxWidth: .infinity)
    }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Sign Up Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .fullScreenCover(isPresented: $hasSignedUp) {
                    MainView()
                }
    }

    private func signUp() {
        guard !username.isEmpty && !password.isEmpty && password == confirmPassword else {
            alertMessage = "Please make sure all fields are filled and passwords match."
            showAlert = true
            return
        }

        let passwordData = Data(password.utf8)
        KeychainManager.standard.save(service: "dev.chillvibes.MyndVault", account: username, data: passwordData)

        hasSignedUp = true
    }
}


#Preview {
    SignUpWithPasswordView()
}
