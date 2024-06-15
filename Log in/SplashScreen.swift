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
    @State private var showCode: Bool  = false
    
    let symbols: [String] = ["link.icloud", "tray", "gear", "checkmark", ""]
    
    var body: some View {
        GeometryReader { geometry in
           
            ZStack {
                Color.white
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Color.britishRacingGreen
                        .frame(height: greenHeight)
                        .ignoresSafeArea(.all)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1)) {
                                greenHeight = geometry.size.height + (geometry.size.height * 0.15)
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    showLogo = true
                                    startSymbolAnimation()
                                }
                            }
                        }
                }.frame(height: greenHeight)
//                    .frame(width: geometry.size.width)
                if showLogo {
                    carousel(geometry: geometry)
                  
                }
                if showCode {
                    codeView(geometry: geometry)
                }
            }
            .onChange(of: currentSymbolIndex) { _, newValue in
                
                if newValue == symbols.count - 1 { // The index of symbols[""]
                    withAnimation {
                        showLogo = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        
                        loadingComplete = true // Just to mimic the loading ok
                    }
                }
            }
            .onChange(of: loadingComplete) {
                if loadingComplete {
                    withAnimation(.easeInOut(duration: 0.5)) {
//                        greenHeight = 0
                        showCode = false
                    }
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showSplash = false
                    }
                }
            }
            .onAppear {
                cloudKit.startCloudKit()
                startCodeAnimation()
            }
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
                .foregroundStyle(.white)
                .cornerRadius(8)
            
        }
        .frame(width: symbolWidth, height: symbolWidth, alignment: .center)
        
    }
    
    func startSymbolAnimation() {
        withAnimation { showCode = true }
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentSymbolIndex += 1
            }
        }
    }
    
    @ViewBuilder
    private func codeView(geometry: GeometryProxy) -> some View {
        VStack(alignment: .trailing) {
            Spacer()
            ForEach(Array(codeLines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .foregroundColor(.gray).opacity(0.7)
                    .font(Font.custom("SF-Compact", size: 13))
                    .transition(.move(edge: .bottom))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing)// Align text to the trailing edge
            }
        }
        .frame(width: geometry.size.width, alignment: .trailing)  // Align the VStack to the trailing edge
        
    }
    
    func startCodeAnimation() {
        let lines = assemblyCode.split(separator: "\n").map { String($0) }
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            if currentLineIndex < lines.count {
                withAnimation {
                    codeLines.append(lines[currentLineIndex])
                }
                currentLineIndex += 1
            } else {
                withAnimation {
                    codeLines = [] }
                timer.invalidate()
            }
        }
    }
    
}
#Preview {
    SplashScreen(showSplash: .constant(true))
}
