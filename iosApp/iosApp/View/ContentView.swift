import SwiftUI
import Shared


struct ContentView: View {
    @EnvironmentObject var oauth: OAuthManager
    
    var body: some View {
        if oauth.authState == nil {
            SignInView()
        } else {
            BottomBarView()
        }
    }
}

#Preview {
    NavigationView {
        ContentView()
    }
}

struct BottomBarView: View {
    @State var accentColor: Color = .accentColor
    
    var body: some View {
        TabView {
            CourseView()
                .tabItem {
                    Label("Courses", systemImage: "book")
                }
            UserManagementView(accentColor: $accentColor)
                .tabItem {
                    Label("User", systemImage: "person.crop.circle")
                }
        }
        .tint(accentColor)
    }
}
