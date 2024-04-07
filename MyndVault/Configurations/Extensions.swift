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
