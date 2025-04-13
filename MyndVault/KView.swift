//
//  KView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 12.04.25.
//

import SwiftUI

struct KView: View {
    enum ViewState: Equatable {
        case idle
        case input
        case onApiCall
        case onSuccess
        case onError(String)
    }

    @State private var viewState: ViewState = .idle
    @State private var selectedImage: String = ""
    @State private var text: String = ""
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // 1) Shared background
                if viewState == .idle {
                    Image(selectedImage)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .ignoresSafeArea()
                } else {
                    Image("oldPaper")
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .ignoresSafeArea()
                        .opacity(0.9)
                        .blur(radius: 1)
                }

                ScrollView {
                    // 2) Switch the displayed child view
                    VStack {
                        if viewState == .idle {
                            IdleView()
                                .transition(.opacity)
                        } else {
                            ZStack {
                                InputView(
                                    kViewState: $viewState, text: $text,
                                    isEditorFocused: _isEditorFocused,
                                    geometry: geo
                                )
                                .transition(.opacity)
                            }
                        }
                    }
                    .ignoresSafeArea()
                    .frame(width: geo.size.width)
                    .animation(.easeInOut(duration: 0.6), value: viewState)
                }
                .ignoresSafeArea(.keyboard, edges: .all)
                .onAppear {
                    selectedImage = imageForToday()
                }
            }
        }
        .onTapGesture {
            // Toggle the child view
            withAnimation(.easeInOut(duration: 0.6)) {
                switch viewState {
                case .idle:
                    viewState = .input
                    isEditorFocused = true
                case .input, .onApiCall, .onError, .onSuccess:
                    viewState = .idle
                    isEditorFocused = false
                }
            }
        }
    }

    private func imageForToday() -> String {
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return backgroundImages[dayIndex % backgroundImages.count]
    }
}

// MARK: - IdleView

struct IdleView: View {
    var body: some View {
        VStack {
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

// MARK: - InputView

struct InputView: View {
    @Binding var kViewState: KView.ViewState   // we pass down the parent's state
    @Binding var text: String
    @FocusState var isEditorFocused: Bool
    var geometry: GeometryProxy
    
    var body: some View {
        
        VStack(alignment: .center) {
            TextEditor(text: $text)
                .focused($isEditorFocused)
                .font(.custom("New York", size: 18))
                .foregroundColor(.primary)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 20)
                .frame(width: geometry.size.width, height: 200)
            
            switch kViewState {
            case .onApiCall:
                // "Saving..." label (disabled button or no button)
                Text("Saving...")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                
            case .onError(let errorMessage):
                VStack {
                    Text(errorMessage)
                        .foregroundColor(.red)
                    Button("Retry") {
                        withAnimation {
                            kViewState = .input
                        }
                    }
                }
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
                
            case .onSuccess:
                Button("Done") {
                    withAnimation {
                        text = ""
                        kViewState = .input
                    }
                }
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
                
            case .input:
                // Normal “Save” button
                Button("Save") {
                    print("Saving...")
                    withAnimation {
                        kViewState = .onApiCall
                    }
                }
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 20)
                .transition(.opacity)
            default:
                EmptyView()
            }
        }
        .padding()
        
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
