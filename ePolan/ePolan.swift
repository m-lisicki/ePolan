import SwiftUI
import OSLog
import Atlantis

let log = Logger()

@main
struct EPolan: App {
    var oauth = OAuthManager.shared
    var networkMonitor = NetworkMonitor()
    
    init() {
        Atlantis.start()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(oauth)
                .environment(networkMonitor)
        }
    }
}
