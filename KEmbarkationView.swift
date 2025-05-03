//
//  KEmbarkationView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 03.05.25.
//

import SwiftUI


struct KEmbarkationView: View {
    var onDone: () -> Void
    @State private var step: EmbarkationStep = .inputExplanation
    
    var body: some View {
        ZStack(alignment: .bottom) {
            KMockedView(for: step)
                .transition(.opacity)
            VStack {
                annotationView(for: step)
                    .transition(.opacity)
                    .padding(.top, 15)
                
                Button(nextButtonTitle) {
                    advanceStep()
                }
                .font(.custom("New York", size: 20))
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
//                .padding(.bottom, 40)
                Spacer()
            }
            
//            VStack {
//                
//                Button(nextButtonTitle) {
//                    advanceStep()
//                }
//                .font(.custom("New York", size: 20))
//                .padding()
//                .background(.ultraThinMaterial)
//                .clipShape(Capsule())
//                .padding(.bottom, 40)
//                Spacer()
//            }
        }
        .animation(.easeInOut, value: step)
    }
    
    private var nextButtonTitle: String {
        step == EmbarkationStep.allCases.last ? "Start Using Kioku" : "Next"
    }
    
    private func advanceStep() {
        if let next = EmbarkationStep(rawValue: step.rawValue + 1) {
            step = next
        } else {
            onDone()
        }
    }
}

#Preview {
    KEmbarkationView(onDone: {})
}

@MainActor
@ViewBuilder
func KMockedView(for step: EmbarkationStep) -> some View {
    let audioRecorder = AudioRecorder()
    switch step {
    case .idleExplanation:
        ZStack(alignment: .bottomTrailing) {
            Image("bg12")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            KRecordButton(recordingURL: .constant(nil), audioRecorder: audioRecorder, micColor: .constant(.white))
                .padding(.bottom, 140)
                .padding(.trailing, 100)
        }
    case .inputExplanation:
        ZStack {
            Image("oldPaper")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            VStack {
                TextEditor(text: .constant("Remind me to call Jane tomorrow"))
                    .font(.custom("New York", size: 20))
                    .frame(height: 150)
                    .padding()
                    .background(.white.opacity(0.7))
                    .cornerRadius(16)
                    .padding(.top, 160)
                    .padding(.horizontal, 30)
                Spacer()
            }
        }
    case .vaultSwipeExplanation:
        ZStack {
            Image("bg12")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            KRecordButton(recordingURL: .constant(nil), audioRecorder: audioRecorder, micColor: .constant(.white))
                .padding(.bottom, 140)
                .padding(.trailing, 20)
            
            // Optional swipe indicator
            HStack {
                Image(systemName: "chevron.right")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .padding(.leading, 20)
                    .opacity(0.8)
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    case .vaultListExplanation:
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(0..<3) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("“License plate is AB123”")
                            .font(.custom("New York", size: 18))
                            .fontWeight(.semibold)
                            .foregroundColor(.black)

                        Text("(Added on Mar 4, 2025)")
                            .font(.custom("New York", size: 14))
                            .italic()
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(.white.opacity(0.8))
                    .cornerRadius(16)
                    .shadow(radius: 2)
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 100)
        }
        .background(
            Image("oldPaper")
                .resizable()
                .scaledToFill()
                .blur(radius: 1)
                .opacity(0.9)
                .ignoresSafeArea()
        )
    case .settingsSwipeExplanation:
        ZStack {
            Image("bg12")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            KRecordButton(recordingURL: .constant(nil), audioRecorder: AudioRecorder(), micColor: .constant(.white))
                .padding(.bottom, 140)
                .padding(.trailing, 20)

            HStack {
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .padding(.trailing, 20)
                    .opacity(0.8)
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
}


@ViewBuilder
func annotationView(for step: EmbarkationStep) -> some View {
    switch step {
    case .idleExplanation:
        annotationBox("This is your starting screen.\nTap and hold the microphone to speak and save:\n– Notes\n– Reminders\n– Calendar events.")
//            .padding(.top, 80)
            .padding()
        
    case .inputExplanation:
        annotationBox("Prefer typing?\nJust tap anywhere on the screen to bring up the keyboard and write instead.")
            .padding(.top, 80)
        
    case .vaultSwipeExplanation:
        annotationBox("Swipe from the left edge to reveal your Vault.\nIt holds everything you've saved.")
            .padding(.top, 80)
        
    case .vaultListExplanation:
        annotationBox("This is your Vault.\nHere you can review, edit, or delete anything you’ve saved.\nJust tap an item to manage it.")
            .padding(.top, 80)
        
    case .settingsSwipeExplanation:
        annotationBox("Swipe from the right edge to open Settings.\nFrom there, you can change preferences — or revisit this tour anytime.")
            .padding(.top, 80)
    }
}

func annotationBox(_ text: String) -> some View {
    Text(text)
        .font(.custom("New York", size: 18))
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal, 30)
        .multilineTextAlignment(.center)
        .foregroundColor(.black)
        .shadow(radius: 4)
}
