import SwiftUI

struct SplashScreen: View {
    @EnvironmentObject var cloudKit: CloudKitViewModel // Use this to check if loading is ok, check Notes
    
    @Binding var showSplash: Bool
    @State private var greenHeight: CGFloat = 0
    @State private var showLogo: Bool = false
    @State private var currentSymbolIndex: Int = 0
    @State private var loadingComplete: Bool = false
    @State private var codeLines: [String] = []
    @State private var currentLineIndex: Int = 0
    @State private var showCode: Bool = false
    @State private var logs: [String] = []
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    let symbols: [String] = ["link.icloud", "tray", "gear", "checkmark", ""]
    
    var body: some View {
        GeometryReader { geometry in
            
            ZStack {
                Color.primaryBackground
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Color.britishRacingGreen
                        .frame(height: greenHeight)
                        .ignoresSafeArea(.all)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1)) {
                                greenHeight = geometry.size.height + 100
                            }                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    
                                    startAnimations()
                                }
                            }
                        }
                }.frame(height: geometry.size.height)
                
                
                //                ScrollView {
                //                    if !cloudKit.userIsSignedIn {
                //                        Text("User is Not signed -in").padding()
                //                    }
                if showLogo {
                    carousel(geometry: geometry)
                    
                }
                //                    if !cloudKit.fetchedNamespaceDict.isEmpty {
                //                        Text("NamespaceDictionary is not Empty")
                //                    }
                //                    else if cloudKit.fetchedNamespaceDict.isEmpty {
                //                        Text("NamespaceDictionary is Empty !")
                //                    }
                //                    if cloudKit.CKError != "" {
                //                        Text("Error CloudKit: \(cloudKit.CKError)")
                //                    }
                //                    VStack(alignment: .leading) {
                //                        ForEach(cloudKit.log, id: \.self) { logEntry in
                //                            Text(logEntry)
                //                                .foregroundColor(.black)
                //                                .font(.footnote)
                //                                .padding(2)
                //                        }
                //                        Spacer()
                //                    }
                //                }
                //                .frame(height: geometry.size.height * 0.4)
                //                .background(Color.white)
                //                .cornerRadius(8)
                //                .shadow(radius: 4)
                //                .padding()
                
                if showCode {
                   
                    codeView(geometry: geometry)
                }
                
            }
            .statusBar(hidden: true)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("Retry"),
                                              action: cloudKit.startCloudKit))
                    } //TODO: Check this if is correct to call again. Check in this screen if namespace etc failed and make the alertMessage
        }
        .onAppear {
            cloudKit.startCloudKit()
        }
        
        .onChange(of: currentSymbolIndex) { _, newValue in
            
            if newValue == symbols.count - 1 { // The index of symbols[""]
                withAnimation {
                    showLogo = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { //around 1.3 - a.4
                    
                    loadingComplete = true // Just to mimic the loading ok
                }
            }
        }
        .onChange(of: loadingComplete) {
            if loadingComplete {
               
                withAnimation(.easeInOut(duration: 0.01)) {
                    showSplash = false
                    
                }
            }
        }
        .onChange(of: cloudKit.CKError) { _, error in
            if error != "" { self.alertMessage = error }
        }
    }
    @ViewBuilder
    private func carousel(geometry: GeometryProxy) -> some View {
        let symbolWidth = geometry.size.width
        
        HStack(spacing: 0) {
            
            Image(systemName: symbols[currentSymbolIndex])
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .foregroundStyle(Color.primaryBackground)
                .cornerRadius(8)
            
        }
        .frame(width: symbolWidth, height: symbolWidth, alignment: .center)
    }
    
    private func startAnimations() {
        withAnimation {
            showCode = true
            showLogo = true
        }
        startCodeAnimation()
        startSymbolAnimation()
    }
    
    @ViewBuilder
    private func codeView(geometry: GeometryProxy) -> some View {
        VStack(alignment: .trailing) {
            Spacer()
            ForEach(Array(codeLines.enumerated()), id: \.offset) { _, line in
                Text(line)
          
                    .foregroundColor(colorScheme == .light ? Color.primaryBackground : Color.black)
                    .font(Font.custom("SF-Compact", size: 13))
                    .transition(.move(edge: .bottom))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing)
                    .padding(.bottom, 12)
            }
        }
        .frame(width: geometry.size.width, alignment: .trailing).padding(.bottom, 12)
    }
    
    func startSymbolAnimation() {
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.1)) {
                
                currentSymbolIndex += 1
            }
            if currentSymbolIndex >= symbols.count - 1 {
                timer.invalidate()
            }
        }
    }
        
        func startCodeAnimation() {
            let lines = assemblyCode.split(separator: "\n").map { String($0) }
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if currentLineIndex < lines.count {
                    withAnimation {
                        codeLines.append(lines[currentLineIndex])
                    }
                    currentLineIndex += 1
                } else {
                    //                withAnimation {
                    //                    codeLines = [] }
                    timer.invalidate()
                }
            }
        }

}
    #Preview {
        SplashScreen(showSplash: .constant(true))
            .environmentObject(CloudKitViewModel())
    }

