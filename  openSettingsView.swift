//
//   openSettings.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 09.07.24.
//

import SwiftUI

struct ThisViewAa: View {
    var body: some View {
        VStack {
            Spacer()
            Button(action: openSettings) {
                Text("Settings")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            Spacer()
        }
        .background(Color.blue.opacity(0.1))
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ThisViewAa()
    }
}
