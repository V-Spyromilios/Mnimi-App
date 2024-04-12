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


let rectCornerRad: CGFloat = 50
var yellowGradient = LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.3), Color.yellow.opacity(0.6), Color.yellow]), startPoint: .top, endPoint: .bottom)

var greenGradient = LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.3), Color.green.opacity(0.6), Color.green]), startPoint: .top, endPoint: .bottom)



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



struct Formatters {
    
    static var shared = Formatters()
    
    //For the recordings with .m4a
    func formatfileName(_ filename: String) -> String? {
        
        let dateString = filename
            .deletingPrefix("recording_")
            .deletingSuffix(".m4a")
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "dd-MM-yy_HH_mm_ss"
        
        guard let date = inputFormatter.date(from: dateString) else {
            print("formatfileName() Error parsing date from filename: \(dateString).")
            return nil
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        outputFormatter.timeStyle = .short
        
        return outputFormatter.string(from: date)
    }
}

extension LinearGradient {
    static func bluePurpleGradient() -> LinearGradient {
        return LinearGradient(gradient: Gradient(colors: [Color.purple ,Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}


extension View {
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    
}



class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    
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
            }
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        DispatchQueue.main.async {
            self.currentHeight = 0
        }
    }
}


// MARK: from ISO8601 to displayed date and time. I use ISO8601 to convert Date() to string for pinecone's timestamp:String.

func dateFromISO8601(isoDate: String) -> Date? {
    let formatter = ISO8601DateFormatter()
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

func toDictionary(type: String, desc: String, relevantFor: String) -> [String: String] {
    
    return [
        "type": type,
        "description": desc,
        "relevantFor": relevantFor,
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
                .background(Color.green.opacity(0.3))
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
        .padding(.top, 14)
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
