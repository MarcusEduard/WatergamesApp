import SwiftUI
import Firebase

@main
struct WatergamesApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
