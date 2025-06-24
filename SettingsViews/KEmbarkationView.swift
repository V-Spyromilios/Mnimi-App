//
//  KEmbarkationView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 03.05.25.
//

import SwiftUI
import AVFoundation
import EventKit


struct KEmbarkationView: View {
    @EnvironmentObject var audioRecorder: AudioRecorder
    var onDone: () -> Void
    @State private var animateSwipe: Bool = false
    @State private var animateSwap2: Bool = false
    @State private var step: EmbarkationStep = .welcomeIntro
    @AppStorage("calendarPermissionGranted") var calendarPermissionGranted: Bool = false
    @AppStorage("reminderPermissionGranted") var reminderPermissionGranted: Bool = false
    @AppStorage("microphonePermissionGranted") var microphonePermissionGranted: Bool = false
    
    @State private var pulse: Bool = false //for demo the mic explanation
    
    let isDemo: Bool
    
    var body: some View {
        ZStack(alignment: .bottom) {
            KMockedView(for: step, animateSwap: $animateSwipe, animateSwap2: $animateSwap2, pulse: $pulse)
                .transition(.opacity)
            VStack {
                if step.annotationAlignment == .top {
                    annotationText(for: step)
                        .padding(.top, step.annotationPadding)
                    Spacer()
                    nextButton
                } else {
                    Spacer()
                    annotationText(for: step)
                        .padding(.bottom, step.annotationPadding)
                    nextButton
                        .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
        }
        .animation(.easeInOut, value: step)
    }
    
    private var nextButton: some View {
        Group {
            if step == .requestPermissions && !isDemo {
                permissionsButton
            } else {
                Button(nextButtonTitle) {
                    advanceStep()
                }
                .font(.custom(NewYorkFont.italic.rawValue, size: 22))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .foregroundColor(.black)
                .kiokuShadow()
            }
        }
    }
    
     var nextButtonTitle: String {
        step == EmbarkationStep.allCases.last ? "Start Using Mnimi" : "Next"
    }
    
    //TODO: UPDATE check that works correctly, should skip the permissions inDemo mode.
    func advanceStep() {
        var nextRawValue = step.rawValue + 1

        // If the next step would be `.requestPermissions`, and we're in demo mode, skip it
        if isDemo, EmbarkationStep(rawValue: nextRawValue) == .requestPermissions {
            nextRawValue += 1
        }

        // Try to get the next step. Fails for .permissions + 1 in demo mode
        if let next = EmbarkationStep(rawValue: nextRawValue) {
            step = next
        } else {
            onDone()
        }
    }
    
    @MainActor
    private var permissionsButton: some View {
        Button("Grant Permissions") {
            
            Task { @MainActor in
                
                let micGranted = await audioRecorder.requestPermission()
                let calendarGranted = await requestCalendarPermission()
                let reminderGranted = await requestReminderPermission()
                
                await MainActor.run {
                    calendarPermissionGranted = calendarGranted
                    reminderPermissionGranted = reminderGranted
                    microphonePermissionGranted = micGranted
                }
                
                advanceStep()
            }
        }
        .font(.custom("New York", size: 20))
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .foregroundColor(.black)
        .kiokuShadow()
    }

    @MainActor
    private func requestCalendarPermission() async -> Bool {
        let store = EKEventStore()
        do {
            // EventKit resumes on arbitrary queue → hop back before returning
            let granted = try await store.requestFullAccessToEvents()
            await MainActor.run {}
            return granted
        } catch { return false }
    }

    @MainActor
    private func requestReminderPermission() async -> Bool {
        let store = EKEventStore()
        do {
            let granted = try await store.requestFullAccessToReminders()
            await MainActor.run {}
            return granted
        } catch { return false }
    }
    
}

#Preview {
    KEmbarkationView(onDone: {}, isDemo: false)
}

@MainActor
@ViewBuilder
func KMockedView(for step: EmbarkationStep, animateSwap: Binding<Bool>, animateSwap2: Binding<Bool>, pulse: Binding<Bool>) -> some View {
    let audioRecorder = AudioRecorder()
    switch step {
    case .idleExplanation:
        ZStack(alignment: .bottomTrailing) {
            Image("bg10")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            KRecordButton(recordingURL: .constant(nil), audioRecorder: audioRecorder, micColor: .constant(.white))
                .padding(.bottom, 140)
                .padding(.trailing, 100)
                .disabled(true)
        }
    case .micExplanation:
        ZStack(alignment: .bottomTrailing) {
            Image("bg10")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Animate waveform icon to simulate recording
            Image(systemName: "waveform.badge.microphone")
                .font(.system(size: 58))
                .foregroundColor(.white.opacity(pulse.wrappedValue ? 1.0 : 0.7))
                .scaleEffect(pulse.wrappedValue ? 1.1 : 0.95)
                .symbolEffect(.variableColor)
                .shadow(radius: 10)
                .padding(.bottom, 140)
                .padding(.trailing, 100)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                    ) {
                        pulse.wrappedValue = true
                    }
                }
        }
    case .inputExplanation: //Keep it for question
        ZStack {
            KiokuBackgroundView()
            VStack {
                Text("What was the proposed title of my thesis?")
                    .font(.custom("New York", size: 20))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundStyle(.black)
                    .lineSpacing(7)
                    .padding(.top, 40)
                    .padding(.leading, 30)
                    .frame(height: 150)
                saveButton
                Spacer()
            }.frame(width: UIScreen.main.bounds.width)
        }
    case .inputExplanationRemindersCalendar:
        ZStack {
            KiokuBackgroundView()
            VStack {
                Text("Add to my Calendar: Rust meetup in Berlin next Thursday at 19:00")
                    .font(.custom("New York", size: 20))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundStyle(.black)
                    .lineSpacing(7)
                    .padding(.top, 40)
                    .padding(.leading, 30)
                    .frame(height: 150)
                saveButton
                Spacer()
            }.frame(width: UIScreen.main.bounds.width)
        }
    case .vaultSwipeExplanation:
        ZStack(alignment: .bottomTrailing) {
            Image("bg10")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            KRecordButton(recordingURL: .constant(nil), audioRecorder: audioRecorder, micColor: .constant(.white))
                .padding(.bottom, 140)
                .padding(.trailing, 100)
                .disabled(true)
        }
        
        HStack {
            Image(systemName: "chevron.right")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .offset(x: animateSwap.wrappedValue ? 13 : -5)
                .opacity(animateSwap.wrappedValue ? 1.0: 0.7)
                .scaleEffect(animateSwap.wrappedValue ? 1.1 : 1.0)
                .padding(.leading, 20)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 0.9)
                        .repeatForever(autoreverses: true)
                    ) {
                        animateSwap.wrappedValue = true
                    }
                }
            
            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .frame(width: UIScreen.main.bounds.width)
        
    case .vaultListExplanation:
        ZStack {
            KiokuBackgroundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(demoVectors) { vector in
                        sampleContentView(data: vector)
                            .padding(.horizontal)
                    }
                    
                }.padding(.top, 50)
                    .frame(maxHeight: .infinity, alignment: .leading)
                    .frame(width: UIScreen.main.bounds.width)
                    .clipped()
                
            }
        }
        
    case .settingsSwipeExplanation:
        ZStack(alignment: .bottomTrailing) {
            Image("bg10")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .frame(width: UIScreen.main.bounds.width)
            
            KRecordButton(recordingURL: .constant(nil), audioRecorder: AudioRecorder(), micColor: .constant(.white))
                .padding(.bottom, 140)
            
                .padding()
            
            HStack {
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.trailing, 20)
                    .offset(x: animateSwap2.wrappedValue ? -5 : 13)
                    .opacity(animateSwap2.wrappedValue ? 1.0: 0.7)
                    .scaleEffect(animateSwap2.wrappedValue ? 1.1 : 1.0)
                
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.9)
                    .repeatForever(autoreverses: true)
                ) {
                    animateSwap2.wrappedValue = true
                }
            }
            
        }
    case .welcomeIntro:
        ZStack {
            KiokuBackgroundView()
            
            Text("Mnimi helps you remember anything.\nSpeak or type, and Mnimi will store your notes, reminders, or calendar events.")
                .font(.custom(NewYorkFont.italic.rawValue, size: 19))
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .lineSpacing(8)
                .kiokuShadow()
                .padding(.horizontal, 30)
            
        }
    case .requestPermissions:
        ZStack {
            KiokuBackgroundView()
            
            Text("""
    One last thing!
    
    Mnimi needs permission to access your microphone, Calendar, and Reminders.

    This allows you to use voice input to create notes, ask questions, and add calendar events or reminders.
    """)
            .font(.custom(NewYorkFont.italic.rawValue, size: 19))
            .multilineTextAlignment(.center)
            .foregroundColor(.black)
            .kiokuShadow()
            .padding(.horizontal, 30)
            
        }
    }
}

@MainActor
private var saveButton: some View {
    Button("Go") {
        //Just sample for the Embarkation
    }
    .buttonStyle(.plain)
    .underline()
    .font(.custom("New York", size: 22))
    .bold()
    .foregroundColor(.black)
    .padding(.top, 20)
    .transition(.opacity)
}




@MainActor
private func sampleContentView(data: Vector) -> some View {
    
    VStack(alignment: .leading, spacing: 15) {
        let note = data.metadata["description"] ?? "Empty note."
        let dateText = dateFromISO8601(isoDate: data.metadata["timestamp"] ?? "").map { formatDateForDisplay(date: $0) } ?? ""
        
        VStack(alignment: .leading, spacing: 8) {
            Text("\"\(note)\"")
                .font(.custom("New York", size: 18))
                .fontWeight(.semibold)
                .lineSpacing(5)
                .multilineTextAlignment(.leading)
                .foregroundColor(.black)
            
            Text("(\(dateText))")
                .font(.custom("New York", size: 14))
                .italic()
                .foregroundColor(.black.opacity(0.8))
        }
        .multilineTextAlignment(.leading)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    
    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    .drawingGroup()
}

private var demoVectors: [Vector] {
    let formatter = ISO8601DateFormatter()
    let now = Date()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return [
        Vector(
            id: UUID().uuidString,
            metadata: [
                "description": "Dieses Buch von Marco Polo ist gut, um es vor der Reise nach Griechenland zu huben.",
                "timestamp": formatter.string(from: now.addingTimeInterval(-86400 * 1))
            ]
        ),
        Vector(
            id: UUID().uuidString,
            metadata: [
                "description": "Idea for the next app: microservices with Rust and grpc on private cloud - focus on ios and visionOS",
                "timestamp": formatter.string(from: now.addingTimeInterval(+86500 * 3)) // 3 days ago
            ]
        ),
        
        Vector(
            id: UUID().uuidString,
            metadata: [
                "description": "My research paper can be on late 1800s Athens, perhaps: 'The Evolution of small retailers and urbanisation'",
                "timestamp": formatter.string(from: now.addingTimeInterval(+86500 * 3)) // 3 days ago
            ]
        ),
        Vector(
            id: UUID().uuidString,
            metadata: [
                "description": "the cafe of the art museum is open Tuesday to Sunday 11:00 - 18:00.",
                "timestamp": formatter.string(from: now.addingTimeInterval(+86400 * 5)) // 5 days ago
            ]
        ),
        Vector(
            id: UUID().uuidString,
            metadata: [
                "description": "Sofia likes hats and tops with puppies!",
                "timestamp": formatter.string(from: now.addingTimeInterval(-86400 * 1))
            ]
        ),
        Vector(
            id: UUID().uuidString,
            metadata: [
                "description": "Το ντοκιμαντέρ για την Αθήνα να ξεκινά με αφήγηση απο το παλιό Πανεπιστημίο στην Πλάκα!",
                "timestamp": formatter.string(from: now.addingTimeInterval(-86400 * 1))
            ]
        )
    ]
}


@MainActor
@ViewBuilder
func annotationText(for step: EmbarkationStep) -> some View {
    switch step {
    case .idleExplanation:
        annotationBox {
            Text("""
            This is your starting screen.

            Press and hold the microphone to speak and save notes, reminders, or calendar events.

            Prefer typing? Just tap anywhere to bring up the input view.
            """)
            .font(.custom(NewYorkFont.regular.rawValue, size: 18))
        }

    case .inputExplanation:
        annotationBox {
            Text("""
            Ask Mnimi questions like: “What did I save about my thesis?”

            Mnimi remembers everything you've entered and will try to answer it for you.
            """)
            .font(.custom(NewYorkFont.regular.rawValue, size: 18))
        }

    case .vaultSwipeExplanation:
        annotationBox {
            Text("Swipe left to open your Vault — everything you’ve saved lives there.")
                .font(.custom(NewYorkFont.regular.rawValue, size: 18))
        }

    case .vaultListExplanation:
        annotationBox {
            Text("""
            This is your Vault.

            Here you can review, edit, or delete anything you’ve saved.
            Just tap an item to manage it.
            """)
            .font(.custom(NewYorkFont.regular.rawValue, size: 18))
        }

    case .settingsSwipeExplanation:
        annotationBox {
            Text("Swipe right to open Settings and revisit this tour.")
                .font(.custom(NewYorkFont.regular.rawValue, size: 18))
        }

    case .welcomeIntro:
        annotationBox {
            Text("Welcome to Mnimi. \n\n")
                .font(.custom(NewYorkFont.heavy.rawValue, size: 22))
            +
            Text("Your second brain: just speak or type to save anything you want to remember — and Mnimi will help you recall it later.")
                .font(.custom(NewYorkFont.regular.rawValue, size: 18))
        }

    case .requestPermissions:
        EmptyView()

    case .inputExplanationRemindersCalendar:
        annotationBox {
            Text("""
            Add a Reminder or Calendar Event by speaking or typing.

            You can say or write things like:
            “Remind me to call Alex tomorrow at 10.”
            or
            “Add to my Calendar: The museum holds a photo exhibition on Saturday at 3 PM.”

            Mnimi will understand and help you save it.
            """)
            .font(.custom(NewYorkFont.regular.rawValue, size: 18))
        }

    case .micExplanation:
        annotationBox {
            Text("""
            Press and hold the mic to record your thoughts or add reminders and calendar events.

            Mnimi will transcribe your voice and save it instantly.

            (Microphone access is required for this to work.)
            """)
            .font(.custom(NewYorkFont.regular.rawValue, size: 18))
        }
    }
}

@MainActor
func annotationBox<Content: View>(_ content: @escaping () -> Content) -> some View {
    content()
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal, 30)
        .multilineTextAlignment(.center)
        .foregroundColor(.black)
        .frame(width: UIScreen.main.bounds.width - 10)
        .kiokuShadow()
}
