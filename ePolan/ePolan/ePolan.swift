import SwiftUI
import OSLog

let log = Logger()

@main
struct EPolan: App {
    let oauth = OAuthManager.shared
    @State var refreshController = RefreshController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(oauth)
                .environment(refreshController)
        }
    }
}
