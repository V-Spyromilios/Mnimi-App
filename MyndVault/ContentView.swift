//
//  ContentView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 06.04.24.
//

import SwiftUI
//import SwiftData
import Network

struct ContentView: View {
   
    @ObservedObject var networkManager = NetworkManager()
    
    @EnvironmentObject private var keyboardResponder: KeyboardResponder
    @State var keyboardAppeared: Bool = false
    @State var hideKyeboardButton: Bool = false
    @State var tabSelection: Int = 1
    @State var showEditors: Bool = true
    @State var showNetworkError = false
    @EnvironmentObject var speechManager: SpeechRecognizerManager
    
    var body: some View {

        NavigationStack {
           
                TabView(selection: $tabSelection) {
                    
                    //               AskView().keyboardResponsive().tag(1)
                    NewPromptView().tag(1)
                    ToDoView().tag(2)
                    SettingsView().tag(3)
                    
                }
                .overlay(alignment: .bottom) {
                    if !keyboardAppeared {
                        CustomTabBarView(tabSelection: $tabSelection)
                            .transition(.move(edge: .bottom))
                            .edgesIgnoringSafeArea(.bottom)
                            .animation(.easeInOut, value: keyboardAppeared)
                            .padding(.horizontal)
                            .shadow(radius: 8)
                    }
                    else {
                        HStack {
                            Spacer()
                            Button {
                                hideKeyboard()
                            } label: {
                                Image(systemName: "keyboard.chevron.compact.down")
                                    .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)), removal: .opacity))
                                    .animation(.easeInOut(duration: 0.3), value: keyboardAppeared)
                            }
                        }.padding(.trailing,12)
                            .padding(.bottom, 8)
                    }
                }
            
                .onAppear {
                    speechManager.requestSpeechAuthorization()
                    
                }
                .onChange(of: networkManager.hasInternet) { _, hasInternet in
                    if !hasInternet {
                        showNetworkError = true
                    }
                    
                }
                .onChange(of: keyboardResponder.currentHeight) { _, height in
                    
                        keyboardAppeared = height > 0
                    
                    
                    withAnimation(.easeInOut(duration: 0.3).delay(height > 0 ? 0.3 : 0)) {
                        hideKyeboardButton = height > 0
                        }
                }
                .alert(isPresented: $showNetworkError) {
                    Alert(
                        title: Text("No Internet Connection"),
                        message: Text("Please check your internet connection and try again."),
                        dismissButton: .default(Text("OK"))
                    )
                }
        }
    }
}
        
//        .background {
////            Image("AppIcon").resizable().frame(minHeight: 300)
//        }

//        NavigationSplitView {
//            List {
//                ForEach(items) { item in
//                    NavigationLink {
//                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
//                    } label: {
//                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
//                    }
//                }
//                .onDelete(perform: deleteItems)
//            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
//            }
//        } detail: {
//            Text("Select an item")
//        }


//    private func addItem() {
//        withAnimation {
//            let newItem = Item(timestamp: Date())
//            modelContext.insert(newItem)
//        }
//    }
//
//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            for index in offsets {
//                modelContext.delete(items[index])
//            }
//        }
//    }
//}
    

#Preview {
    ContentView()
//        .modelContainer(for: ResponseModel.self, inMemory: true)
}
