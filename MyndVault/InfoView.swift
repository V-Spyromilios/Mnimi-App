//
//  InfoView.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 12.04.24.
//

import SwiftUI

struct InfoView: View {
    
    @ObservedObject var viewModel: EditInfoViewModel
    
    @EnvironmentObject var openAiManager: OpenAIManager
    @EnvironmentObject var pineconeManager: PineconeManager
    @EnvironmentObject var progressTracker: ProgressTracker
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @FocusState private var focusField: Field?
    @State var thrownError: String = ""
    @State var apiCallInProgress: Bool = false
    private enum Field {
        case addNew
        case relevantFor
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "rectangle.and.pencil.and.ellipsis").bold()
                Text("Edit Info:").bold()
                Spacer()
            }.font(.callout)
                .padding(.bottom, 12)
            HStack {
                TextEditor(text: $viewModel.description)
                    .overlay{
                        RoundedRectangle(cornerRadius: 10.0)
                            .stroke(lineWidth: 1)
                            .opacity(0.3)
                            .foregroundColor(Color.gray)
                    }
                
                    .frame(minHeight: 100)
                    .padding(.bottom)
                    .onAppear { }
                    .onSubmit { focusField = .relevantFor }
                    .focused($focusField, equals: .addNew)
            }
            HStack {
                Image(systemName: "person.bubble").bold()
                Text("Relevant For:").bold()
                Spacer()
            }.font(.callout)
                .padding(.bottom, 12)
            
            TextEditor(text: $viewModel.relevantFor)
                .frame(minHeight: 40)
                .overlay{
                    RoundedRectangle(cornerRadius: 10.0)
                        .stroke(lineWidth: 1)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                }
                .padding(.bottom, 50)
                .onSubmit {
                    focusField = nil //TODO: test if dismisses the keyboard
                }
                .focused($focusField, equals: .relevantFor)
            
            HStack {
                Button(action: {
                    DispatchQueue.main.async {
                        viewModel.showConfirmation = true
                        print("Button changed showConfirmation to \(viewModel.showConfirmation.description)")
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: rectCornerRad)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.6), Color.blue]), startPoint: .top, endPoint: .bottom))
                            .frame(height: 70)
                            .shadow(color: .blue.opacity(0.9), radius: 3, x: 3, y: 3)
                        Text("Save").font(.title2).bold().foregroundColor(.white)
                    }
                }.frame(maxWidth: .infinity) // to get all 'safe' width, in all possible screens
                    .padding(.bottom, keyboardResponder.currentHeight > 0 ? 25: 0) //Check if correct
            }
        }
    }
}

#Preview {
    InfoView(viewModel: EditInfoViewModel(vector: Vector(id: "1234", metadata: ["Test":"test"])))
        .environmentObject(OpenAIManager())
        .environmentObject(PineconeManager())
       
        .environmentObject(ProgressTracker())
        
        .environmentObject(KeyboardResponder())
}
