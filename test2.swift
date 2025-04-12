//
//  test2.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 01.04.25.
//

import SwiftUI

struct KiokuMainView: View {
    @State private var text: String = ""

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                // App title (optional)
                Text("Kioku")
                    .fontDesign(.rounded)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.top, 24)

                // The clean TextEditor
                TextEditor(text: $text)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .font(.system(size: 18, weight: .regular, design: .default))
                    .foregroundColor(.primary)
                    .background(Color.clear)
                    .frame(maxHeight: .infinity)
                    .overlay(
                        // Optional placeholder
                        Group {
                            if text.isEmpty {
                                Text("Your memory starts here...")
                                    .font(.custom("New York", size: 18))
                                
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                            }
                        }, alignment: .topLeading
                    )

                Spacer()

                // The simple button
                Button(action: {
                    // Save action
                }) {
                    Text("Save")
                        .font(.custom("New York", size: 28))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
//                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor.opacity(0.1)))
                }
            }
            .padding()

            // The floating button (record, capture, etc.)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // Record or trigger action
                    }) {
                        Image(systemName: "mic.fill")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding()
//                            .background(Circle().fill(Color.accentColor))
//                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        }
    }
}
#Preview {
    KiokuMainView()
}
