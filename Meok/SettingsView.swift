import GameKernel
import SkyState
import SwiftUI

/// Settings v0: the manual city picker (until real location arrives with
/// the M7 permission choreography) and the weather-data attribution.
struct SettingsView: View {
    @ObservedObject var sky: SkyMonitor
    @Environment(\.dismiss) private var dismiss
    @AppStorage("meok-audio") private var soundEnabled = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(City.presets) { city in
                        Button {
                            Task { await sky.setCity(city) }
                        } label: {
                            HStack {
                                Text(verbatim: city.name)
                                Spacer()
                                if city == sky.city {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Text("City")
                } footer: {
                    Text("The scroll lives under this city's real sky.")
                }

                Section {
                    Toggle(isOn: $soundEnabled) {
                        Text("Sound")
                    }
                } footer: {
                    Text("Gentle procedural sounds for bites and finds. Everything is synthesized — no audio files.")
                }

                Section {
                } footer: {
                    Link(
                        "Weather data by Open-Meteo.com (CC BY 4.0)",
                        destination: URL(string: "https://open-meteo.com/")!)
                }
            }
            .navigationTitle(Text("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
