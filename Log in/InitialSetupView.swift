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
