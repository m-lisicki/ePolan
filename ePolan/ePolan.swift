import SwiftUI
import OSLog

let log = Logger()

@main
struct EPolan: App {
    var oauth = OAuthManager.shared
    var refreshController = RefreshController()
    var networkMonitor = NetworkMonitor()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(oauth)
                .environment(refreshController)
                .environment(networkMonitor)
        }
    }
}
