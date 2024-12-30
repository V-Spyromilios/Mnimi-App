//
//  ShareSheet.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 20.12.24.
//

import UIKit
import SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    let items: [String] //change to any for adding & sending images
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
