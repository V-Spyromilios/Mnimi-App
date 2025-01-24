//
//  TypingTextView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 19.07.24.
//

import SwiftUI
import Combine

@MainActor
struct TypingTextView: View {
    @State private var displayedText: String = ""
    @State private var hasTyped: Bool = false
    let fullText: String
    var typingSpeed: Double = 0.01
    var isTitle: Bool = false
    
    @State private var timerCancellable: AnyCancellable?
    
    var body: some View {
        HStack {
            Text(displayedText)
                .font(Font.custom(isTitle ? "SF Compact Display" : "SF Mono Semibold", size: isTitle ? 29 : 16))
                .fontDesign(isTitle ? .rounded : .monospaced)
                .foregroundStyle(isTitle ? Color.customTiel : .primary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
                .onAppear {
                    if !hasTyped {
                        startTyping()
                    }
                }
            Spacer()
        }.frame(maxWidth: .infinity)
    }
    
    private func startTyping() {
        let characters = Array(fullText)
        var currentIndex = 0
        
        timerCancellable = Timer.publish(every: typingSpeed, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if currentIndex < characters.count {
                    displayedText.append(characters[currentIndex])
                    currentIndex += 1
                } else {
                    timerCancellable?.cancel()
                    hasTyped = true
                }
            }
    }
}

//#Preview {
//    TypingTextView(fullText: "AI did that ?!\nLorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.\nIt has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.")
//}


struct LoadingTransitionView: View {
    
    @Binding var isUpserting: Bool
    @Binding var isSuccess: Bool
    
    var body: some View {
        if #available(iOS 16.0, *) {
            VStack {
                if isUpserting {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.circle")
                        .foregroundStyle(Color.customLightBlue, .blue)
                        .symbolEffect(.rotate, options: .speed(2).repeating)
                        .font(.system(size: 90))
                    
                }
                else if isSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .symbolEffect(.bounce, options: .nonRepeating)
                        .font(.system(size: 90))
                        .foregroundColor(Color.customLightBlue)
                }
            }
        } else { //older than ios16
            VStack {
                if isUpserting {
                    VStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(isUpserting ? .degrees(360) : .degrees(0))
                            .animation(
                                Animation.linear(duration: 0.8).repeatForever(autoreverses: false),
                                value: isUpserting
                            )
                            .font(.system(size: 90))
                            .foregroundColor(.blue)
                        
                    }
                }
                else if isSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .scaleEffect(isUpserting ? 1.0 : 1.2)
                        .animation(
                            Animation.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true),
                            value: !isUpserting
                        )
                        .font(.system(size: 90))
                        .foregroundColor(.green)
                    
                }
                
            }
        }
    }
    
}
#Preview {
    PreviewWrapper()
}

struct PreviewWrapper: View {
    @State private var isUpserting = true
    @State private var isSuccess = false
    @State private var shouldShown = false
    
    var body: some View {
        ZStack {
            LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                .opacity(0.4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            VStack {
                Button(action: {
                    withAnimation {
                        shouldShown.toggle()
                    }
                }) {
                    Text("Show/Hide").font(.title).bold().padding(.bottom)
                }
                
                if shouldShown {
                    VStack {
                        Button(action: {
                            withAnimation {
                                toggle()
                            }
                        }) {
                            Text("Toggle").font(.title).bold().padding(.bottom)
                        }
                        
                        LoadingTransitionView(isUpserting: $isUpserting, isSuccess: $isSuccess)
                            .transition(.asymmetric(insertion: .scale(scale: 0.5).combined(with: .opacity),
                                                    removal: .opacity))
                            .frame(width: 220, height: 220)
                    }
                }
            }
        }
    }
    
    private func toggle() {
        isSuccess.toggle()
        isUpserting.toggle()
    }
}
