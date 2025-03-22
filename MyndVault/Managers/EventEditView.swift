//
//  EventEditView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 01.03.25.
//

import Foundation
import SwiftUI
import EventKitUI

/// A SwiftUI wrapper for Apple's built-in event editor
struct EventEditView: UIViewControllerRepresentable {
    let eventStore: EKEventStore
    let event: EKEvent
    var onDismiss: (() -> Void)? // ✅ Optional closure to handle dismiss

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = eventStore
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(onDismiss: onDismiss)
    }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        var onDismiss: (() -> Void)? // ✅ Now stored locally in Coordinator

        init(onDismiss: (() -> Void)?) {
            self.onDismiss = onDismiss
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) { 
            switch action {
            case .saved:
                print("✅ Event saved!")
            case .canceled:
                print("❌ Event creation canceled.")
            case .deleted:
                print("🗑 Event deleted.")
            @unknown default:
                print("⚠️ Unknown action.")
            }
            onDismiss?() // dismiss the SwiftUI sheet: activeModel = nil is called.
            
        }
    }
}
