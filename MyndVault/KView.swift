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
                if viewState != .input {
                    Image(selectedImage)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .ignoresSafeArea()
                }
                
                ScrollView {
                    VStack {
                        if viewState == .input {
                            InputView(
                                kViewState: $viewState, text: $text,
                                isEditorFocused: _isEditorFocused,
                                geometry: geo
                            )
                            .ignoresSafeArea(.keyboard, edges: .all)
                            .transition(.opacity)
                            .frame(height: geo.size.height)
                        }
                    } .frame(width: geo.size.width, height: geo.size.height)
                    Spacer()
                }
                .ignoresSafeArea()
                .frame(width: geo.size.width)
            }
            .ignoresSafeArea(.keyboard, edges: .all)
            .onAppear {
                selectedImage = imageForToday()
            }
        }
        .ignoresSafeArea()
        .onTapGesture { handleTap() }
        .statusBar(hidden: true)
    }
    
    private func imageForToday() -> String {
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return backgroundImages[dayIndex % backgroundImages.count]
    }
    
    private func handleTap() {
        switch viewState {
        case .idle:  showInputView()
        default:     fromInputToIdle()
        }
    }
    
    private func showInputView() {
        withAnimation(.easeInOut(duration: 0.4)) {
            viewState = .input
        }
        DispatchQueue.main.async {
            isEditorFocused = true
        }
    }
    
    
    func fromInputToIdle() {
        isEditorFocused = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { //    If you prefer the keyboard to finish before the overlay starts fading
            withAnimation(.easeInOut(duration: 0.4)) {
                viewState = .idle
            }
        }
    }
}


// MARK: - InputView

struct InputView: View {
    @Binding var kViewState: KView.ViewState   // we pass down the parent's state
    @Binding var text: String
    @FocusState var isEditorFocused: Bool
    var geometry: GeometryProxy
    
    var body: some View {
        
        ZStack(alignment: .top) {
            Image("oldPaper")
                       .resizable()
                       .scaledToFill()
                       .frame(maxWidth: .infinity, maxHeight: .infinity)
                       .clipped()
                       .opacity(0.9)
                       .blur(radius: 1)
                       .ignoresSafeArea(.keyboard, edges: .bottom)
        VStack {
            TextEditor(text: $text)
                .focused($isEditorFocused)
                .font(.custom("New York", size: 20))
                .foregroundColor(.black)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .multilineTextAlignment(.leading)
                .padding()
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
                .underline()
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
                
            case .onSuccess:
                Button("Done") {
                    withAnimation {
                        text = ""
                    }
                    isEditorFocused = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { //    If you prefer the keyboard to finish before the overlay starts fading
                        withAnimation(.easeInOut(duration: 0.4)) {
                            kViewState = .idle
                        }
                    }
                }
                .font(.headline)
                .underline()
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
                
            case .input:
                // Normal “Save” button
                Button("Save"){
                    print("Saving...")
                    withAnimation {
                        kViewState = .onApiCall
                    }
                }
                .font(.custom("New York", size: 22))
                .bold()
                .foregroundColor(.black)
                .padding(.top, 20)
                .transition(.opacity)
            default:
                EmptyView()
            }
        }
        .padding(.top, 15)
    }
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
