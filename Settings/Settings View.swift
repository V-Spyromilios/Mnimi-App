//
//  Settings View.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 10.02.24.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var cloudKit: CloudKitViewModel
    @Environment(\.colorScheme) var colorScheme

    @Binding var showSettings: Bool
    @State private var errorString = ""
    @State private var animateSettingsPowerOff: Bool = false
    @State private var animateSettingsButton: Bool = true
    @State private var canShowSubscription: Bool = true
    @State private var canShowAppSettings: Bool = true
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
//                    LottieRepresentable(filename: "").frame(width: 55, height: 55).padding(.bottom, 5).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
//                    Button {
//                        withAnimation {
//                            animateSettingsPowerOff.toggle()
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                                authManager.logout() }
//                        }
//                    } label: {
//                        
//                        
//                        LottieRepresentable(filename: "PowerOffButton",speed: 0.8, isPlaying: $animateSettingsPowerOff).frame(width: 45, height: 45).padding(.bottom, 5).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0).opacity(0.8)
//                        
//                            .accessibilityLabel("Log out.")
//                    }
                    
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
                guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else {
                    return
                }
                if UIApplication.shared.canOpenURL(url) {
                    canShowSubscription = true
                }
                else {
                    withAnimation { canShowSubscription = false }
                }
                guard let urlSettings = URL(string: UIApplication.openSettingsURLString) else { return }
                if UIApplication.shared.canOpenURL(urlSettings) {
                    canShowAppSettings = true
                }
                else {
                    withAnimation{ canShowAppSettings = false }
                }
                
            }
            .alert(isPresented: $showDeleteAll) {
                Alert(title: Text(deleteAllWarningTitle), message: Text(deleteAllWarningBody), primaryButton: .cancel(), secondaryButton: .destructive(Text("Delete all"), action: deleteAll)
                )
            }
            
        }
        .statusBar(hidden: true)
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
        
    }
}


#Preview {
    SettingsView(showSettings: .constant(true))
}
