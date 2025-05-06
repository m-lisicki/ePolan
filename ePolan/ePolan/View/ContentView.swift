import SwiftUI
import Shared


struct ContentView: View {
    @Environment(OAuthManager.self) var oauth: OAuthManager
    
    var body: some View {
        VStack {
            if !OAuthManager.shared.changePleaseGo {
                SignInView()
            } else {
                BottomBarView()
            }
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
