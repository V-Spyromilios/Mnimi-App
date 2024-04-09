//
//  EditInfoView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 18.03.24.
//

import SwiftUI
import SwiftData

struct EditInfoView: View {
    
    @ObservedObject var viewModel: EditInfoViewModel
    @State var showConfirmation: Bool = false
    
    var body: some View {
        
        Form {
            TextField("Timestamp", text: $viewModel.timestamp)
            TextField("Relevant For", text: $viewModel.relevantFor)
            TextField("Description", text: $viewModel.description)
            Button("Save") {
                print("saved.")
                showConfirmation = true
            }
            //.disabled(vector.metadata["description"].count < 5 && vector.metadata["description"].wrappedValue.count < 2)
        }
        if showConfirmation {
            EditConfirmView().showAndStack()
                .dismissAfter(5)
        }
        
    }
       
}

#Preview {
    EditInfoView(viewModel: EditInfoViewModel(vector: Vector(id: "uuid-test01", metadata: [
        "timestamp":"2024",
        "relevantFor":"Charlie",
        "description":"Pokemon",
    ])))
}
