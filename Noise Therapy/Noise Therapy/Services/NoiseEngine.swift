import AVFoundation
import Combine
import Foundation

final class NoiseEngine: ObservableObject {
    private let engine = AVAudioEngine()

    // Stereo Chain
    private var leftSource: AVAudioSourceNode!
    private var rightSource: AVAudioSourceNode!

    private let leftEQ = AVAudioUnitEQ(numberOfBands: 1)
    private let rightEQ = AVAudioUnitEQ(numberOfBands: 1)

    // Intermediate mixers for panning each channel
    private let leftMixer = AVAudioMixerNode()
    private let rightMixer = AVAudioMixerNode()

    private let mainMixer: AVAudioMixerNode

    @Published var isRunning: Bool = false

    // MARK: - UI & State
    @Published var selectedEar: EarSetting = .both

    // MARK: - Preset Management
    @Published var presets: [Preset] = []
    @Published var currentPresetId: UUID? {
        didSet {
            if let id = currentPresetId, let preset = presets.first(where: { $0.id == id }) {
                loadPreset(preset)
            }
        }
    }

    private let presetsKey = "savedPresets"
    private let currentPresetIdKey = "currentPresetId"

    // MARK: - Active Settings (In-Memory)
    // When selectedEar == .both, we edit these "Base" values.
    // When selectedEar == .left/right, we edit the overrides (optionals).

    // Base Values
    @Published var noiseTypeBase: NoiseType = .white { didSet { updateAudioState() } }
    @Published var volumeBase: Float = 0.2 { didSet { updateAudioState() } }
    @Published var centerFrequencyBase: Float = 8000 { didSet { updateAudioState() } }
    @Published var bandwidthBase: Float = 1.0 { didSet { updateAudioState() } }

    // Overrides
    @Published var noiseTypeLeft: NoiseType? { didSet { updateAudioState() } }
    @Published var volumeLeft: Float? { didSet { updateAudioState() } }
    @Published var centerFrequencyLeft: Float? { didSet { updateAudioState() } }
    @Published var bandwidthLeft: Float? { didSet { updateAudioState() } }

    @Published var noiseTypeRight: NoiseType? { didSet { updateAudioState() } }
    @Published var volumeRight: Float? { didSet { updateAudioState() } }
    @Published var centerFrequencyRight: Float? { didSet { updateAudioState() } }
    @Published var bandwidthRight: Float? { didSet { updateAudioState() } }

    // Computed Bindings for UI
    var activeNoiseType: NoiseType {
        get {
            switch selectedEar {
            case .both: return noiseTypeBase
            case .left: return noiseTypeLeft ?? noiseTypeBase
            case .right: return noiseTypeRight ?? noiseTypeBase
            }
        }
        set {
            switch selectedEar {
            case .both: noiseTypeBase = newValue
            case .left: noiseTypeLeft = newValue
            case .right: noiseTypeRight = newValue
            }
            updateAudioState()
            autoSaveCurrentPreset()
        }
    }

    var activeVolume: Float {
        get {
            switch selectedEar {
            case .both: return volumeBase
            case .left: return volumeLeft ?? volumeBase
            case .right: return volumeRight ?? volumeBase
            }
        }
        set {
            switch selectedEar {
            case .both: volumeBase = newValue
            case .left: volumeLeft = newValue
            case .right: volumeRight = newValue
            }
            updateAudioState()
            autoSaveCurrentPreset()
        }
    }

    var activeCenterFrequency: Float {
        get {
            switch selectedEar {
            case .both: return centerFrequencyBase
            case .left: return centerFrequencyLeft ?? centerFrequencyBase
            case .right: return centerFrequencyRight ?? centerFrequencyBase
            }
        }
        set {
            switch selectedEar {
            case .both: centerFrequencyBase = newValue
            case .left: centerFrequencyLeft = newValue
            case .right: centerFrequencyRight = newValue
            }
            updateAudioState()
            autoSaveCurrentPreset()
        }
    }

    var activeBandwidth: Float {
        get {
            switch selectedEar {
            case .both: return bandwidthBase
            case .left: return bandwidthLeft ?? bandwidthBase
            case .right: return bandwidthRight ?? bandwidthBase
            }
        }
        set {
            switch selectedEar {
            case .both: bandwidthBase = newValue
            case .left: bandwidthLeft = newValue
            case .right: bandwidthRight = newValue
            }
            updateAudioState()
            autoSaveCurrentPreset()
        }
    }

    // MARK: - Internal Generator Filters
    private var brownLastLeft: Float = 0.0
    private var pinkStateLeft: [Float] = Array(repeating: 0, count: 7)

    private var brownLastRight: Float = 0.0
    private var pinkStateRight: [Float] = Array(repeating: 0, count: 7)

    @Published var isHeadphonesConnected: Bool = false

    init() {
        mainMixer = engine.mainMixerNode

        setupAudioSession()
        setupEngine()
        setupRouteMonitoring()

        // Load presets after setup
        loadPresets()
        updateAudioState()  // Apply initial loaded preset or default state

        // Initial check
        checkHeadphoneConnection()
    }

    private func setupAudioSession() {
        #if os(iOS) || targetEnvironment(macCatalyst)
            let session = AVAudioSession.sharedInstance()
            do {
                // .playback category defaults to high-quality output (AirPlay/A2DP allowed).
                // .allowBluetooth/.allowBluetoothA2DP are only valid for .playAndRecord.
                try session.setCategory(
                    .playback, mode: .default,
                    options: [.mixWithOthers])
                try session.setActive(true)
            } catch {
                print("AudioSession error (Safe to ignore on macOS if sound plays): \(error)")
            }
        #endif
    }

    private func setupRouteMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleRouteChange(notification: Notification) {
        checkHeadphoneConnection()

        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else { return }

        // If device disconnected or we just determined no headphones are connected
        if reason == .oldDeviceUnavailable || !isHeadphonesConnected {
            if isRunning && !isHeadphonesConnected {
                print("Headphones disconnected, stopping therapy.")
                stop()
            }
        }
    }

    private func checkHeadphoneConnection() {
        #if os(iOS)
            // On iOS App on Mac (Designed for iPhone/iPad), os(iOS) is true, but behavioral is Mac-like.
            // We should detect if we are running in that environment.
            let isiOSAppOnMac = ProcessInfo.processInfo.isiOSAppOnMac

            if isiOSAppOnMac {
                print("Debug: Running as iOS App on Mac. Bypassing strict headphone check.")
                DispatchQueue.main.async { self.isHeadphonesConnected = true }
                return
            }

            // Real iOS device logic
            try? AVAudioSession.sharedInstance().setActive(true)

            let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
            let headphonePortTypes: [AVAudioSession.Port] = [
                .headphones,
                .bluetoothA2DP,
                .bluetoothLE,
                .bluetoothHFP,
                .airPlay,
            ]

            let connected = outputs.contains { headphonePortTypes.contains($0.portType) }

            if !connected {
                let portNames = outputs.map { $0.portType.rawValue }.joined(separator: ", ")
                print("Debug: No headphones detected. Current outputs: [\(portNames)]")
            }

            DispatchQueue.main.async {
                self.isHeadphonesConnected = connected
            }
        #else
            // macOS (Native or unknown): Bypass check.
            print("Debug: Non-iOS platform detected. Bypassing headphone check.")
            DispatchQueue.main.async {
                self.isHeadphonesConnected = true
            }
        #endif
    }

    private func setupEngine() {
        // Output format (Hardware)
        let hwFormat = engine.outputNode.inputFormat(forBus: 0)
        // Ensure we use a standard stereo format for the entire chain to avoid any mono downmixing
        let stereoFormat = AVAudioFormat(
            standardFormatWithSampleRate: hwFormat.sampleRate, channels: 2)!

        // --- LEFT CHANNEL ---
        // Configured to output stereo, but we will only write to the LEFT buffer
        leftSource = AVAudioSourceNode {
            [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            return self.render(
                channel: .left, frameCount: frameCount,
                audioBufferList: UnsafeMutableAudioBufferListPointer(audioBufferList))
        }

        // --- RIGHT CHANNEL ---
        // Configured to output stereo, but we will only write to the RIGHT buffer
        rightSource = AVAudioSourceNode {
            [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            return self.render(
                channel: .right, frameCount: frameCount,
                audioBufferList: UnsafeMutableAudioBufferListPointer(audioBufferList))
        }

        engine.attach(leftSource)
        engine.attach(rightSource)
        engine.attach(leftEQ)
        engine.attach(rightEQ)
        engine.attach(leftMixer)
        engine.attach(rightMixer)

        // Wiring: All Stereo now.
        // Source (Stereo) -> EQ (Stereo) -> ChannelMixer (Stereo) -> MainMixer

        // Left Chain
        engine.connect(leftSource, to: leftEQ, format: stereoFormat)
        engine.connect(leftEQ, to: leftMixer, format: stereoFormat)
        engine.connect(leftMixer, to: mainMixer, format: stereoFormat)

        // Right Chain
        engine.connect(rightSource, to: rightEQ, format: stereoFormat)
        engine.connect(rightEQ, to: rightMixer, format: stereoFormat)
        engine.connect(rightMixer, to: mainMixer, format: stereoFormat)

        // Set initial pan for channel mixers as a safeguard, though explicit buffer filling handles separation.
        leftMixer.pan = -1.0  // Full left
        rightMixer.pan = 1.0  // Full right

        // Apply initial volume scaling to main mixer (overall output)
        mainMixer.outputVolume = 1.0
    }

    private func render(
        channel: EarSetting, frameCount: AVAudioFrameCount,
        audioBufferList: UnsafeMutableAudioBufferListPointer
    ) -> OSStatus {
        let ablPointer = audioBufferList

        // Determine settings for this source's target channel
        // Note: 'channel' here tells us WHICH source node called this (LeftSource or RightSource).
        let type: NoiseType
        if channel == .left {
            type = noiseTypeLeft ?? noiseTypeBase
        } else {
            type = noiseTypeRight ?? noiseTypeBase
        }

        // We expect 2 buffers because we are using stereoFormat.
        // buffer[0] = Left, buffer[1] = Right
        // If we are LeftSource, we fill buffer[0] and clear buffer[1].
        // If we are RightSource, we clear buffer[0] and fill buffer[1].

        // Safety check
        if ablPointer.count < 2 {
            // Fallback for some unexpected mono setup, though shouldn't happen with our stereoFormat.
            // Just fill available buffers.
            for frame in 0..<Int(frameCount) {
                let sample = generateSample(for: type, channel: channel)
                for buffer in ablPointer {
                    let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = sample
                }
            }
            return noErr
        }

        // Get pointers to Left and Right buffers
        let leftPtr = ablPointer[0].mData!.assumingMemoryBound(to: Float.self)
        let rightPtr = ablPointer[1].mData!.assumingMemoryBound(to: Float.self)

        for frame in 0..<Int(frameCount) {
            let sample = generateSample(for: type, channel: channel)

            if channel == .left {
                leftPtr[frame] = sample
                rightPtr[frame] = 0.0
            } else {
                leftPtr[frame] = 0.0
                rightPtr[frame] = sample
            }
        }
        return noErr
    }

    // Helper to generate a single sample
    private func generateSample(for type: NoiseType, channel: EarSetting) -> Float {
        switch type {
        case .white:
            return generateWhite()
        case .pink:
            return (channel == .left)
                ? generatePink(state: &pinkStateLeft) : generatePink(state: &pinkStateRight)
        case .brown:
            return (channel == .left)
                ? generateBrown(last: &brownLastLeft) : generateBrown(last: &brownLastRight)
        }
    }

    func start() {
        guard !engine.isRunning else { return }

        // Ensure session is setup/active
        setupAudioSession()

        // Double check headphones (just for status, not blocking)
        checkHeadphoneConnection()

        // We no longer block start() if headphones are missing,
        // effectively allowing playback on speakers if user desires.

        do {
            try engine.start()
            isRunning = true
        } catch {
            print("Engine start error: \(error)")
        }
    }

    func stop() {
        guard engine.isRunning else { return }
        engine.stop()
        isRunning = false
    }

    private func resetFilters() {
        brownLastLeft = 0.0
        pinkStateLeft = Array(repeating: 0, count: 7)
        brownLastRight = 0.0
        pinkStateRight = Array(repeating: 0, count: 7)
        updateEQs()
    }

    private func updateEQs() {
        // Left EQ
        let lFreq = centerFrequencyLeft ?? centerFrequencyBase
        let lBw = bandwidthLeft ?? bandwidthBase

        leftEQ.bands[0].filterType = .bandPass
        leftEQ.bands[0].frequency = lFreq
        leftEQ.bands[0].bandwidth = lBw
        leftEQ.bands[0].gain = 0  // 0 dB, just filtering
        leftEQ.bands[0].bypass = false

        // Right EQ
        let rFreq = centerFrequencyRight ?? centerFrequencyBase
        let rBw = bandwidthRight ?? bandwidthBase

        rightEQ.bands[0].filterType = .bandPass
        rightEQ.bands[0].frequency = rFreq
        rightEQ.bands[0].bandwidth = rBw
        rightEQ.bands[0].gain = 0  // 0 dB, just filtering
        rightEQ.bands[0].bypass = false
    }

    private func updateAudioState() {
        // Update EQs
        updateEQs()

        // Update Volumes for channel mixers
        // Mapping 0.0 - 1.0 (UI) -> 0.0 - 0.3 (Internal)
        leftMixer.outputVolume = (volumeLeft ?? volumeBase) * 0.3
        rightMixer.outputVolume = (volumeRight ?? volumeBase) * 0.3

        // Reset generator states if noise type changes
        // This is implicitly handled by the render function using the correct noiseType for each channel.
        // However, if the *base* noise type changes, we should reset both.
        // If an override changes, only that channel's state needs reset.
        // For simplicity, we'll reset both if any noise type changes.
        // This is a bit aggressive but safe. A more precise approach would track previous noise types.
        resetFilters()

        autoSaveCurrentPreset()  // Auto-save current state to the active preset
    }

    // MARK: - Presets Logic

    private func loadPresets() {
        if let data = UserDefaults.standard.data(forKey: presetsKey),
            let decoded = try? JSONDecoder().decode([Preset].self, from: data)
        {
            self.presets = decoded
        } else {
            // Create default if none exist
            let defaultPreset = Preset(
                name: "Standard",
                noiseType: .white,
                volume: 0.2,
                centerFrequency: 8000,
                bandwidth: 1.0
            )
            self.presets = [defaultPreset]
        }

        // Restore last used preset or default
        if let savedIdString = UserDefaults.standard.string(forKey: currentPresetIdKey),
            let savedId = UUID(uuidString: savedIdString),
            presets.contains(where: { $0.id == savedId })
        {
            self.currentPresetId = savedId
            // Note: didSet of currentPresetId will trigger loadPreset()
        } else if let first = presets.first {
            self.currentPresetId = first.id
        }
    }

    private func loadPreset(_ preset: Preset) {
        // Update properties without triggering autoSave to avoid circular save
        // Base values
        self.noiseTypeBase = preset.noiseType
        self.volumeBase = preset.volume
        self.centerFrequencyBase = preset.centerFrequency
        self.bandwidthBase = preset.bandwidth

        // Left overrides
        self.noiseTypeLeft = preset.noiseTypeLeft
        self.volumeLeft = preset.volumeLeft
        self.centerFrequencyLeft = preset.centerFrequencyLeft
        self.bandwidthLeft = preset.bandwidthLeft

        // Right overrides
        self.noiseTypeRight = preset.noiseTypeRight
        self.volumeRight = preset.volumeRight
        self.centerFrequencyRight = preset.centerFrequencyRight
        self.bandwidthRight = preset.bandwidthRight

        // Ensure audio state is updated after loading
        updateAudioState()
    }

    func saveAsNewPreset(name: String) {
        let newPreset = Preset(
            name: name,
            noiseType: noiseTypeBase,
            volume: volumeBase,
            centerFrequency: centerFrequencyBase,
            bandwidth: bandwidthBase,
            noiseTypeLeft: noiseTypeLeft,
            volumeLeft: volumeLeft,
            centerFrequencyLeft: centerFrequencyLeft,
            bandwidthLeft: bandwidthLeft,
            noiseTypeRight: noiseTypeRight,
            volumeRight: volumeRight,
            centerFrequencyRight: centerFrequencyRight,
            bandwidthRight: bandwidthRight
        )
        presets.append(newPreset)
        savePresetsToDisk()

        // Select the new preset
        currentPresetId = newPreset.id
    }

    private func autoSaveCurrentPreset() {
        guard let currentId = currentPresetId,
            let index = presets.firstIndex(where: { $0.id == currentId })
        else { return }

        var preset = presets[index]
        preset.noiseType = noiseTypeBase
        preset.volume = volumeBase
        preset.centerFrequency = centerFrequencyBase
        preset.bandwidth = bandwidthBase

        preset.noiseTypeLeft = noiseTypeLeft
        preset.volumeLeft = volumeLeft
        preset.centerFrequencyLeft = centerFrequencyLeft
        preset.bandwidthLeft = bandwidthLeft

        preset.noiseTypeRight = noiseTypeRight
        preset.volumeRight = volumeRight
        preset.centerFrequencyRight = centerFrequencyRight
        preset.bandwidthRight = bandwidthRight

        presets[index] = preset
        savePresetsToDisk()
    }

    func deletePreset(id: UUID) {
        presets.removeAll { $0.id == id }
        if currentPresetId == id {
            // If deleted preset was current, select first available
            self.currentPresetId = presets.first?.id
        }
        savePresetsToDisk()
    }

    private func savePresetsToDisk() {
        if let encoded = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(encoded, forKey: presetsKey)
        }
        if let currentId = currentPresetId {
            UserDefaults.standard.set(currentId.uuidString, forKey: currentPresetIdKey)
        }
    }

    // MARK: - Noise Generatoren

    private func generateWhite() -> Float {
        return Float.random(in: -1...1)
    }

    /// Ganz einfache pink-noise-Approximation (Voss-McCartney approximiert)
    private func generatePink(state: inout [Float]) -> Float {
        // sehr simple Version, reicht fürs Einschlafen
        let white = generateWhite()

        // 7-stufiger IIR-ähnlicher Ansatz
        state[0] = 0.99886 * state[0] + white * 0.0555179
        state[1] = 0.99332 * state[1] + white * 0.0750759
        state[2] = 0.96900 * state[2] + white * 0.1538520
        state[3] = 0.86650 * state[3] + white * 0.3104856
        state[4] = 0.55000 * state[4] + white * 0.5329522
        state[5] = -0.7616 * state[5] - white * 0.0168980

        let pink =
            state[0] + state[1] + state[2] + state[3] + state[4] + state[5]
            + state[6] + white * 0.5362
        state[6] = white * 0.115926

        return pink * 0.1  // Level runter, damit es nicht clippt
    }

    private func generateBrown(last: inout Float) -> Float {
        let white = generateWhite()
        last += white * 0.02
        // clamp
        if last > 1 { last = 1 }
        if last < -1 { last = -1 }
        return last
    }
}
