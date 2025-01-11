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

@MainActor
struct Constants {
    
    static let assemblyCode = """
section .data
    message db 'LOGIN', 0

section .bss
    len resb 1

section .text
    global _start

_start:
    mov ecx, message
    mov ebx, 0
get_len:
    cmp byte [ecx + ebx], 0
    je done
    inc ebx
    jmp get_len
done:
    mov [len], ebx
    mov eax, 4
    mov ebx, 1
    mov ecx, message
    mov edx, [len]
    int 0x80
    mov eax, 1
    xor ebx, ebx
    int 0x80
""".trimmingCharacters(in: .whitespacesAndNewlines)
    
    
    static let rectCornerRad: CGFloat = 50
    
    static let textEditorHeight: CGFloat = 140
    
    static let smallTextEditorHeight: CGFloat = 50
    
    static let contentUnaivalableOffset: CGFloat = 40
    
    static let buttonHeight: CGFloat = 50
    
    static let backgroundSpeed: CGFloat = 0.4
    
    static let standardCardPadding: CGFloat = 16
    
    static let showLangDuration: CGFloat = 2.5
    
    static let entitlementID: String = "manager"
    
    static let welcomeText: String = "Welcome to MyndVault!\n\nThis app is more than just a project—it’s a reflection of my journey. Transitioning into software development later in life wasn’t easy, but it was driven by a desire to create meaningful, distraction-free tools in a world of digital noise. MyndVault was built with digital minimalism in mind, designed to help you store and retrieve your thoughts effortlessly, without stealing your attention. No ads, no notifications, no personal data collection. Just a simple, elegant interface that empowers you to remember the important staff.\n\nIf you’re a fellow coder or just curious about how this app works, feel free to connect— I’d love to share ideas and stories.\nLet’s build something meaningful together!"
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


extension View {
    @MainActor
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    @MainActor
    func navigationBarTitleView<Content: View>(_ content: @escaping () -> Content) -> some View {
        self.navigationBarItems(leading: content())
    }
    
    
}

func userDefaultsKeyExists(_ key: String) async -> Bool {
    // running only in a background task
    return await Task(priority: .background) {
        return UserDefaults.standard.object(forKey: key) != nil
    }.value // Task returns 'Task<Bool, never>'
}

func idealWidth(for availableWidth: CGFloat) -> CGFloat {
    
    if availableWidth < 800 {
        return availableWidth
    } else {
        
        return availableWidth * 0.6
    }
}


@MainActor
final class KeyboardResponder: ObservableObject {
    
    @Published var currentHeight: CGFloat = 0
    private var keyboardVisible = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue }
            .map { $0.cgRectValue.height }
            .receive(on: RunLoop.main)
            .sink { [weak self] height in
                self?.currentHeight = height
                self?.keyboardVisible = true
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.currentHeight = 0
                self?.keyboardVisible = false
            }
            .store(in: &cancellables)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardHeight = keyboardFrame.cgRectValue.height
            self.currentHeight = keyboardHeight
            self.keyboardVisible = true
            
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        // no ' DispatchQueue.main.async {' as class marked @MainActor
        self.currentHeight = 0
        self.keyboardVisible = false
    }
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


struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}


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


struct NeumorphicStyle: ViewModifier {
    var cornerRadius: CGFloat
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                color
                    .cornerRadius(cornerRadius)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 10, y: 10)
                    .shadow(color: Color.white.opacity(0.7), radius: 10, x: -5, y: -5)
            )
    }
}

@MainActor
struct FloatingLabelTextField: View {
    
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @Binding var text: String
    let title: String
    let isSecure: Bool
    var onSubmit: (() -> Void)? = nil
    @FocusState.Binding var isFocused: Bool
    @State private var isPasswordVisible: Bool = false // State to toggle visibility
    
    var body: some View {
        ZStack(alignment: .leading) {
            
            Text(title)
                .foregroundColor(isFocused || !text.isEmpty ? .customTiel : .gray)
                .background(Color.clear)
                .offset(y: isFocused || !text.isEmpty ? -30 : 0)
                .scaleEffect(isFocused || !text.isEmpty ? 0.8 : 1.0, anchor: .leading)
                .animation(.easeInOut(duration: 0.2), value: isFocused || !text.isEmpty)
            
            if isSecure {
                HStack {
                    if isPasswordVisible {
                        TextField("", text: $text)
                            .focused($isFocused)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.top, 20)
                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                            .onSubmit {
                                onSubmit?()
                            }
                    } else {
                        SecureField("", text: $text)
                            .focused($isFocused)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.top, 20)
                            .transition(.blurReplace(.downUp).combined(with: .push(from: .bottom)))
                            .onSubmit {
                                onSubmit?()
                            }
                    }
                    
                    Button(action: {
                        withAnimation { isPasswordVisible.toggle() }
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 8)
                }
            } else {
                TextField("", text: $text)
                    .focused($isFocused)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.top, 20)
                    .onSubmit {
                        onSubmit?()
                    }
            }
        }
        .padding(10)
        .background(
            Color.clear
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 10, y: 10)
                .shadow(color: Color.white.opacity(0.7), radius: 10, x: -5, y: -5)
        )
        .onTapGesture {
            self.isFocused = true
        }
    }
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

@MainActor func isIPad() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}

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
