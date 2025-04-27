import SwiftUI
import OSLog

let log = Logger()

@main
struct iOSApp: App {
    @StateObject private var oauth = OAuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(oauth)
                .onOpenURL { url in
                    if oauth.resumeExternalUserAgentFlow(with: url) {
                        log.info("Resumed flow from redirect URI")
                    }
                }
        }
    }
}
