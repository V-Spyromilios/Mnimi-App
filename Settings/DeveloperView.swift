//
//  DeveloperView.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 14.02.24.
//

import SwiftUI

struct DeveloperView: View {

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @ObservedObject var viewModel = PineconeManager()
    var body: some View {
        VStack {
    
            Button(action: {
                viewModel.listPineconeIndexes()
            }, label: {
                Text("List Pinecone Indexes").fontWeight(.semibold).fontDesign(.rounded).font(.title3).padding()
            })
            
            Button(action: {
                viewModel.checkPineconeIndex()
            }, label: {
                Text("Check Pinecone Index").fontWeight(.semibold).fontDesign(.rounded).font(.title3).padding(.bottom)
            })
            
            Button(action: {
                viewModel.getIndexInfo(indexName: "memoryindex")
            }, label: {
                Text("Get Index Info").fontWeight(.semibold).fontDesign(.rounded).font(.title3).padding(.bottom)
            })
           
        ScrollView {
            VStack {
                if viewModel.indexDetails != nil {
                    HStack {
                        Text("Index Details").font(.title3).fontDesign(.rounded).padding(.vertical)
                        Spacer()
                    }
                    Text(viewModel.indexDetails ?? "").font(.callout).fontDesign(.rounded)
                }
                if viewModel.indexesList != nil {
                    HStack {
                        Text("All indexes").font(.title3).fontDesign(.rounded).padding(.vertical)
                        Spacer()
                    }
                    Text(viewModel.indexesList ?? "").font(.callout).fontDesign(.rounded)
                }
                if viewModel.indexInfo != nil {
                    HStack {
                        Text("Index Info").font(.title3).fontDesign(.rounded).padding(.vertical)
                        Spacer()
                    }
                    Text(viewModel.indexInfo ?? "").font(.callout).fontDesign(.rounded)
                }
            }.padding()
            }
        }.navigationTitle("Pinecone Developer View")
            .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                self.presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Settings")
                                }
                            }
                        }
                    }
    }
}

#Preview {
    DeveloperView()
}
