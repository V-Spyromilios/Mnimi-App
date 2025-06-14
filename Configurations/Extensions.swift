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
import SwiftData

@MainActor
struct Constants {
    
    static let entitlementID: String = "manager"
}


func userDefaultsKeyExists(_ key: String) async -> Bool {
    // running only in a background task
    return await Task(priority: .background) {
        return UserDefaults.standard.object(forKey: key) != nil
    }.value // Task returns 'Task<Bool, never>'
}


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



enum Persistence {
    static let container: ModelContainer = {
        let config = ModelConfiguration(cloudKitDatabase: .none)   // .none for local store
        do {
            return try ModelContainer(for: VectorEntity.self, configurations: config)
        } catch {
            fatalError("⚠️ SwiftData container failed: \(error)")
        }
    }()
}

func clean(text: String) -> String {
    text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}



func withTimeout<T: Sendable>(
    seconds: Double,
    operation: @MainActor @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw AppNetworkError.timeout("Operation timed out after \(seconds) seconds.")
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

final class ReminderWrapper: ObservableObject, Identifiable {
    let id = UUID()
    var title: String
    var dueDate: Date?
    var notes: String?
    
    init(title: String, dueDate: Date?, notes: String?) {
        self.title = title
        self.dueDate = dueDate
        self.notes = notes
    }
}

final class EventWrapper: ObservableObject, Identifiable {
    let id = UUID()
       var title: String
       var startDate: Date
       var endDate: Date
       var location: String?
    
    init(title: String, startDate: Date, endDate: Date, location: String? = nil) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
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
    @State private var animateWave = false
    @Binding var micColor: Color
    let maxDuration: TimeInterval = 12

    var body: some View {
        ZStack {
            if isRecording {
                Image(systemName: "waveform.badge.microphone")
                    .font(.system(size: 58))
                    .foregroundColor(micColor.opacity(0.85))
                    .scaleEffect(animateWave ? 1.1 : 0.95)
                    .symbolEffect(.variableColor)
                    .opacity(0.9)
                    .transition(.opacity.combined(with: .scale))
            } else {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(micColor.opacity(0.7))
                    .opacity(pulse ? 1.0 : 0.8)
                    .scaleEffect(isRecording ? 1.15 : 1)
                    .shadow(radius: 10)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !hasStartedRecording {
                        hasStartedRecording = true
                        debugLog("Recording Started")
                        startRecording()
                        animateWave = true
                    }
                }
                .onEnded { _ in
                    stopRecording()
                    hasStartedRecording = false
                    debugLog("Recording Ended")
                    animateWave = false
                }
        )
        .onChange(of: isRecording) { _, newVal in
            pulse = newVal
        }
        .animation(.easeInOut(duration: 0.8), value: animateWave)
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
    case micExplanation
    case inputExplanation
    case inputExplanationRemindersCalendar
    case vaultSwipeExplanation
    case vaultListExplanation
    case settingsSwipeExplanation
    case requestPermissions

    /// Determines where the annotation box appears (top or bottom).
    var annotationAlignment: Alignment {
        switch self {
        case .idleExplanation, .vaultSwipeExplanation, .settingsSwipeExplanation, .welcomeIntro, .requestPermissions, .micExplanation, .inputExplanationRemindersCalendar:
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
