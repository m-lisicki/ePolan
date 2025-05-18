import SwiftUI
import OSLog
import Atlantis

let log = Logger()

@main
struct EPolan: App {
    
    init() {
        _ = OAuthManager.shared
        Atlantis.start()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
