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

    @Environment(\.colorScheme) var colorScheme
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
                    Text("Initial Setup")
                        .foregroundStyle(Color.buttonText)
                        .font(.title2)
                        .padding()
                    Spacer()
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: idealWidth(for: geometry.size.width))
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
                        .frame(maxWidth: idealWidth(for: geometry.size.width))
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
                        .frame(maxWidth: idealWidth(for: geometry.size.width))
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
                       completeSetup()
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
                    .frame(maxWidth: idealWidth(for: geometry.size.width))
                    .padding(.top, 12)
                    .padding(.horizontal)
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
      
        UserDefaults.standard.set(false, forKey: "isFirstLaunch")
        setupComplete = true
    }
}


#Preview {
    InitialSetupView()
}
