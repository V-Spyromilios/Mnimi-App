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


let assemblyCode = """
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

func userDefaultsKeyExists(_ key: String) -> Bool {
    return UserDefaults.standard.object(forKey: key) != nil
}

let rectCornerRad: CGFloat = 50

let toolbarButtonShadow: CGFloat = 6
let textEditorHeight: CGFloat = 140
let smallTextEditorHeight: CGFloat = 50

let contentUnaivalableOffset: CGFloat = 40

let greenGradient = LinearGradient(gradient: Gradient(colors: [Color.britishRacingGreen.opacity(0.7), Color.britishRacingGreen.opacity(0.8), Color.britishRacingGreen.opacity(0.9),
    Color.britishRacingGreen]), startPoint: .top, endPoint: .bottom)


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


func popOverView(animateStep: Binding<Int>, show: Binding<Bool>) -> some View {

    VStack(alignment: .center) {
               ZStack {
                   Color.britishRacingGreen.ignoresSafeArea()
                   
                   if animateStep.wrappedValue == 0 || animateStep.wrappedValue == 1 {
                       Image(systemName: "arrow.2.circlepath")
                           .resizable().padding(5)
                           .scaledToFit()
                           .foregroundStyle(.white)
                           .frame(width: 70, height: 70)
                           .rotationEffect(Angle.degrees(animateStep.wrappedValue == 0 ? 360 : 0))
//                           .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
                           .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: animateStep.wrappedValue)
                   } else if animateStep.wrappedValue == 2 {
                       Image(systemName: "checkmark.circle")
                           .resizable().padding(5)
                           .scaledToFit()
                           .foregroundStyle(.white)
                           .frame(width: 70, height: 70)
                           .transition(.opacity)
                   }
               }
               .onAppear{
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                  withAnimation {
                                      animateStep.wrappedValue = 1 } }
                   
                   DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                                  withAnimation {
                                      animateStep.wrappedValue = 2 } }
                   
                   DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                                  withAnimation {
                                      show.wrappedValue = false } }
               }
           }
}

extension View {
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func ErrorView(thrownError: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.icloud.fill").foregroundStyle(.yellow).font(.largeTitle)
            Text(thrownError).font(.caption2).bold()
        }
        .animation(.easeOut, value: thrownError)
    }

}



func idealWidth(for availableWidth: CGFloat) -> CGFloat {

    if availableWidth < 800 {
        return availableWidth
    } else {

        return availableWidth * 0.6
    }
}


struct KeyboardToolbar: ViewModifier {
    var toolbarContent: () -> AnyView

    func body(content: Content) -> some View {
        content
            .background(
                VStack {
                    Spacer()
                    toolbarContent()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.systemBackground))
                }
            )
    }
}

extension View {
    func keyboardToolbar<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(KeyboardToolbar {
            AnyView(content())
        })
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
                print("Keyboard height changed to: \(keyboardHeight)")
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



struct TopNotificationBar: View {
    let message: String
    @Binding var show: Bool
    
    var body: some View {
        VStack {
            Text(message)
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .cornerRadius(rectCornerRad)
                .gesture(DragGesture().onEnded { value in
                    if value.translation.height < 0 {
                        withAnimation {
                            show = false
                        }
                    }
                })
            
            Spacer()
        }
//        .padding(.top, 14)
        .padding(.horizontal)
        .shadow(radius: 10)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    show = false
                }
            }
        }
    }
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
