import SwiftUI
import OSLog

let log = Logger()

@main
struct iOSApp: App {
    @StateObject private var oauth = OAuthManager.shared
    @StateObject var refreshController = RefreshController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(oauth)
                .environmentObject(refreshController)
                .onOpenURL { url in
                    if oauth.resumeExternalUserAgentFlow(with: url) {
                        log.info("Resumed flow from redirect URI")
                    }
                }
        }
    }
}
