import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var opacity = 0.0

    var body: some View {
        if isActive {
            ContentView() 
        } else {
            VStack {
                Image("logo")
                    .resizable()
                    .scaledToFit() 
                    .frame(width: UIScreen.main.bounds.width * 0.7)
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 1.5)) {
                    self.opacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}
