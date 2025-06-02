import Atlantis
import OSLog
import SwiftUI

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
