//
//  KView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 12.04.25.
//

import SwiftUI

struct KView: View {
    @State private var selectedImage: String = ""
    @State private var text: String = ""
    @FocusState private var isEditorFocused: Bool
    
    var body: some View {
        ZStack {
            // 1. Background image
            Image(selectedImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .blur(radius: 0.5)
            
            // 2. FAFAFA veil
            if isEditorFocused {
                Image("oldPaper")
                    .resizable()
                    .scaledToFill()
                    .opacity(isEditorFocused ? 0.92 : 0)
                    .blur(radius: 1)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.6), value: isEditorFocused)
                
            }
            // 3. Content
            VStack {
                if !isEditorFocused {
                    Text("Kioku")
                        .fontDesign(.rounded)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.top, 24)
                }
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .focused($isEditorFocused)
                        .font(.custom("New York", size: 18))
                        .foregroundColor(.primary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    
                    if text.isEmpty && !isEditorFocused {
                        HStack {
                            Text("Your memory starts here...")
                                .font(.custom("New York", size: 18))
                                .foregroundColor(.secondary)
//                                .padding(.horizontal, 20) // slightly more than TextEditor to match
                                .padding(.top, 16)        // align visually with first line
                                
//                            Spacer()
                        }
                    }
                }.frame(width: 400)
                .frame(maxHeight: .infinity)
                
                if isEditorFocused {
                    Button("Save") {
                        // Save logic
                    }
                    .font(.custom("New York", size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.top, 16)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.6), value: isEditorFocused)
                }
                Spacer()
            }
        }
        .onAppear {
            selectedImage = imageForToday()
        }
        .scrollDismissesKeyboard(.interactively) // optional
        .ignoresSafeArea(.keyboard) // prevents view from jumping
        
    }
    private func imageForToday() -> String {
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return backgroundImages[dayIndex % backgroundImages.count]
    }
}

let backgroundImages = [
    "bg1", "bg2", "bg3", "bg4", "bg5",
    "bg6", "bg7", "bg8", "bg9", "bg10",
    "bg11", "bg12", "bg13", "bg14", "bg15",
    "bg16", "bg17", "bg18", "bg19", "bg20",
    "bg21", "bg22", "bg23", "bg24", "bg25",
    "bg26", "bg27", "bg28", "bg29", "bg30",
    "bg31"
]


#Preview {
    KView()
}
