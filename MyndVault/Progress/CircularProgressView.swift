//
//  CircularProgressView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 27.02.24.
//

import SwiftUI

struct CircularProgressView: View {
    
    
    
    @ObservedObject var progressTracker: ProgressTracker // Expecting a value between 0 and 1
    
    let bluePurpleGradient = LinearGradient(gradient: Gradient(colors: [Color.purple ,Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing)

    var body: some View {
        
        ZStack {
            
//            Circle()
//                .stroke(lineWidth: 5)
//                .opacity(0.3)
//                .foregroundColor(Color.gray)
//                .frame(height: 60)
//            Circle()
//                .trim(from: 0, to: progressTracker.progress)
//                .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
//                .foregroundStyle(greenGradient)
//                .frame(height: 60)
//                .rotationEffect(Angle(degrees: -90))
//                .animation(.smooth, value:progressTracker.progress) //.linear?
            Text("\(Int(progressTracker.progress * 100))%")
                .contentTransition(.numericText(countsDown: false))
                .font(.title3)
                .fontDesign(.rounded)
                .bold()
                .foregroundStyle(bluePurpleGradient)
            
            
        }
    }
    
}

#Preview {
    CircularProgressView(progressTracker: ProgressTracker.shared)
}
