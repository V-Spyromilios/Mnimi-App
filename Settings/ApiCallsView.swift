////
////  ApiCallsView.swift
////  MyndVault
////
////  Created by Evangelos Spyromilios on 27.07.24.
////
//
//import SwiftUI
//
//
//struct ApiCallsView: View {
//    @StateObject private var viewModel = ApiCallViewModel()
//    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
//    
//    var body: some View {
//        VStack {
//            //            Text("API Calls for Current Month: \(viewModel.monthlyApiCalls[viewModel.getCurrentMonth()] ?? 0)")
//            //                .padding()
//            
//            ScrollView(.horizontal, showsIndicators: false) {
//                LazyHStack(alignment: .center) {
//                    ForEach(viewModel.monthlyApiCalls.keys.sorted(by: { $0 < $1 }), id: \.self) { monthKey in
//                        GeometryReader { geometry in
//                            ApiCallCardView(month: viewModel.getMonthName(from: monthKey), apiCalls: viewModel.monthlyApiCalls[monthKey] ?? 0)
//                                .cornerRadius(10)
//                            
//                                .shadow(radius: 12)
//                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
//                        }
//                        .frame(width: UIScreen.main.bounds.width) // Set the width to screen width to center each card
//                        //
//                        
//                    }
//                }
//            }
//            Spacer()
//           // LottieRepresentable(filename: "takingNotes", loopMode: .loop, contentMode: .scaleAspectFill)
//                //.frame(height: 350)
//
//        } .navigationBarBackButtonHidden(true)
//            .background {
//                LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
//                    .opacity(0.4)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .ignoresSafeArea()
//            }
//            .navigationBarItems(leading: Button(action: {
//                presentationMode.wrappedValue.dismiss()
//            }) {
//                HStack {
//                    Image(systemName: "chevron.left")
//                    Text("Settings")
//                }.font(.title2).bold().foregroundStyle(.blue.opacity(0.7)).fontDesign(.rounded).padding(.trailing, 6)
//            })
//    }
//}
//
//struct ApiCallCardView: View {
//    var month: String
//    var apiCalls: Int
//    @Environment(\.colorScheme) var colorScheme
//    
//    var body: some View {
//        VStack {
//            Text(month)
//                .font(.title)
//                .foregroundStyle(.notificationsTitle)
//                .fontWeight(.bold)
//                .fontDesign(.rounded)
//                .padding(.bottom, 24)
//            Text("\(apiCalls) API Calls")
//                .font(.subheadline)
//                .fontDesign(.rounded)
//                .fontWeight(.medium)
//                .contentTransition(.numericText())
//                .padding(.horizontal)
//        }.frame(width: 250, height: 300)
//            .background(
//                RoundedRectangle(cornerRadius: 10)
//                    .fill(Color.cardBackground)
//                    .shadow(color: Color.customShadow, radius: colorScheme == .light ? 5 : 3, x: 0, y: 0)
//            )
//    }
//}
//#Preview {
//    //ApiCallsView()
//    ApiCallCardView(month: "July", apiCalls: 42)
//}
