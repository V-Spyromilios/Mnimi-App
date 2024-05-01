//
//  LoadingView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 06.03.24.
//

import SwiftUI

//MARK: DEPRICATED

struct LoadingView: View {
    var body: some View {
        VStack {
            Text("Loading....").font(.title).padding()
            ProgressView().font(.title2)
        }
    }
}

#Preview {
    LoadingView()
}
