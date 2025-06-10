import OSLog
import SwiftUI

let log = Logger()

@main
struct EPolan: App {
    init() {
        _ = OAuthManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
