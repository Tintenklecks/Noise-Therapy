import SwiftUI
import AVFoundation
import Combine

// MARK: - 1. The View
struct HeadphoneStatusView: View {
    // Inject the monitor engine
    @StateObject private var audioMonitor = AudioOutputMonitor()
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. Dynamic Icon
            Image(systemName: iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(statusColor)
                .symbolEffect(.bounce, value: audioMonitor.outputType) // Bounces when changed (iOS 17+)
            
            // 2. Status Text
            Text(audioMonitor.connectionStatus)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // 3. Detailed Output Name
            Text("Current Output: \(audioMonitor.currentOutputName)")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 5)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(20)
        .padding()
    }
    
    // Helper to choose the icon based on output type
    private var iconName: String {
        switch audioMonitor.outputType {
        case .wireless: return "airpods"
        case .wired: return "headphones"
        case .speaker: return "speaker.wave.2"
        }
    }
    
    // Helper to choose color
    private var statusColor: Color {
        switch audioMonitor.outputType {
        case .wireless: return .blue
        case .wired: return .green
        case .speaker: return .gray
        }
    }
}

// MARK: - 2. The Engine
class AudioOutputMonitor: ObservableObject {
    
    // Define the types of outputs we care about
    enum AudioOutputType {
        case speaker
        case wired
        case wireless
    }
    
    // Published properties trigger UI updates automatically
    @Published var outputType: AudioOutputType = .speaker
    @Published var connectionStatus: String = "No Headphones"
    @Published var currentOutputName: String = "Speaker"
    
    private var notificationObserver: Any?
    
    init() {
        // 1. Initial check when app launches
        checkCurrentRoute()
        
        // 2. Setup the listener for dynamic changes (plugging in/out)
        setupNotifications()
    }
    
    deinit {
        // Clean up notification observer
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupNotifications() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // When a route change happens, re-check the connections
            self?.handleRouteChange(notification)
        }
    }
    
    private func handleRouteChange(_ notification: Notification) {
        // Optional: You can check the "reason" here if you need specific logic
        // (e.g. only react to .newDeviceAvailable), but checking the current
        // route is the most robust way to get the *current* state.
        checkCurrentRoute()
    }
    
    private func checkCurrentRoute() {
        let session = AVAudioSession.sharedInstance()
        let currentRoute = session.currentRoute
        
        // 1. Get the primary output (usually the first one)
        guard let output = currentRoute.outputs.first else { return }
        
        // 2. Update the name for debugging/UI
        self.currentOutputName = output.portName
        
        // 3. Determine the type
        switch output.portType {
            // Wireless Types
            case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE, .airPlay:
                self.outputType = .wireless
                self.connectionStatus = "Wireless / AirPods Connected"
                
            // Wired Types
            case .headphones, .usbAudio:
                self.outputType = .wired
                self.connectionStatus = "Wired Headphones Connected"
                
            // Speaker / Default Types
            case .builtInSpeaker, .builtInReceiver:
                self.outputType = .speaker
                self.connectionStatus = "Using Device Speaker"
                
            // HDMI / Car Audio / Others
            default:
                self.outputType = .speaker // Treat unknown as speaker/external
                self.connectionStatus = "External Audio (\(output.portName))"
        }
    }
}

// MARK: - Preview
#Preview {
    HeadphoneStatusView()
}
