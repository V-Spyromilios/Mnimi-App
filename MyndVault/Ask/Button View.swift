//
//  Button View.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 19.03.24.
//

import SwiftUI

struct Button_View: View {
    var body: some View {
        VStack(spacing: 50) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.6), Color.blue]), startPoint: .top, endPoint: .bottom))
                    .frame(width: 70, height: 60)
                    .shadow(color: .blue.opacity(0.9), radius: 3, x: 3, y: 3) // subtle shadow for a lifted effect
                Text("Go").font(.title3).bold().foregroundColor(.white)
            }
            
            
            
            VStack {
                HStack {
                    Image(systemName: "exclamationmark.icloud.fill").foregroundStyle(.yellow).padding(.trailing, 9)
                    Text("Error requesting ....Error requesting ....Error requesting ....Error requesting ....Error requesting ....Error requesting ....Error requesting ....Error requesting ....Error requesting ....Error requesting ....").font(.caption2).bold().multilineTextAlignment(.leading)
                }
                
                HStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.3), Color.yellow.opacity(0.6), Color.yellow,
                                                                             
                                                                             Color.orange.opacity(0.6),                                          Color.orange]), startPoint: .top, endPoint: .bottom))
                            .frame(width: 70, height: 60)
                            .shadow(color: .yellow.opacity(0.9), radius: 3, x: 3, y: 3) // subtle shadow for a lifted effect
                        Text("Reset").font(.title3).bold().foregroundColor(.white)
                    }
                }
            }
        }
    }
}

#Preview {
    Button_View()
}
