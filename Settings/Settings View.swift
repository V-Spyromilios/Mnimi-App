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
    
    var body: some View {
        
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                    HStack {
                        NavigationLink(destination: PromptLanguageView()) { Text("Prompt Language").foregroundStyle(colorScheme == .light ? .black : .white)
                        }
                        Spacer()
                        VStack {
                            Image(systemName: "chevron.right")
                                .padding(.trailing)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background( Color.primaryBackground)
                    .cornerRadius(10)
                    .shadow(color: colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8), radius: 5)
                    .contentShape(Rectangle())
                    
                    HStack {
                        NavigationLink(destination: EmptyView()) {
                            Text("About").foregroundStyle(colorScheme == .light ? .black : .white)
                            Spacer()
                            VStack {
                                Image(systemName: "chevron.right")
                                    .padding(.trailing)
                                    .foregroundStyle(.blue)
                            }
                           
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
                            VStack {
                                Image(systemName: "chevron.right")
                                    .padding(.trailing)
                                    .foregroundStyle(.blue)
                            }
                           
                        }
                    } .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background( Color.primaryBackground)
                        .cornerRadius(10)
                        .shadow(color: colorScheme == .dark ? .white : .black, radius: 5)
                        .contentShape(Rectangle())
                }
                .padding(.top, 15)
                    .padding(.horizontal)
                   
            }
            .background {
                LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: backgroundSpeed, contentMode: .scaleAspectFill)
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
                    Button {
                        withAnimation {
                            animateSettingsPowerOff.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                authManager.logout() }
                        }
                    } label: {
                        
                        
                        LottieRepresentable(filename: "PowerOffButton",speed: 0.8, isPlaying: $animateSettingsPowerOff).frame(width: 45, height: 45).padding(.bottom, 5).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0).opacity(0.8)
                        
                            .accessibilityLabel("Log out.")
                    }
                    
                    Button {
                        withAnimation {
                            showSettings.toggle() }
                    } label: {
                        LottieRepresentable(filename: "CancelButton", loopMode: .loop, speed: 0.8, isPlaying: $animateSettingsButton).frame(width: 45, height: 45).padding(.bottom, 5).shadow(color: colorScheme == .dark ? .white : .clear, radius: colorScheme == .dark ? 4 : 0).opacity(0.8)
                        
                    }
                        .accessibilityLabel("Close Settings")
                    
                }
            }
            
        }
        .statusBar(hidden: true)
    }
}


#Preview {
    SettingsView(showSettings: .constant(true))
}
