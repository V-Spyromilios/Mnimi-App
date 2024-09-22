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
}
extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    func deletingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }
}


extension View {
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func navigationBarTitleView<Content: View>(_ content: @escaping () -> Content) -> some View {
        self.navigationBarItems(leading: content())
    }
    
    
}

func userDefaultsKeyExists(_ key: String) -> Bool {
    return UserDefaults.standard.object(forKey: key) != nil
}

func idealWidth(for availableWidth: CGFloat) -> CGFloat {

    if availableWidth < 800 {
        return availableWidth
    } else {

        return availableWidth * 0.6
    }
}


final class KeyboardResponder: ObservableObject {

    @Published var currentHeight: CGFloat = 0
    private var keyboardVisible = false
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardHeight = keyboardFrame.cgRectValue.height
            DispatchQueue.main.async {
                self.currentHeight = keyboardHeight
                self.keyboardVisible = true
            }
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        DispatchQueue.main.async {
            self.currentHeight = 0
            self.keyboardVisible = false
        }
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

final class ShakeEffect: GeometryEffect {
    private let amount: CGFloat //max movement(displacement)
    private let shakesPerUnit: CGFloat // complete back and forth per animation
    var animatableData: CGFloat

    init(amount: CGFloat = 5, shakesPerUnit: CGFloat = 2, animatableData: CGFloat) {
        self.amount = amount
        self.shakesPerUnit = shakesPerUnit
        self.animatableData = animatableData
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}


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

//@MainActor
//struct CustomDatePicker: View {
//    @Binding var selectedDate: Date
//    @State private var showingDatePicker = false
//    
//    var body: some View {
//        VStack {
//            Button(action: {
//                withAnimation {
//                    showingDatePicker.toggle() }
//            }) {
//                
//                    Text("\(selectedDate, formatter: dateFormatter)")
//                    .font(.title2)
//                    .fontDesign(.rounded)
//                    .fontWeight(.medium)
//                    .foregroundStyle(.secondary)
//                    .padding(.bottom, 8)
//            }
//           
//            .background(RoundedRectangle(cornerRadius: 10).fill(Color.clear))
//            .shadow(radius: 4)
//            
//            if showingDatePicker {
//                DatePicker(
//                    "",
//                    selection: $selectedDate,
//                    displayedComponents: [.date, .hourAndMinute]
//                )
//                .datePickerStyle(GraphicalDatePickerStyle())
//                .labelsHidden()
//                
//                .padding(.bottom, 12)
//               // .shadow(radius: 5)
//               
//            }
//        }.frame(maxHeight: 500)
//    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }


enum RepeatInterval: String, CaseIterable, Identifiable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case weekdays = "Weekdays"
    case weekends = "Weekends"
    
    var id: String { self.rawValue }
    
    var description: LocalizedStringKey {
            switch self {
            case .none:
                return LocalizedStringKey("Never")
            case .daily:
                return LocalizedStringKey("Daily")
            case .weekly:
                return LocalizedStringKey("Weekly")
            case .weekdays:
                return LocalizedStringKey("Weekdays")
            case .weekends:
                return LocalizedStringKey("Weekends")
            }
        }
}
