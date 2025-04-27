import SwiftUI
import Shared

struct ContentView: View {
#if RELEASE
    @EnvironmentObject var oauth: OAuthManager
#endif
    
    var body: some View {
#if RELEASE
        if oauth.authState == nil {
            SignInView()
        } else {
            BottomBarView()
        }
#else
        BottomBarView()
#endif
    }
}

#Preview {
    NavigationView {
        ContentView()
    }
}

struct BottomBarView: View {
    var body: some View {
        TabView {
            PointsView()
                .tabItem {
                    Label("Points", systemImage: "star")
                }
            UserManagementView()
                .tabItem {
                    Label("User", systemImage: "person.crop.circle")
                }
        }
    }
}
