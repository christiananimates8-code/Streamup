// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StreamUp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "StreamUp",
            targets: ["StreamUp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/socketio/socket.io-client-swift", from: "16.0.0"),
        .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "7.1.0"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.6.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.9.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.1")
    ],
    targets: [
        .target(
            name: "StreamUp",
            dependencies: [
                "Alamofire",
                .product(name: "SocketIO", package: "socket.io-client-swift"),
                "ReactiveSwift",
                "SnapKit",
                "Kingfisher",
                "SwiftyJSON"
            ]
        ),
        .testTarget(
            name: "StreamUpTests",
            dependencies: ["StreamUp"]
        ),
    ]
)