import SwiftUI

struct SplashScreen: View {
    @EnvironmentObject var cloudKit: CloudKitViewModel // Use this to check if loading is ok, check Notes
    
    @Binding var showSplash: Bool
    @State private var greenHeight: CGFloat = 0

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

                LottieRepresentable(filename: "Gradient Background", loopMode: .loop, speed: Constants.backgroundSpeed, contentMode: .scaleAspectFill)
                        .opacity(0.4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()

                if showCode {
                   
                    codeView(geometry: geometry)
                }
            }
            .statusBar(hidden: true)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("iCloud"),
                    message: Text(alertMessage),
                    primaryButton: .default(Text("Retry")) {
                        cloudKit.clearCloudKit()
                        cloudKit.startCloudKit()
                    },
                    secondaryButton: .default(Text("Login with iCloud")) {
                        openICloudSettings()
                    }
                )
            }
        }
        .onAppear {
            startAnimations()
            cloudKit.startCloudKit()
        }
        .onChange(of: cloudKit.userIsSignedIn) { _, isSignedIn in
                    if !isSignedIn {
                        showAlert = true
                        alertMessage = "Please sign in to iCloud to continue using the app."
                    }
                }

        .onChange(of: loadingComplete) {
            if loadingComplete {
                withAnimation(.easeInOut(duration: 0.1)) {
                    showSplash.toggle()
                }
            }
        }
        .onChange(of: cloudKit.CKErrorDesc) { _, error in
            if error != "" { 
                self.alertMessage = error
                self.showAlert = true }
        }
        .onChange(of: cloudKit.isLoading) { _, isLoading in
            if !isLoading && cloudKit.CKErrorDesc == "" {
                loadingComplete = true
            } //TODO: Check if starts the main screen only if the cloudKit is OK
            else if cloudKit.CKErrorDesc != "" {
                
            }
        }
    }
    
    private func openICloudSettings() {
        if let url = URL(string: "App-Prefs:root=CASTLE") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func startAnimations() {
        withAnimation {
            showCode = true
        }
        startCodeAnimation()
    }
    
    @ViewBuilder
    private func codeView(geometry: GeometryProxy) -> some View {
        VStack(alignment: .trailing) {
            Spacer()
            ForEach(Array(codeLines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .foregroundColor(Color.white.opacity(0.8))
                    .font(Font.custom("SF Mono Semibold", size: 14)) //as per Font Book, not fileName
                    .bold()
                    .transition(.move(edge: .bottom))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing)
                    .padding(.bottom, 12)
            }
        }
        .frame(width: geometry.size.width, alignment: .trailing).padding(.bottom, 12)
    }


        private func startCodeAnimation() {
            let lines = Constants.assemblyCode.split(separator: "\n").map { String($0) }
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

