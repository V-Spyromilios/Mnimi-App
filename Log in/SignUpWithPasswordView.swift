//
//  SignUpWithPasswordView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 18.05.24.
//

import SwiftUI
import Security

struct SignUpWithPasswordView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var hasSignedUp = false
    @State private var shake: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.britishRacingGreen.ignoresSafeArea()
                VStack {
                    Text("Mynd Vault 🗃️").font(.largeTitle).fontWeight(.semibold).foregroundStyle(.white).fontDesign(.rounded).padding()
                    Text("Sign-up with Password")
                        .foregroundStyle(colorScheme == .light ? .black : .gray)
                        .font(.title2)
                        .padding()
                    
                    Spacer()
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color.customShadow, radius: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10.0)
                                .stroke(lineWidth: 1)
                                .opacity(0.7)
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
                    
                    SecureField("Confirm Password", text: $confirmPassword)
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
                        signUp()
                    }
                    ) {
                        ZStack {
                            RoundedRectangle(cornerRadius: rectCornerRad)
                                .fill(Color.primaryAccent)
                                .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
                                .frame(height: buttonHeight)
                            
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
                    .padding()
                    Spacer()
                }.frame(maxWidth: .infinity)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Sign Up Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onChange(of: shake) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        shake = false
                    }
                }
            }
            .fullScreenCover(isPresented: $hasSignedUp) {
                MainView()
            }
        }
    }

    private func signUp() {
        
        if shake { return }

        guard !username.isEmpty && !password.isEmpty && password == confirmPassword else {
            
            withAnimation { shake = true }
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
