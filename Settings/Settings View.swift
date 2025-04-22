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
    @EnvironmentObject var pineconeManager: PineconeViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var showSettings: Bool
    @State private var errorString = ""
    //    @State private var animateSettingsPowerOff: Bool = false
    @State private var animateSettingsButton: Bool = true
    @State private var canShowSubscription: Bool = true
    @State private var canShowAppSettings: Bool = true
    @State private var showError: Bool = false
    @State private var isKeychainDeleted: Bool = false
    @State private var showDeleteAll: Bool = false
    @State private var showAccountDeleted: Bool = false
    enum AccountButton {
        case idle, hidden
    }
    
    @State private var deleteButton: AccountButton = .idle
    var deleteAllWarningTitle: String = "With great power comes great responsibility"
    var deleteAllWarningBody: String = "Are you sure that you want to Delete all your Info and all your uploaded images?\nThis action is irreversable."
    
    
    var body: some View {
        
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                    
                    
                    
                    
                    //MARK: Language
                    NavigationLink(destination: PromptLanguageView()) {
                        HStack {
                            Text("Prompt Language")
                                .foregroundStyle(colorScheme == .light ? .black : .white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.blue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black)
                        .cornerRadius(10)
                        .shadow(color: colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8), radius: 5)
                        .contentShape(Rectangle()) // Ensures the entire rectangle is tappable
                    }
                    
                    //MARK: About
                    HStack {
                        NavigationLink(destination: AboutUsView()) {
                            Text("About").foregroundStyle(colorScheme == .light ? .black : .white)
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.blue)
                        }
                    } .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background( Color.white)
                        .cornerRadius(10)
                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 5)
                        .contentShape(Rectangle())
                    
                    //MARK: Open App Settings
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
                            .background(Color.black)
                            .cornerRadius(10)
                            .shadow(color: colorScheme == .dark ? .white : .black, radius: 5)
                            .contentShape(Rectangle())
                        }
                    }
                    
                    //MARK: Open Subscription
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
                            .background(Color.black)
                            .cornerRadius(10)
                            .shadow(color: colorScheme == .dark ? .white : .black, radius: 5)
                            .contentShape(Rectangle())
                        }
                    }
                    
                    //MARK: Open Privacy Policy
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
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 5)
                        .contentShape(Rectangle())
                    }
                    
                    
                    //MARK: Terms of Use
                    Button(action: {
                        eula()
                    }) {
                        HStack {
                            Text("Terms of Use")
                                .foregroundColor(colorScheme == .light ? .black : .white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 5)
                        .contentShape(Rectangle())
                    }
                    
                    //MARK: Open Support request
                    Button(action: {
                        openSupportRequest()
                    }) {
                        HStack {
                            Text("Support Request")
                                .foregroundColor(colorScheme == .light ? .black : .white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red)
                        .cornerRadius(10)
                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 5)
                        .contentShape(Rectangle())
                    }
                    
                    
                    //MARK: Delete Account
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
                            .background(Color.red)
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
                            .background(Color.red)
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
            .fullScreenCover(isPresented: $showAccountDeleted) {
                AccountDeletedView()
            }
            
            .navigationBarTitleView {
                HStack {
                    Text("Settings").font(.headline).bold().foregroundStyle(.blue.opacity(0.8)).fontDesign(.rounded)
                        .minimumScaleFactor(0.8)
                        .lineLimit(2)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    
                    Button {
                        withAnimation {
                            showSettings.toggle() }
                    } label: {
                        //                        LottieRepresentable(filename: "CancelButton", loopMode: .loop, speed: 0.8, isPlaying: $animateSettingsButton)
                        Image(systemName: "xmark.circle")
                            .frame(width: 45, height: 45).padding(.bottom, 5).opacity(0.8)
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
                Alert(title: Text(deleteAllWarningTitle), message: Text(deleteAllWarningBody), primaryButton: .cancel(Text("Cancel"), action: cancelDelete), secondaryButton: .destructive(Text("Delete all"), action: deleteAll)
                )
            }
            .onChange(of: showDeleteAll) { _, newValue in
                if newValue {
                    let haptic = UINotificationFeedbackGenerator()
                    haptic.notificationOccurred(.warning)
                }
            }
        }
        .onChange(of: pineconeManager.pineconeErrorOnDel) { _, newValue in
            if let pineconeErrorOnDel = newValue {
                self.errorString = pineconeErrorOnDel.localizedDescription
                self.showError = true
            }
        }
        .onChange(of: cloudKit.CKErrorDesc) { _, newValue in
            if !newValue.isEmpty {
                self.errorString = newValue
                self.showError = true
            }
        }
//        .statusBar(hidden: true)
    }
    
    private func cancelDelete() {
        if deleteButton == .hidden {
            withAnimation { deleteButton = .idle }
        }
        if showDeleteAll {
            withAnimation { showDeleteAll = false }
        }
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://polydactyl-drain-3f7.notion.site/MyndVault-Privacy-Policy-3ddf94bced6c4481b1753cac12844f1c?pvs=4") {
            UIApplication.shared.open(url)
        }
    }
    
    private func eula() {
        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openSupportRequest() {
        if let url = URL(string: "https://polydactyl-drain-3f7.notion.site/MyndVault-d74ca5df50374eada3193a64c1cee7dc?pvs=4") {
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
    
    //MARK: DeleteAll
    private func deleteAll() {
        Task {
            await deleteNamespaceFromICloud()
            await pineconeManager.deleteAllVectorsInNamespace()
            await cloudKit.deleteAllImageItems()
            removeUserDefaults()
            deleteKeyChain()
            deleteButton = .idle
        }
        deleteButton = .idle
        showAccountDeleted = true
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
    
    
    //TODO: Proper error handling!
    
    func deleteKeyChain() {
        
        var keychainDeleteRetryCount = 0
        let keychainDeletemaxRetries = 3
        
        guard let username = KeychainManager.standard.readUsername() else {
            debugLog("deleteKeyChain::No username found in keychain.")
            isKeychainDeleted = false
            return
        }
        
        let success = KeychainManager.standard.delete(service: "dev.chillvibes.MyndVault", account: username)
        
        if success {
            debugLog("Successfully deleted keychain for username: \(username)")
            isKeychainDeleted = true
        } else {
            debugLog("deleteKeyChain::Failed to delete keychain.")
            isKeychainDeleted = false
            
            if keychainDeleteRetryCount < keychainDeletemaxRetries {
                keychainDeleteRetryCount += 1
                debugLog("Retrying deletion... Attempt \(keychainDeleteRetryCount)")
                deleteKeyChain()
            }
        }
    }
    
    private func deleteNamespaceFromICloud() async {

//            do {
                let container = CKContainer.default()
                let privateDatabase = container.privateCloudDatabase
                guard let recordIDDelete = KeychainManager.standard.readRecordID(account: "recordIDDelete") else {
                    self.errorString = "Could not retrieve recordID from keychain."
                    self.showError.toggle()
                    return
                }
                debugLog("Before Deleting: \(String(describing: recordIDDelete))")
                
                await cloudKit.deleteRecordFromICloud(recordID: recordIDDelete, from: privateDatabase)
//            } catch {
//                debugLog("Error deleting record: \(error.localizedDescription)")
//                self.errorString = "Unable to Delete record from iCloud."
//                self.showError = true
//            }
        
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
