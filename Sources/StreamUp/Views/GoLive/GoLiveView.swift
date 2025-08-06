import SwiftUI
import AVFoundation

struct GoLiveView: View {
    @State private var streamTitle = ""
    @State private var streamDescription = ""
    @State private var selectedCategory: StreamCategory = .entertainment
    @State private var isPrivate = false
    @State private var allowCoStreaming = true
    @State private var maxCoStreamers = 3
    @State private var isSettingUpStream = false
    @State private var showingStreamView = false
    @State private var showingCameraPermissionAlert = false
    @State private var errorMessage: String?
    
    @EnvironmentObject var streamingService: StreamingService
    @EnvironmentObject var networkService: NetworkService
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if streamingService.isStreaming {
                    LiveStreamView()
                } else {
                    setupView
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingStreamView) {
            LiveStreamView()
        }
        .alert("Camera Permission Required", isPresented: $showingCameraPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("StreamUp needs access to your camera and microphone to stream. Please enable permissions in Settings.")
        }
    }
    
    private var setupView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Camera preview
                cameraPreviewView
                
                // Stream settings
                streamSettingsView
                
                // Go Live button
                goLiveButton
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Go Live")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Set up your stream and share with the world")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var cameraPreviewView: some View {
        ZStack {
            // Camera preview container
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 250)
                .overlay(
                    CameraPreviewView()
                        .cornerRadius(16)
                )
            
            // Controls overlay
            VStack {
                HStack {
                    Spacer()
                    
                    // Camera controls
                    HStack(spacing: 12) {
                        // Switch camera
                        Button(action: {
                            streamingService.switchCamera()
                        }) {
                            Image(systemName: "camera.rotate")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        // Toggle camera
                        Button(action: {
                            streamingService.toggleCamera()
                        }) {
                            Image(systemName: streamingService.isCameraEnabled ? "video" : "video.slash")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        // Toggle microphone
                        Button(action: {
                            streamingService.toggleMicrophone()
                        }) {
                            Image(systemName: streamingService.isMicrophoneEnabled ? "mic" : "mic.slash")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                }
                
                Spacer()
                
                // Quality indicator
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(streamingService.connectionState == .connected ? .green : .gray)
                            .frame(width: 8, height: 8)
                        
                        Text(streamingService.streamQuality.displayName)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(16)
                    
                    Spacer()
                }
            }
            .padding(16)
        }
    }
    
    private var streamSettingsView: some View {
        VStack(spacing: 20) {
            // Stream title
            VStack(alignment: .leading, spacing: 8) {
                Text("Stream Title")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("What's your stream about?", text: $streamTitle)
                    .textFieldStyle(StreamTextFieldStyle())
            }
            
            // Stream description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Tell viewers what to expect...", text: $streamDescription, axis: .vertical)
                    .textFieldStyle(StreamTextFieldStyle())
                    .lineLimit(3...6)
            }
            
            // Category selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Menu {
                    ForEach(StreamCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedCategory.icon)
                        Text(selectedCategory.displayName)
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
            }
            
            // Stream options
            VStack(spacing: 16) {
                // Private stream toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Private Stream")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Only people you invite can watch")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isPrivate)
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                }
                
                // Co-streaming toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Allow Co-streaming")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Let others join your stream")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $allowCoStreaming)
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                }
                
                // Max co-streamers (if enabled)
                if allowCoStreaming {
                    HStack {
                        Text("Max Co-streamers")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Picker("Max Co-streamers", selection: $maxCoStreamers) {
                            ForEach(1...4, id: \.self) { count in
                                Text("\(count)").tag(count)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .accentColor(.purple)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var goLiveButton: some View {
        Button(action: {
            Task {
                await startLiveStream()
            }
        }) {
            HStack(spacing: 12) {
                if isSettingUpStream {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "video.fill")
                        .font(.system(size: 20))
                }
                
                Text(isSettingUpStream ? "Setting Up..." : "Go Live")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.purple, .pink]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .disabled(isSettingUpStream || streamTitle.isEmpty)
        .opacity(streamTitle.isEmpty ? 0.6 : 1.0)
    }
    
    private func startLiveStream() async {
        isSettingUpStream = true
        errorMessage = nil
        
        do {
            // Create stream
            let stream = try await streamingService.createStream(
                title: streamTitle,
                description: streamDescription.isEmpty ? nil : streamDescription,
                category: selectedCategory,
                isPrivate: isPrivate
            )
            
            // Start streaming
            try await streamingService.startStream()
            
            DispatchQueue.main.async {
                self.showingStreamView = true
                self.isSettingUpStream = false
            }
            
        } catch StreamingError.permissionDenied {
            DispatchQueue.main.async {
                self.showingCameraPermissionAlert = true
                self.isSettingUpStream = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isSettingUpStream = false
            }
        }
    }
}

struct StreamTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .foregroundColor(.white)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
    }
}

struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        if let previewLayer = StreamingService.shared.getPreviewLayer() {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

// Additional views would be defined here: DiscoveryView, ProfileView, NotificationsView, LiveStreamView, StreamDetailView

struct DiscoveryView: View {
    var body: some View {
        Text("Discovery View")
            .foregroundColor(.white)
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profile View")
            .foregroundColor(.white)
    }
}

struct NotificationsView: View {
    var body: some View {
        Text("Notifications View")
            .foregroundColor(.white)
    }
}

struct LiveStreamView: View {
    var body: some View {
        Text("Live Stream View")
            .foregroundColor(.white)
    }
}

struct StreamDetailView: View {
    let stream: Stream
    
    var body: some View {
        Text("Stream Detail View")
            .foregroundColor(.white)
    }
}

#Preview {
    GoLiveView()
        .environmentObject(StreamingService.shared)
        .environmentObject(NetworkService.shared)
        .preferredColorScheme(.dark)
}