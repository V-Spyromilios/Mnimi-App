//
//  ProgressTracker.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 27.02.24.
//

import Foundation
import SwiftUI

final class ProgressTracker: ObservableObject {

    @Published var progress: CGFloat = 0.0
    static var shared = ProgressTracker()

    func reset() {
        progress = 0.0
    }
    
    func setProgress(to newValue: CGFloat) {
        DispatchQueue.main.async {
            while self.progress < newValue {
                withAnimation {
                    self.progress += 0.1
                }
            }
        }
    }
}
