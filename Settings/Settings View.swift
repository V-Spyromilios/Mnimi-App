//
//  Settings View.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 10.02.24.
//

import SwiftUI
import CloudKit

struct SettingsView: View {
    
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var cloudKit: CloudKitViewModel
    @EnvironmentObject var pineconeManager: PineconeManager
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var showSettings: Bool
    @State private var errorString = ""
    //    @State private var animateSettingsPowerOff: Bool = false
    @State private var animateSettingsButton: Bool = true
    @State private var canShowSubscription: Bool = true
    @State private var canShowAppSettings: Bool = true
    @State private var showError: Bool = false
    enum AccountButton {
        case idle, hidden
    }
    
    @State private var deleteButton: AccountButton = .idle
    var deleteAllWarningTitle: String = "With great power comes great responsibility"
    var deleteAllWarningBody: String = "Are you sure that you want to Delete all your Info and all your uploaded images?\nThis action is irreversable."
    @State private var showDeleteAll: Bool = false
    
    var body: some View {
        
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                    HStack {
                        NavigationLink(destination: PromptLanguageView()) { Text("Prompt Language").foregroundStyle(colorScheme == .light ? .black : .white)
                        }
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                        
                            .foregroundStyle(.blue)
                        
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background( Color.primaryBackground)
                    .cornerRadius(10)
                    .shadow(color: colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8), radius: 5)
                    .contentShape(Rectangle())
                    
                    HStack {
                        NavigationLink(destination: AboutUsView()) {
                            Text("About").foregroundStyle(colorScheme == .light ? .black : .white)
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                            
                                .foregroundStyle(.blue)
                            
                            
                        }
                    } .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background( Color.primaryBackground)
                        .cornerRadius(10)
                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 5)
                        .contentShape(Rectangle())
                    
                    
                    
                    
                    HStack {
                        NavigationLink(destination: ApiCallsView()) {
                            Text("Credit").foregroundStyle(colorScheme == .light ? .black : .white)
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                            
                                .foregroundStyle(.blue)
                            
                            
                        }
                    } .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background( Color.primaryBackground)
                        .cornerRadius(10)
                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 5)
                        .contentShape(Rectangle())
                    if canShowAppSettings {
                        Button(action: {
                            openAppSettings()
                        }) {
                            HStack {
                                Text("General Settings")
                                    .foregroundColor(colorScheme == .light ? .black : .white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primaryBackground)
                            .cornerRadius(10)
                            .shadow(color: colorScheme == .dark ? .white : .black, radius: 5)
                            .contentShape(Rectangle())
                        }
                    }
                    
                    if canShowSubscription {
                        Button(action: {
                            openSubscriptionManagement()
                        }) {
                            HStack {
                                Text("Manage Subscription")
                                    .foregroundColor(colorScheme == .light ? .black : .white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primaryBackground)
                            .cornerRadius(10)
                            .shadow(color: colorScheme == .dark ? .white : .black, radius: 5)
                            .contentShape(Rectangle())
                        }
                    }
                    
                    Button(action: {
                                        openPrivacyPolicy()
                                    }) {
                                        HStack {
                                            Text("Privacy Policy")
                                                .foregroundColor(colorScheme == .light ? .black : .white)

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.blue)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.primaryBackground)
                                        .cornerRadius(10)
                                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 5)
                                        .contentShape(Rectangle())
                                    }

                    Button(action: {
                        deleteButton = .hidden
                        showDeleteAll.toggle()
                    }) {
                        if deleteButton == .idle {
                            HStack {
                                //
                                Text("Delete Account")
                                    .foregroundColor(.red)
                                Spacer()
                                Image(systemName: "exclamationmark.octagon.fill")
                                    .foregroundColor(.red)
                                
                                
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primaryBackground)
                            .cornerRadius(10)
                            .shadow(color: colorScheme == .dark ? .white : .black, radius: 5)
                            .contentShape(Rectangle())
                            
                        }
                        else {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primaryBackground)
                            .cornerRadius(10)
                            .shadow(color: colorScheme == .dark ? .white : .black, radius: 5)
                            .contentShape(Rectangle())
                        }
                    }.disabled(deleteButton == .hidden)
                }
                .padding(.top, 15)
                .padding(.horizontal)
                if showError {
                    ErrorView(thrownError: errorString)
                    {
                        self.showError = false
                        self.deleteButton = .idle
                    }
                }
            }
            .background {
                LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                    .opacity(0.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            
            .navigationBarTitleView {
                HStack {
                    Text("Settings").font(.title2).bold().foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded).padding(.trailing, 6)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    
                    Button {
                        withAnimation {
                            showSettings.toggle() }
                    } label: {
                        LottieRepresentable(filename: "CancelButton", loopMode: .loop, speed: 0.8, isPlaying: $animateSettingsButton).frame(width: 45, height: 45).padding(.bottom, 5).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0).opacity(0.8)
                    }
                    .accessibilityLabel("Close Settings")
                    .disabled(deleteButton == .hidden)
                }
            }
            .onAppear {
                checkOpeningSubscriptions()
                checkOpeningSettings()
                
            }
            .alert(isPresented: $showDeleteAll) {
                Alert(title: Text(deleteAllWarningTitle), message: Text(deleteAllWarningBody), primaryButton: .cancel(), secondaryButton: .destructive(Text("Delete all"), action: deleteAll)
                )
            }
        }
        .statusBar(hidden: true)
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://polydactyl-drain-3f7.notion.site/MyndVault-Privacy-Policy-3ddf94bced6c4481b1753cac12844f1c?pvs=4") {
            UIApplication.shared.open(url)
        }
    }

    
    
    private func openSubscriptionManagement() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func openAppSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings)
        }
    }
    
    private func deleteAll() {
        Task {
            do {
                deleteNamespaceFromICloud()
                try await pineconeManager.deleteAllVectorsInNamespace()
                removeUserDefaults()
            } catch let error as AppCKError {
               
                await MainActor.run {
                    withAnimation {
                        self.errorString = error.errorDescription
                        self.showError = true
                    }
                }
            } catch let error as AppNetworkError {
               
                await MainActor.run {
                    print("The error: \(error.localizedDescription)")
                    withAnimation {
                        self.errorString = error.errorDescription
                        self.showError = true
                    }
                }
            } catch {
                // General error handling
                print("General error: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorString = error.localizedDescription
                    self.showError = true
                }
            }
        }
        deleteButton = .idle
    }


private func checkOpeningSubscriptions() {
    guard let url = URL(string: "https://apps.apple.com/account/subscriptions"),
          UIApplication.shared.canOpenURL(url)
    else {
        withAnimation { canShowSubscription = false }
        return
    }
}

private func checkOpeningSettings() {
    guard let urlSettings = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(urlSettings)
    else {
        withAnimation { canShowAppSettings = false }
        return
    }
}

private func deleteKeyChain() {
    
    let username = KeychainManager.standard.readUsername()
    if let username = username {
        let success = KeychainManager.standard.delete(service: "dev.chillvibes.MyndVault", account: username)
        if success {
            
        } else {
            print("Failed to delete the account from keychain.")
        }
    } else { print("Unable to get username for deleting KeyChain.") }
}



private func deleteNamespaceFromICloud() {
    // Example usage:
    Task {
        do {
            let container = CKContainer.default()
            let privateDatabase = container.privateCloudDatabase
            let recordIDDelete = KeychainManager.standard.readRecordID(account: "recordIDDelete")
            print("Before Deleting: \(String(describing: recordIDDelete))")
            
            
            try await cloudKit.deleteRecordFromICloud(recordID: recordIDDelete!, from: privateDatabase)
        } catch {
            print("Error deleting record: \(error.localizedDescription)")
        }
    }
}
///Delete all vectors in a Namespace from Pinecone also deletes the namespace itself. Here we delete the namespace from CloudKit
//    private func deleteNamespace() async {
//        Task {
//            do {
//                // Retrieve the first recordID from the fetchedNamespaceDict
//                if let recordID = self.cloudKit.fetchedNamespaceDict.keys.first {
////                    try await self.cloudKit.deleteNamespaceItem(recordID: recordID)
//                    try await cloudKit.deleteAllData(for: "NamespaceItem")
//
//                    // Update the dictionary on the main thread after successful deletion
//                    await MainActor.run {
//                        self.cloudKit.fetchedNamespaceDict.removeValue(forKey: recordID)
//                    }
//                    print("After delete: \(cloudKit.fetchedNamespaceDict)")
//                } else {
//                    print("No namespace item found to delete.")
//                }
//            } catch {
//                print("Error deleting namespace item: \(error.localizedDescription)")
//            }
//        }
//    }

private func removeUserDefaults() {
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: "isFirstLaunch")
    defaults.removeObject(forKey: "monthlyApiCalls")
    defaults.removeObject(forKey: "selectedPromptLanguage")
    defaults.removeObject(forKey: "APITokenUsage")
}

}

#Preview {
    SettingsView(showSettings: .constant(true))
}
