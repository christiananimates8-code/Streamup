import SwiftUI

struct HomeView: View {
    @State private var liveStreams: [Stream] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedCategory: StreamCategory? = nil
    
    @EnvironmentObject var networkService: NetworkService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Search and filters
                    searchAndFiltersView
                    
                    // Content
                    if isLoading {
                        loadingView
                    } else {
                        contentView
                    }
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .refreshable {
                await loadLiveStreams()
            }
        }
        .onAppear {
            Task {
                await loadLiveStreams()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("StreamUp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let user = networkService.currentUser {
                    Text("Welcome back, \(user.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Notifications button
            Button(action: {
                // Navigate to notifications
            }) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "bell")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var searchAndFiltersView: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search streams...", text: $searchText)
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            // Category filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryFilterChip(
                        title: "All",
                        isSelected: selectedCategory == nil,
                        action: {
                            selectedCategory = nil
                            Task { await loadLiveStreams() }
                        }
                    )
                    
                    ForEach(StreamCategory.allCases, id: \.self) { category in
                        CategoryFilterChip(
                            title: category.displayName,
                            isSelected: selectedCategory == category,
                            action: {
                                selectedCategory = category
                                Task { await loadLiveStreams() }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }
    
    private var contentView: some View {
        LazyVStack(spacing: 16) {
            if filteredStreams.isEmpty {
                emptyStateView
            } else {
                // Featured stream
                if let featuredStream = filteredStreams.first {
                    FeaturedStreamCard(stream: featuredStream)
                        .padding(.horizontal, 20)
                }
                
                // Live streams grid
                ForEach(Array(filteredStreams.dropFirst().enumerated()), id: \.element.id) { index, stream in
                    StreamCard(stream: stream)
                        .padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, 100)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                .scaleEffect(1.5)
            
            Text("Loading streams...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No live streams")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Be the first to go live!")
                    .foregroundColor(.gray)
            }
            
            Button(action: {
                // Navigate to Go Live tab
            }) {
                Text("Start Streaming")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var filteredStreams: [Stream] {
        var streams = liveStreams
        
        if let category = selectedCategory {
            streams = streams.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            streams = streams.filter { stream in
                stream.title.localizedCaseInsensitiveContains(searchText) ||
                stream.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return streams
    }
    
    private func loadLiveStreams() async {
        isLoading = true
        
        do {
            let response = try await networkService.getLiveStreams()
            DispatchQueue.main.async {
                self.liveStreams = response.streams
                self.isLoading = false
            }
        } catch {
            print("Failed to load streams: \(error)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}

struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white : Color.gray.opacity(0.3))
                .cornerRadius(16)
        }
    }
}

struct FeaturedStreamCard: View {
    let stream: Stream
    
    var body: some View {
        NavigationLink(destination: StreamDetailView(stream: stream)) {
            ZStack(alignment: .bottomLeading) {
                // Thumbnail/Preview
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.purple, .blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 200)
                
                // Overlay info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // Live indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text("LIVE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        
                        Spacer()
                        
                        // Viewer count
                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                            Text("\(stream.viewerCount)")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stream.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text(stream.category.displayName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StreamCard: View {
    let stream: Stream
    
    var body: some View {
        NavigationLink(destination: StreamDetailView(stream: stream)) {
            HStack(spacing: 12) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.purple.opacity(0.6), .blue.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 60)
                    
                    // Live indicator
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 4, height: 4)
                                
                                Text("LIVE")
                                    .font(.system(size: 8))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                        }
                    }
                    .padding(4)
                }
                
                // Stream info
                VStack(alignment: .leading, spacing: 4) {
                    Text(stream.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(stream.category.displayName)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                            Text("\(stream.viewerCount)")
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                            Text("\(stream.totalLikes)")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView()
        .environmentObject(NetworkService.shared)
        .preferredColorScheme(.dark)
}