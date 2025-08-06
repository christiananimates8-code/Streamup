# StreamUp iOS App

A mobile-first social livestreaming platform where anyone can broadcast live video and interact with viewers in real-time. Built with SwiftUI and modern iOS development practices.

## 🎯 Features

### Core Livestreaming
- **Instant Go Live**: Start streaming with camera and microphone access
- **Multiple Stream Qualities**: 360p, 720p HD, 1080p HD, and 4K Ultra HD
- **Real-time Chat**: Interactive chat with viewers during streams
- **Stream Categories**: Gaming, Music, Art, Cooking, Fitness, Education, and more
- **Public/Private Streams**: Control who can watch your streams

### Co-Streaming & Social Features
- **Joined Lives**: Invite followers or friends to join your stream
- **Split-screen Mode**: Multiple participants in picture-in-picture layout
- **Multi-user Support**: Up to 4 participants at launch
- **Follow System**: Follow your favorite streamers
- **Real-time Notifications**: Get notified when followed streamers go live

### Gamification & Rewards
- **XP System**: Earn experience points for streaming, getting likes, and gaining followers
- **Level Progression**: Unlock new features as you level up
- **Achievement Badges**: Earn badges for milestones and accomplishments
- **Perk Unlocks**: Visual effects, higher quality streaming, longer stream time
- **Daily/Weekly Challenges**: Complete challenges for bonus XP
- **Leaderboards**: Compete with friends and community

### Discovery & Exploration
- **Trending Feed**: Discover popular live streams
- **Category Filters**: Browse streams by category
- **Search**: Find streams by username, topic, or hashtags
- **Personalized Recommendations**: Streams tailored to your interests

### Safety & Moderation
- **Chat Moderation**: Word filters, mute, and ban tools
- **Reporting System**: Report inappropriate content or users
- **Blocking**: Block users from your streams and chat
- **Age Restrictions**: Content guidelines and safety measures

## 🛠 Technical Architecture

### Frontend (iOS)
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for data binding
- **AVFoundation**: Camera and microphone access for streaming
- **Swift Package Manager**: Dependency management

### Backend Integration
- **REST API**: HTTP-based API communication using Alamofire
- **Socket.IO**: Real-time chat and live updates
- **WebRTC/RTMP**: Live video streaming protocols
- **Authentication**: JWT-based secure authentication

### Key Dependencies
- `Alamofire`: HTTP networking
- `SocketIO`: Real-time communication
- `ReactiveSwift`: Reactive programming extensions
- `SnapKit`: Auto Layout DSL
- `Kingfisher`: Image loading and caching
- `SwiftyJSON`: JSON parsing

## 📁 Project Structure

```
StreamUp/
├── Sources/StreamUp/
│   ├── StreamUpApp.swift              # Main app entry point
│   ├── Models/                        # Data models
│   │   ├── User.swift                 # User model with stats and achievements
│   │   └── Stream.swift               # Stream model with chat and co-streaming
│   ├── Services/                      # Business logic services
│   │   ├── NetworkService.swift       # API communication
│   │   ├── StreamingService.swift     # Live streaming functionality
│   │   ├── ChatService.swift          # Real-time chat
│   │   └── GamificationService.swift  # XP, levels, and rewards
│   └── Views/                         # SwiftUI views
│       ├── Authentication/            # Login and registration
│       ├── Home/                      # Home feed and discovery
│       └── GoLive/                    # Stream setup and controls
├── Package.swift                      # Swift Package Manager
├── Info.plist                        # App configuration
└── README.md                          # This file
```

## 🚀 Getting Started

### Prerequisites
- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- Active Apple Developer Account (for device testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/streamup-ios.git
   cd streamup-ios
   ```

2. **Open in Xcode**
   ```bash
   open Package.swift
   ```

3. **Install dependencies**
   Dependencies will be automatically resolved by Swift Package Manager when you build the project.

4. **Configure Info.plist**
   Update the bundle identifier and team settings in your project configuration.

5. **Run the app**
   Select your target device or simulator and press Cmd+R to build and run.

### Configuration

#### API Endpoints
Update the base URL in `NetworkService.swift`:
```swift
private let baseURL = "https://your-api-server.com/v1"
```

#### Socket.IO Server
Update the chat server URL in `ChatService.swift`:
```swift
guard let url = URL(string: "https://your-chat-server.com") else { return }
```

#### Streaming Server
Configure your RTMP/WebRTC streaming server endpoints in the streaming service.

## 🎮 Core Functionality

### Authentication Flow
1. Users can register with username, email, and password
2. Login with email/password authentication
3. JWT tokens stored securely for session management
4. Automatic token refresh and logout on expiration

### Streaming Workflow
1. **Setup Stream**: Choose title, description, category, and privacy settings
2. **Camera Preview**: Real-time camera preview with controls
3. **Go Live**: Start streaming with automatic server connection
4. **Stream Management**: Control camera, microphone, and stream quality
5. **End Stream**: Stop streaming and save stream data

### Chat System
1. **Real-time Messaging**: Instant chat during live streams
2. **Message Types**: Text, emojis, likes, system messages
3. **Moderation**: Delete messages, ban/mute users, slow mode
4. **Chat Commands**: Built-in commands for stream management

### Gamification System
1. **XP Calculation**: Points for streaming, likes, followers, chat activity
2. **Level Progression**: Automatic level-up with perk unlocks
3. **Challenge Tracking**: Daily and weekly challenge progress
4. **Badge System**: Achievement badges for milestones
5. **Leaderboards**: Weekly/monthly ranking system

## 📱 App Screens

### Main Navigation
- **Home**: Live stream feed and trending content
- **Discovery**: Search and browse streams by category
- **Go Live**: Stream setup and broadcasting
- **Notifications**: Stream alerts and activity updates
- **Profile**: User profile with stats and achievements

### Key Features by Screen

#### Home Screen
- Featured live stream carousel
- Category filter chips
- Live stream cards with viewer count and likes
- Pull-to-refresh for latest streams
- Search functionality

#### Go Live Screen
- Live camera preview with controls
- Stream configuration (title, description, category)
- Privacy and co-streaming settings
- Quality selection and status indicators
- One-tap streaming start

#### Profile Screen
- User stats (followers, likes, stream hours)
- Level progress and XP display
- Achievement badges showcase
- Stream history and highlights
- Settings and account management

## 🔒 Privacy & Security

### Permissions Required
- **Camera**: Video streaming capabilities
- **Microphone**: Audio for live streams
- **Photo Library**: Profile pictures and stream thumbnails
- **Location** (Optional): Nearby stream discovery

### Data Protection
- All API communication over HTTPS
- JWT token-based authentication
- No sensitive data stored locally
- Secure chat message transmission
- User privacy controls for streams

## 🎯 Future Enhancements

### Phase 2 Features
- **Stream Recording**: Save and replay past streams
- **Enhanced Co-streaming**: Screen sharing and guest management
- **Monetization**: Virtual gifts and subscription tiers
- **Analytics**: Detailed streaming insights and metrics
- **Push Notifications**: Real-time alerts and engagement

### Technical Improvements
- **Offline Mode**: Cache content for offline viewing
- **Performance Optimization**: Better streaming quality and battery life
- **Accessibility**: VoiceOver and accessibility improvements
- **Internationalization**: Multi-language support

## 📊 Performance Considerations

### Streaming Optimization
- Adaptive bitrate streaming based on network conditions
- Battery usage optimization during long streams
- Memory management for camera preview and chat
- Background audio support for co-streaming

### UI/UX Performance
- Lazy loading for stream feeds
- Image caching and optimization
- Smooth animations and transitions
- Responsive design for various screen sizes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- SwiftUI community for UI inspiration
- Socket.IO team for real-time communication
- AVFoundation documentation and examples
- iOS development community and open source contributors

---

**StreamUp** - Empowering everyone to go live instantly and connect with the world through livestreaming.