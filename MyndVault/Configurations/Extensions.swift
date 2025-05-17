//
//  Extensions.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 01.03.24.
//

import Foundation
import SwiftUI
import UIKit
import Combine
import EventKit

@MainActor
struct Constants {
    
//    static let assemblyCode = """
//section .data
//    message db 'LOGIN', 0
//
//section .bss
//    len resb 1
//
//section .text
//    global _start
//
//_start:
//    mov ecx, message
//    mov ebx, 0
//get_len:
//    cmp byte [ecx + ebx], 0
//    je done
//    inc ebx
//    jmp get_len
//done:
//    mov [len], ebx
//    mov eax, 4
//    mov ebx, 1
//    mov ecx, message
//    mov edx, [len]
//    int 0x80
//    mov eax, 1
//    xor ebx, ebx
//    int 0x80
//""".trimmingCharacters(in: .whitespacesAndNewlines)
    
    
//    static let rectCornerRad: CGFloat = 50
//    
//    static let textEditorHeight: CGFloat = 140
//    
//    static let smallTextEditorHeight: CGFloat = 50
//    
//    static let contentUnaivalableOffset: CGFloat = 40
//    
//    static let buttonHeight: CGFloat = 50
//    
//    static let backgroundSpeed: CGFloat = 0.4
//    
//    static let standardCardPadding: CGFloat = 16
//    
//    static let showLangDuration: CGFloat = 4.5
    
    static let entitlementID: String = "manager"
}


//extension String {
//    func deletingPrefix(_ prefix: String) -> String {
//        guard self.hasPrefix(prefix) else { return self }
//        return String(self.dropFirst(prefix.count))
//    }
//
//    func deletingSuffix(_ suffix: String) -> String {
//        guard self.hasSuffix(suffix) else { return self }
//        return String(self.dropLast(suffix.count))
//    }
//}


//extension View {
//    @MainActor
//    func hideKeyboard() {
//        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//    }
//    @MainActor
//    func navigationBarTitleView<Content: View>(_ content: @escaping () -> Content) -> some View {
//        self.navigationBarItems(leading: content())
//    }
//    
//    
//}

func userDefaultsKeyExists(_ key: String) async -> Bool {
    // running only in a background task
    return await Task(priority: .background) {
        return UserDefaults.standard.object(forKey: key) != nil
    }.value // Task returns 'Task<Bool, never>'
}

//func idealWidth(for availableWidth: CGFloat) -> CGFloat {
//    
//    if availableWidth < 800 {
//        return availableWidth
//    } else {
//        
//        return availableWidth * 0.6
//    }
//}


@MainActor
//final class KeyboardResponder: ObservableObject {
//    
//    @Published var currentHeight: CGFloat = 0
//    private var keyboardVisible = false
//    
//    private var cancellables = Set<AnyCancellable>()
//    
//    init() {
//        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
//            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue }
//            .map { $0.cgRectValue.height }
//            .receive(on: RunLoop.main)
//            .sink { [weak self] height in
//                self?.currentHeight = height
//                self?.keyboardVisible = true
//            }
//            .store(in: &cancellables)
//        
//        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
//            .receive(on: RunLoop.main)
//            .sink { [weak self] _ in
//                withAnimation(.easeInOut) {
//                    self?.currentHeight = 0
//                    self?.keyboardVisible = false
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
//    @objc func keyboardWillShow(notification: Notification) {
//        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
//            let keyboardHeight = keyboardFrame.cgRectValue.height
//            self.currentHeight = keyboardHeight
//            self.keyboardVisible = true
//            
//        }
//    }
//    
//    @objc func keyboardWillHide(notification: Notification) {
//        // no ' DispatchQueue.main.async {' as class marked @MainActor
//        withAnimation(.easeInOut) {
//            self.currentHeight = 0
//            self.keyboardVisible = false
//        }
//    }
//}

// MARK: from ISO8601 to displayed date and time. I use ISO8601 to convert Date() to string for pinecone's timestamp:String.


func dateFromISO8601(isoDate: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: isoDate)
}


func formatDateForDisplay(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone(identifier: TimeZone.current.identifier)
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .short
    return dateFormatter.string(from: date)
}

func currentDateToISO8601() -> String {
    let isoDateFormatter = ISO8601DateFormatter()
    isoDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let timestamp = isoDateFormatter.string(from: Date())
    return timestamp
}

func toDictionary(desc: String) -> [String: String] {
    return [
        "description": desc,
        "timestamp": currentDateToISO8601()
    ]
}

extension View {
    func kiokuShadow() -> some View {
        self.shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

func localizedBrightness(of image: UIImage, relativeRect: CGRect) -> CGFloat {
    guard let cgImage = image.cgImage else { return 1.0 }
    
    let context = CIContext()
    let ciImage = CIImage(cgImage: cgImage)
    let extent = ciImage.extent

    let sampleRect = CGRect(
        x: extent.width * relativeRect.origin.x,
        y: extent.height * relativeRect.origin.y,
        width: extent.width * relativeRect.width,
        height: extent.height * relativeRect.height
    )

    let inputExtent = CIVector(
        x: sampleRect.origin.x,
        y: sampleRect.origin.y,
        z: sampleRect.width,
        w: sampleRect.height
    )

    let filter = CIFilter(name: "CIAreaAverage", parameters: [
        kCIInputImageKey: ciImage,
        kCIInputExtentKey: inputExtent
    ])!

    guard let outputImage = filter.outputImage else { return 1.0 }

    var bitmap = [UInt8](repeating: 0, count: 4)
    context.render(outputImage,
                   toBitmap: &bitmap,
                   rowBytes: 4,
                   bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                   format: .RGBA8,
                   colorSpace: CGColorSpaceCreateDeviceRGB())

    let brightness = (0.299 * CGFloat(bitmap[0]) +
                      0.587 * CGFloat(bitmap[1]) +
                      0.114 * CGFloat(bitmap[2])) / 255.0
    return brightness
}


//struct BlurView: UIViewRepresentable {
//    var style: UIBlurEffect.Style
//    
//    func makeUIView(context: Context) -> UIVisualEffectView {
//        return UIVisualEffectView(effect: UIBlurEffect(style: style))
//    }
//    
//    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
//        uiView.effect = UIBlurEffect(style: style)
//    }
//}


//final class ShakeEffect: GeometryEffect {
//    private let amount: CGFloat //max movement(displacement)
//    private let shakesPerUnit: CGFloat // complete back and forth per animation
//    var animatableData: CGFloat
//
//    init(amount: CGFloat = 5, shakesPerUnit: CGFloat = 2, animatableData: CGFloat) {
//        self.amount = amount
//        self.shakesPerUnit = shakesPerUnit
//        self.animatableData = animatableData
//    }
//
//    func effectValue(size: CGSize) -> ProjectionTransform {
//        let translation = amount * sin(animatableData * .pi * shakesPerUnit)
//        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
//    }
//}


//struct NeumorphicStyle: ViewModifier {
//    var cornerRadius: CGFloat
//    var color: Color
//    
//    func body(content: Content) -> some View {
//        content
//            .padding(20)
//            .background(
//                color
//                    .cornerRadius(cornerRadius)
//                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 10, y: 10)
//                    .shadow(color: Color.white.opacity(0.7), radius: 10, x: -5, y: -5)
//            )
//    }
//}


@MainActor
//struct RecordButton: View {
//
//    var onPressBegan: () -> Void
//    var onPressEnded: () -> Void
//    var onConfirmRecording: (_: URL) -> Void
//
//    @State private var isRecording = false
//    @State private var countdownTime = 15
//    @State private var timer: Timer?
//
//    @Binding var showAlert: Bool
//    @Binding var isProcessing: Bool
//    @Binding var showPopup: Bool
//    @ObservedObject var audioRecorder: AudioRecorder
//    @Binding var showReminderSuccess: Bool
//    @State private var animateThumbsUp = false
//    
//    var body: some View {
//        ZStack(alignment: .trailing) {
//            // Reserve space for pop-up, even when it's hidden
//            if showPopup {
//                recordingPopup
//                    .transition(.opacity.combined(with: .scale)) // ✅ Consistent transition
//            } else {
//                Color.clear // ✅ Invisible placeholder to prevent shifting
//                    .frame(width: 120, height: 100)
//            }
//            
//            recordButton
//        }
//        .animation(.spring(), value: showPopup) // ✅ Apply animation globally
//    }
//
//    private var recordingPopup: some View {
//        VStack {
//            if isProcessing {
//                ProgressView()
//                    .foregroundColor(.white.opacity(0.8))
//                    .scaleEffect(2.5) // Adjust this to match the thumb image
//                        .frame(width: 100, height: 100)
//                    .contentTransition(.opacity)
//            } else if showReminderSuccess {
//                Image(systemName: "hand.thumbsup.circle.fill")
//                    .resizable()
//                    .scaledToFit()
//                    .foregroundColor(.white.opacity(0.8))
//                    .frame(width: 80, height: 80)
//                    .contentTransition(.symbolEffect(.replace))
//                    .symbolEffect(.bounce, value: animateThumbsUp)
//                    .onAppear {
//                                animateThumbsUp = true
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                                    withAnimation {
//                                        showReminderSuccess = false
//                                        showPopup = false
//                                        animateThumbsUp = false
//                                    }
//                                }
//                            }
////                    .onAppear {
////                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
////                            withAnimation {
////                                showReminderSuccess = false
////                                showPopup = false
////                            }
////                        }
////                    }
//            }
//            else {
//                Text("\(countdownTime) sec")
//                    .font(.body)
//                    .fontDesign(.rounded)
//                    .bold()
//                    .contentTransition(.numericText())
//                    .padding(.top, 8)
//                
//                HStack(spacing: 10) {
//                    Button(action: confirmRecording) {
//                        Image(systemName: "checkmark.circle.fill")
//                            .resizable()
//                            .frame(width: 35, height: 35)
//                            .foregroundColor(.green)
//                    }
//                    Button(action: cancelRecording) {
//                        Image(systemName: "xmark.circle.fill")
//                            .resizable()
//                            .frame(width: 35, height: 35)
//                            .foregroundColor(.red)
//                    }
//                }
//                .padding(.bottom, 8)
//            }
//        }
//        .frame(width: 120, height: 100)
//        .background(.ultraThinMaterial.opacity(0.7))
//        .cornerRadius(10)
//        .shadow(radius: 10)
//        .offset(x: -110, y: -10)
//        .transition(.scale.combined(with: .opacity)) // Consistent animation for both appearing and disappearing
//        .animation(.spring(), value: showPopup)
//    }
//    
//    private var recordButton: some View {
//        Image(systemName: "mic.circle.fill")
//            .resizable()
//            .scaledToFit()
//            .frame(width: 50, height: 50)
//            .foregroundColor(.blue)
//            .scaleEffect(isRecording ? 1.2 : 1.0, anchor: .bottom) // ✅ Scaling from the bottom prevents jumping
//            .animation(.easeInOut, value: isRecording)
//            .background(
//                RoundedRectangle(cornerRadius: 10)
//                    .fill(
//                        LinearGradient(
//                            gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.2), Color.blue.opacity(0.3), Color.blue.opacity(0.4)]),
//                            startPoint: .top,
//                            endPoint: .bottom
//                        )
//                    )
//                    .frame(width: 75, height: 75)
//            )
//            .scaleEffect(isRecording ? 1.1 : 1.0)
//            .animation(.easeInOut, value: isRecording)
//            .gesture(recordGesture)
//    }
//    
//    private var recordGesture: some Gesture {
//        DragGesture(minimumDistance: 0)
//            .onChanged { _ in
//                Task {
//                    guard !isRecording else { return } // Prevent multiple triggers
//
//                        deletePreviousRecording()
//                        showPopup = true
//                        try? await audioRecorder.startRecording()
//                        startCountdown()
//                        isRecording = true
//                        onPressBegan()
//                }
//            }
//            .onEnded { _ in
//                guard isRecording else { return } // Ensure recording is active before stopping
//                stopRecording()
//            }
//    }
//    
//    private func confirmRecording() {
//        
//        guard let recordedFile = audioRecorder.audioURL else { // Use stored URL instead of stopping again
//            debugLog("❌ No recorded file found")
//            return
//        }
//        debugLog("✅ Recording confirmed: \(recordedFile)")
//        withAnimation {
//            isProcessing = true
//        }
//        
//         onConfirmRecording(recordedFile)
//        resetState()
//    }
//    
//    
//    
//    
//    private func cancelRecording() {
//        
//        debugLog("❌ Audio discarded.")
//        if audioRecorder.audioURL != nil {
//            _ = audioRecorder.stopRecording()
//            audioRecorder.deleteAudioAndUrl()
//        }
//        showPopup = false
//        resetState()
//    }
//    
//    private func resetState() {
//        withAnimation {
//            isRecording = false }
//        timer?.invalidate()
//        timer = nil
//        countdownTime = 15
//    }
//    
//    private func deletePreviousRecording() {
//        if let url = audioRecorder.audioURL {
//            try? FileManager.default.removeItem(at: url) // Delete previous recording
//            debugLog("🗑 Deleted previous recording: \(url)")
//
//        }
//    }
//    
//    private func startCountdown() {
//        withAnimation {
//            countdownTime = 15 }
//        timer?.invalidate()
//        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//            DispatchQueue.main.async {
//                
//                if countdownTime > 0 {
//                    withAnimation {
//                        countdownTime -= 1 }
//                } else {
//                    timer?.invalidate()
//                    stopRecording()
//                    withAnimation {
//                        timer = nil
//                        countdownTime = 0 }
//                }
//            }
//        }
//    }
//    
//    private func stopRecording() {
//        timer?.invalidate()
//        timer = nil
//        
//        guard isRecording else {
//            debugLog("⚠️ stopRecording() called, but no active recording.")
//            return
//        }
//        
//        if audioRecorder.isRecording {
//            let _ = audioRecorder.stopRecording()
//            
//            DispatchQueue.main.async {
////                if let recordedFile = recordedFile {
////                    self.recordingURL = recordedFile
////                    print("⏳ Recording ended, file saved: \(recordedFile)")
////                } else {
////                    print("❌ stopRecording() failed to retrieve a valid file URL")
////                }
//                withAnimation {
//                    isRecording = false
//                    countdownTime = countdownTime
//                }
//                onPressEnded()
//            }
//        }
//    }
//}

final class ReminderWrapper: ObservableObject, Identifiable {
    let id = UUID()
    @Published var reminder: EKReminder

    init(reminder: EKReminder) {
        self.reminder = reminder
    }
}

final class EventWrapper: ObservableObject, Identifiable {
    let id = UUID()
    @Published var event: EKEvent

    init(event: EKEvent) {
        self.event = event
    }
}

@MainActor
struct KRecordButton: View {
    @Binding var recordingURL: URL?
    @ObservedObject var audioRecorder: AudioRecorder

    @State private var isRecording = false
    @State private var pulse = false
    @State private var hasStartedRecording = false
    @State private var recordingTask: Task<Void, Never>? = nil
    @Binding var micColor: Color
    let maxDuration: TimeInterval = 12

    var body: some View {
        Image(systemName: "mic.circle.fill")
            .font(.system(size: 60))
            .foregroundColor(micColor.opacity(0.7))
            .opacity(pulse ? 1.0 : 0.8)
            .scaleEffect(isRecording ? 1.15 : 1)
            .shadow(radius: 10)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !hasStartedRecording {
                            hasStartedRecording = true
                            debugLog("Recording Started")
                            startRecording()
                        }
                    }
                    .onEnded { _ in
                        stopRecording()
                        hasStartedRecording = false
                        debugLog("Recording Ended")
                    }
            )
            .onChange(of: isRecording) { _, newVal in
                pulse = newVal
            }
            .animation(.easeInOut(duration: 0.8), value: pulse)
    }

    private func startRecording() {
        guard !isRecording else { return }
        print("⏺ start")

        recordingTask = Task {
            isRecording = true
            try? await audioRecorder.startRecording()

            try? await Task.sleep(nanoseconds: UInt64(maxDuration * 1_000_000_000))

            if isRecording {
                stopRecording()
            }
        }
    }

    private func stopRecording() {
        print("⏺ Ended")
        recordingTask?.cancel()
        recordingTask = nil

        guard isRecording else { return }

        isRecording = false

        if let url = audioRecorder.stopRecording() {
            recordingURL = url
        }
    }
}


//struct FloatingLabelTextField: View {
//    
//    @EnvironmentObject var keyboardResponder: KeyboardResponder
//    @Binding var text: String
//    let title: String
//    let isSecure: Bool
//    var onSubmit: (() -> Void)? = nil
//    @FocusState.Binding var isFocused: Bool
//    @State private var isPasswordVisible: Bool = false
//    
//    var body: some View {
//        ZStack(alignment: .leading) {
//            
//            Text(title)
//                .foregroundColor(isFocused || !text.isEmpty ? .black : .gray)
//                .background(Color.clear)
//                .offset(y: isFocused || !text.isEmpty ? -30 : 0)
//                .scaleEffect(isFocused || !text.isEmpty ? 0.8 : 1.0, anchor: .leading)
//                .animation(.easeInOut(duration: 0.2), value: isFocused || !text.isEmpty)
//            
//            if isSecure {
//                HStack {
//                    if isPasswordVisible {
//                        TextField("", text: $text)
//                            .focused($isFocused)
//                            .textFieldStyle(PlainTextFieldStyle())
//                            .padding(.top, 20)
//                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
//                            .onSubmit {
//                                onSubmit?()
//                            }
//                    } else {
//                        SecureField("", text: $text)
//                            .focused($isFocused)
//                            .textFieldStyle(PlainTextFieldStyle())
//                            .padding(.top, 20)
//                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
//                            .onSubmit {
//                                onSubmit?()
//                            }
//                    }
//                    
//                    Button(action: {
//                        withAnimation { isPasswordVisible.toggle() }
//                    }) {
//                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
//                            .foregroundColor(.gray)
//                    }
//                    .padding(.trailing, 8)
//                }
//            } else {
//                TextField("", text: $text)
//                    .focused($isFocused)
//                    .textFieldStyle(PlainTextFieldStyle())
//                    .padding(.top, 20)
//                    .onSubmit {
//                        onSubmit?()
//                    }
//            }
//        }
//        .padding(10)
//        .background(
//            Color.clear
//                .cornerRadius(10)
//                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 10, y: 10)
//                .shadow(color: Color.white.opacity(0.7), radius: 10, x: -5, y: -5)
//        )
//        .onTapGesture {
//            self.isFocused = true
//        }
//    }
//}

extension Color {
    static let softWhite = Color(red: 0.97, green: 0.97, blue: 0.94)
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

//@MainActor func isIPad() -> Bool {
//    return UIDevice.current.userInterfaceIdiom == .pad
//}

private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}

func debugLog(_ message: String) {
#if DEBUG
    print(message)
#endif
}

extension Date {
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return self.addingTimeInterval(seconds)
    }
}

struct KAlertView: View {
    let title: String
    let message: String
    let dismissAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.custom("New York", size: 20))
                .italic()
                .multilineTextAlignment(.center)

            Text(message)
                .font(.custom("New York", size: 16))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: dismissAction) {
                Text("OK")
                    .font(.custom("New York", size: 17)).bold()
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.thinMaterial)
                .shadow(radius: 10)
        )
        .padding(40)
    }
}


protocol DisplayableError: Error, Identifiable where ID == String {
    var title: String { get }
    var message: String { get }
}

struct AnyDisplayableError: DisplayableError {
    let id: String
    let title: String
    let message: String

    init(_ error: any DisplayableError) {
        self.id = error.id
        self.title = error.title
        self.message = error.message
    }
}

enum EmbarkationStep: Int, CaseIterable {
    case welcomeIntro
    case idleExplanation
    case vaultSwipeExplanation
    case settingsSwipeExplanation
    case inputExplanation
    case vaultListExplanation

    /// Determines where the annotation box appears (top or bottom).
    var annotationAlignment: Alignment {
        switch self {
        case .idleExplanation, .vaultSwipeExplanation, .settingsSwipeExplanation, .welcomeIntro:
            return .top
        case .inputExplanation, .vaultListExplanation:
            return .bottom
        }
    }

    /// Controls the padding from the screen edge for the annotation.
    var annotationPadding: CGFloat {
        switch annotationAlignment {
        case .top:
            return 80
        case .bottom:
            return 40
        default:
            return 60 // fallback if ever needed
        }
    }
}

struct KiokuBackgroundView: View {
    var body: some View {
        Image("oldPaper")
            .resizable()
            .scaledToFill()
            .blur(radius: 1)
            .opacity(0.9)
            .ignoresSafeArea()
            .frame(width: UIScreen.main.bounds.width)
    }
}

enum UsageTrackingKeys {
    static let apiCallCount = "apiCallCount"
    static let lastResetDate = "lastResetDate"
}

//extension View {
//    @ViewBuilder
//    func keyboardAvoidance() -> some View {
//        if #available(iOS 16.0, *) {
//            self.scrollDismissesKeyboard(.interactively)
//        } else {
//            self
//        }
//    }
//}
//
//extension View {
//    func hideKeyboardOnDrag() -> some View {
//        self.gesture(
//            DragGesture().onChanged { _ in
//                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
//                                                to: nil, from: nil, for: nil)
//            }
//        )
//    }
//}


import SwiftUI

extension View {
    func hideKeyboardOnTap() -> some View {
        self.gesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                to: nil, from: nil, for: nil)
            }
        )
    }
}
