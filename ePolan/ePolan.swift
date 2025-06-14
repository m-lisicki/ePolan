import OSLog
import SwiftUI

let log = Logger()

@main
struct EPolan: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
#if os(macOS)
        Settings {
            UserManagementView()
        }
#endif
    }
}
