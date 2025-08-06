import SwiftUI

@main
struct StreamUpApp: App {
    @StateObject private var networkService = NetworkService.shared
    @StateObject private var streamingService = StreamingService.shared
    @StateObject private var chatService = ChatService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(networkService)
                .environmentObject(streamingService)
                .environmentObject(chatService)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Connect chat service if user is authenticated
                    if networkService.isAuthenticated {
                        chatService.connect()
                    }
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var networkService: NetworkService
    
    var body: some View {
        Group {
            if networkService.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkService.isAuthenticated)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            DiscoveryView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Discover")
                }
                .tag(1)
            
            GoLiveView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Go Live")
                }
                .tag(2)
            
            NotificationsView()
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("Notifications")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.purple)
        .preferredColorScheme(.dark)
    }
}