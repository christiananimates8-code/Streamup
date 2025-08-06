import Foundation
import AVFoundation
import UIKit
import Combine

class StreamingService: NSObject, ObservableObject {
    static let shared = StreamingService()
    
    // MARK: - Published Properties
    @Published var isStreaming = false
    @Published var isPaused = false
    @Published var streamQuality: StreamQuality = .medium
    @Published var isCameraEnabled = true
    @Published var isMicrophoneEnabled = true
    @Published var cameraPosition: AVCaptureDevice.Position = .front
    @Published var connectionState: ConnectionState = .disconnected
    @Published var viewerCount = 0
    @Published var streamDuration: TimeInterval = 0
    
    // MARK: - Private Properties
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var audioOutput: AVCaptureAudioDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var streamURL: String?
    private var streamKey: String?
    private var currentStream: Stream?
    
    // Co-streaming
    private var coStreamers: [CoStreamer] = []
    private var maxCoStreamers = 3
    
    // Timer for duration tracking
    private var streamTimer: Timer?
    private var startTime: Date?
    
    private override init() {
        super.init()
        setupCaptureSession()
    }
    
    // MARK: - Setup Methods
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        
        captureSession.sessionPreset = streamQuality.sessionPreset
        
        setupVideoInput()
        setupAudioInput()
        setupVideoOutput()
        setupAudioOutput()
    }
    
    private func setupVideoInput() {
        guard let captureSession = captureSession else { return }
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else {
            print("Failed to get camera device")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
        } catch {
            print("Failed to setup video input: \(error)")
        }
    }
    
    private func setupAudioInput() {
        guard let captureSession = captureSession else { return }
        
        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            print("Failed to get microphone device")
            return
        }
        
        do {
            let audioInput = try AVCaptureDeviceInput(device: microphone)
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
        } catch {
            print("Failed to setup audio input: \(error)")
        }
    }
    
    private func setupVideoOutput() {
        guard let captureSession = captureSession else { return }
        
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }
    
    private func setupAudioOutput() {
        guard let captureSession = captureSession else { return }
        
        audioOutput = AVCaptureAudioDataOutput()
        audioOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "audioQueue"))
        
        if let audioOutput = audioOutput, captureSession.canAddOutput(audioOutput) {
            captureSession.addOutput(audioOutput)
        }
    }
    
    // MARK: - Permission Handling
    
    func requestPermissions() async -> Bool {
        let cameraPermission = await requestCameraPermission()
        let microphonePermission = await requestMicrophonePermission()
        return cameraPermission && microphonePermission
    }
    
    private func requestCameraPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Stream Management
    
    func createStream(title: String, description: String?, category: StreamCategory, isPrivate: Bool = false) async throws -> Stream {
        let request = CreateStreamRequest(
            title: title,
            description: description,
            category: category,
            isPrivate: isPrivate,
            allowCoStreaming: true,
            maxCoStreamers: maxCoStreamers,
            tags: []
        )
        
        let stream = try await NetworkService.shared.createStream(request)
        self.currentStream = stream
        return stream
    }
    
    func startStream() async throws {
        guard let currentStream = currentStream else {
            throw StreamingError.noStreamCreated
        }
        
        let hasPermissions = await requestPermissions()
        guard hasPermissions else {
            throw StreamingError.permissionDenied
        }
        
        let streamKey = try await NetworkService.shared.startStream(streamId: currentStream.id)
        self.streamURL = streamKey.streamURL
        self.streamKey = streamKey.streamKey
        
        DispatchQueue.main.async {
            self.connectionState = .connecting
        }
        
        try await startCapture()
        
        DispatchQueue.main.async {
            self.isStreaming = true
            self.connectionState = .connected
            self.startTime = Date()
            self.startStreamTimer()
        }
    }
    
    func endStream() async throws {
        guard let currentStream = currentStream else { return }
        
        stopCapture()
        stopStreamTimer()
        
        try await NetworkService.shared.endStream(streamId: currentStream.id)
        
        DispatchQueue.main.async {
            self.isStreaming = false
            self.connectionState = .disconnected
            self.streamDuration = 0
            self.currentStream = nil
            self.streamURL = nil
            self.streamKey = nil
        }
    }
    
    func pauseStream() {
        DispatchQueue.main.async {
            self.isPaused = true
        }
        // Implement RTMP pause if supported
    }
    
    func resumeStream() {
        DispatchQueue.main.async {
            self.isPaused = false
        }
        // Implement RTMP resume if supported
    }
    
    // MARK: - Capture Control
    
    private func startCapture() async throws {
        guard let captureSession = captureSession else {
            throw StreamingError.captureSessionNotConfigured
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    private func stopCapture() {
        guard let captureSession = captureSession else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.stopRunning()
        }
    }
    
    // MARK: - Camera Controls
    
    func switchCamera() {
        let newPosition: AVCaptureDevice.Position = cameraPosition == .front ? .back : .front
        
        guard let captureSession = captureSession else { return }
        
        captureSession.beginConfiguration()
        
        // Remove current video input
        if let currentInput = captureSession.inputs.first(where: { $0 is AVCaptureDeviceInput && ($0 as! AVCaptureDeviceInput).device.hasMediaType(.video) }) {
            captureSession.removeInput(currentInput)
        }
        
        // Add new video input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                DispatchQueue.main.async {
                    self.cameraPosition = newPosition
                }
            }
        } catch {
            print("Failed to switch camera: \(error)")
        }
        
        captureSession.commitConfiguration()
    }
    
    func toggleCamera() {
        DispatchQueue.main.async {
            self.isCameraEnabled.toggle()
        }
        // Implement camera toggle logic
    }
    
    func toggleMicrophone() {
        DispatchQueue.main.async {
            self.isMicrophoneEnabled.toggle()
        }
        // Implement microphone toggle logic
    }
    
    // MARK: - Quality Control
    
    func updateStreamQuality(_ quality: StreamQuality) {
        guard let captureSession = captureSession else { return }
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = quality.sessionPreset
        captureSession.commitConfiguration()
        
        DispatchQueue.main.async {
            self.streamQuality = quality
        }
    }
    
    // MARK: - Co-Streaming
    
    func inviteCoStreamer(userId: String) async throws {
        guard let currentStream = currentStream else {
            throw StreamingError.noStreamCreated
        }
        
        try await NetworkService.shared.inviteToCoStream(streamId: currentStream.id, userId: userId)
    }
    
    func acceptCoStreamInvite(streamId: String, inviteCode: String) async throws {
        let response = try await NetworkService.shared.joinCoStream(streamId: streamId, inviteCode: inviteCode)
        
        if response.success {
            // Setup co-streaming configuration
            DispatchQueue.main.async {
                // Update UI for co-streaming mode
            }
        }
    }
    
    func removeCoStreamer(coStreamerId: String) async throws {
        guard let currentStream = currentStream else { return }
        
        try await NetworkService.shared.leaveCoStream(streamId: currentStream.id)
        
        DispatchQueue.main.async {
            self.coStreamers.removeAll { $0.id == coStreamerId }
        }
    }
    
    // MARK: - Preview Layer
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let captureSession = captureSession else { return nil }
        
        if previewLayer == nil {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
        }
        
        return previewLayer
    }
    
    // MARK: - Timer Management
    
    private func startStreamTimer() {
        streamTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = self.startTime {
                DispatchQueue.main.async {
                    self.streamDuration = Date().timeIntervalSince(startTime)
                }
            }
        }
    }
    
    private func stopStreamTimer() {
        streamTimer?.invalidate()
        streamTimer = nil
        startTime = nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate

extension StreamingService: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Process video/audio frames for RTMP streaming
        // This would typically involve encoding the frames and sending them via RTMP
        
        if output == videoOutput {
            // Process video frame
            processVideoFrame(sampleBuffer)
        } else if output == audioOutput {
            // Process audio frame
            processAudioFrame(sampleBuffer)
        }
    }
    
    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        // Encode and stream video frame
        // Implementation would depend on the RTMP library used
    }
    
    private func processAudioFrame(_ sampleBuffer: CMSampleBuffer) {
        // Encode and stream audio frame
        // Implementation would depend on the RTMP library used
    }
}

// MARK: - Supporting Types

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case failed
}

enum StreamingError: Error, LocalizedError {
    case permissionDenied
    case noStreamCreated
    case captureSessionNotConfigured
    case streamingFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera and microphone permissions are required for streaming"
        case .noStreamCreated:
            return "No stream has been created"
        case .captureSessionNotConfigured:
            return "Capture session is not properly configured"
        case .streamingFailed:
            return "Failed to start streaming"
        case .networkError:
            return "Network error occurred while streaming"
        }
    }
}

extension StreamQuality {
    var sessionPreset: AVCaptureSession.Preset {
        switch self {
        case .low:
            return .medium
        case .medium:
            return .high
        case .high:
            return .hd1920x1080
        case .ultra:
            return .hd4K3840x2160
        }
    }
}