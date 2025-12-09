import SwiftUI

struct ContentView: View {
    @StateObject private var engine = NoiseEngine()

    // State for the "Save As" dialog
    @State private var showSaveAlert = false
    @State private var showDeleteAlert = false
    @State private var newPresetName = ""

    init() {
        // Force dark mode for the app window to match theme
        // (In a real app handling scene delegate might be better, but this works for simple cases)
    }

    var body: some View {
        ZStack {
            Theme.gradientBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // --- Header ---
                HStack {
                    VStack(alignment: .leading) {
                        Text("NEURO-CALM")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.active)
                            .tracking(2)
                        Text("LABORATORY")
                            .font(.system(size: 20, weight: .thin, design: .monospaced))
                            .foregroundColor(Theme.textMain)
                    }

                    Spacer()

                    // Preset Menu
                    Menu {
                        ForEach(engine.presets) { preset in
                            Button(action: { engine.currentPresetId = preset.id }) {
                                HStack {
                                    Text(preset.name)
                                    if engine.currentPresetId == preset.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("SAVE_NEW_PRESET") {
                            newPresetName = ""
                            showSaveAlert = true
                        }

                        if let current = engine.presets.first(where: {
                            $0.id == engine.currentPresetId
                        }),
                            current.name != "Standard"
                        {
                            Divider()
                            Button(role: .destructive) {
                                showDeleteAlert = true
                            } label: {
                                Label("DELETE_PRESET", systemImage: "trash")
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(
                                engine.presets.first(where: { $0.id == engine.currentPresetId })?
                                    .name.uppercased() ?? NSLocalizedString("STANDARD", comment: "")
                            )
                            .font(Theme.labHeader)
                            Image(systemName: "chevron.down")
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Theme.surface)
                        .cornerRadius(8)
                        .foregroundColor(Theme.textMain)
                    }
                }
                .padding()

                ScrollView {
                    VStack(spacing: 24) {

                        // --- Hero: Monitor Area ---
                        VStack(spacing: 0) {
                            HStack {
                                Text("AUDIO_CHANNEL_SELECT")
                                    .font(Theme.labLabel)
                                    .foregroundColor(Theme.textDim)
                                Spacer()
                                Circle()
                                    .fill(engine.isRunning ? Theme.active : Theme.warn)
                                    .frame(width: 6, height: 6)
                                Text(engine.isRunning ? "ONLINE" : "STANDBY")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(engine.isRunning ? Theme.active : Theme.warn)
                            }
                            .padding(.bottom, 20)

                            VisualEarSelector(selectedEar: $engine.selectedEar)
                                .frame(height: 120)
                        }
                        .padding(20)
                        .background(
                            Theme.surface
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Theme.textDim.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .cornerRadius(24)

                        // --- Controls Section ---
                        VStack(spacing: 24) {

                            // Noise Type
                            VStack(alignment: .leading) {
                                Text("NOISE_GENERATOR")
                                    .font(Theme.labLabel)
                                    .foregroundColor(Theme.textDim)
                                    .padding(.leading, 4)

                                NoiseTypeSelector(
                                    selection: Binding(
                                        get: { engine.activeNoiseType },
                                        set: { engine.activeNoiseType = $0 }
                                    ))
                            }

                            // Volume
                            LabSlider(
                                label: "MASTER_OUTPUT",
                                value: Binding(
                                    get: { engine.activeVolume },
                                    set: { engine.activeVolume = $0 }
                                ),
                                range: 0...1,
                                unit: "%",
                                format: "%.2f"
                            )

                            // Frequency
                            HStack(spacing: 16) {
                                LabSlider(
                                    label: "CENTER",
                                    value: Binding(
                                        get: { engine.activeCenterFrequency },
                                        set: { engine.activeCenterFrequency = $0 }
                                    ),
                                    range: 2000...12000,
                                    unit: "Hz",
                                    format: "%.0f"
                                )

                                LabSlider(
                                    label: "BANDWIDTH",
                                    value: Binding(
                                        get: { engine.activeBandwidth },
                                        set: { engine.activeBandwidth = $0 }
                                    ),
                                    range: 0.3...2.0,
                                    unit: "Okt",
                                    format: "%.1f"
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding()
                }

                // --- Footer Action ---
                VStack {
                    StartButton(isRunning: $engine.isRunning) {
                        engine.isRunning ? engine.stop() : engine.start()
                    }
                }
                .padding()
                .background(Theme.background.opacity(0.8))
            }
        }
        .preferredColorScheme(.dark)
        .alert("SAVE_PRESET_TITLE", isPresented: $showSaveAlert) {
            TextField("NAME_Placeholder", text: $newPresetName)
            Button("SAVE") {
                if !newPresetName.isEmpty {
                    engine.saveAsNewPreset(name: newPresetName)
                }
            }
            Button("CANCEL", role: .cancel) {}
        } message: {
            Text("SAVE_PRESET_MSG")
        }
        .alert("DELETE_CONFIRM_TITLE", isPresented: $showDeleteAlert) {
            Button("DELETE", role: .destructive) {
                if let id = engine.currentPresetId {
                    engine.deletePreset(id: id)
                }
            }
            Button("CANCEL", role: .cancel) {}
        } message: {
            Text("DELETE_CONFIRM_MSG")
        }
    }
}

#Preview {
    ContentView()
}
