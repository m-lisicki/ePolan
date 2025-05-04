import SwiftUI
import OSLog

let log = Logger()

@main
struct EPolan: App {
    @State private var oauth = OAuthManager.shared
    @State var refreshController = RefreshController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(oauth)
                .environment(refreshController)
                .onOpenURL { url in
                    if oauth.resumeExternalUserAgentFlow(with: url) {
                        log.info("Resumed flow from redirect URI")
                    }
                }
        }
    }
}
