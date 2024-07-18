//
//  LottieView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 13.07.24.
//

import SwiftUI
import Lottie

struct LottieRepresentable: UIViewRepresentable {

    let filename: String
    var loopMode: LottieLoopMode
    let speed: CGFloat
    @Binding var isPlaying: Bool
    let animationView: LottieAnimationView
    let contentMode: UIView.ContentMode
    
    init(filename: String, loopMode: LottieLoopMode = .playOnce, speed: CGFloat = 1.0, isPlaying: Binding<Bool> = .constant(true), contentMode: UIView.ContentMode = .scaleAspectFit) {
        self.filename = filename
        self.loopMode = loopMode
        self.speed = speed
        self._isPlaying = isPlaying
        self.animationView = LottieAnimationView(name: filename)
        self.contentMode = contentMode
    }
    
   
    func makeUIView(context: Context) -> UIView {

        let view = UIView(frame: .zero)
        view.addSubview(animationView)

        animationView.loopMode = loopMode
        animationView.animationSpeed = speed
        animationView.contentMode = contentMode
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        animationView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true

        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if isPlaying {
            animationView.play { _ in //this completion runs in after play 
                isPlaying = false
            }
        }
    }
    
    class Coordinator: NSObject {
        var parent: LottieRepresentable

        init(parent: LottieRepresentable) {
            self.parent = parent
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
}
