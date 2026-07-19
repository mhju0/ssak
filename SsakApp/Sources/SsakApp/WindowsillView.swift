import SwiftUI
import SsakCore
import SsakArt

/// The home screen (spec §6): the current plant on its sill, chrome-light so it's
/// screenshot-ready — streak, watered-today, moisture gauge, water + share actions.
public struct WindowsillView: View {
    @ObservedObject var model: GardenModel
    let now: Date
    var onWater: () -> Void
    var onShare: () -> Void

    public init(model: GardenModel, now: Date,
                onWater: @escaping () -> Void, onShare: @escaping () -> Void) {
        self.model = model; self.now = now; self.onWater = onWater; self.onShare = onShare
    }

    private var band: ClosedRange<Double> {
        let lo = model.tuning.dryThreshold / model.tuning.moistureMax
        let hi = model.tuning.tooWetThreshold / model.tuning.moistureMax
        return lo...hi
    }

    /// How much the plant sags: strong while nursing, else scaled by how far
    /// below the dry line the soil is.
    private var droop: Double {
        if model.isNursing { return 0.65 }
        let lower = band.lowerBound
        let f = model.moistureFraction
        return f < lower ? min(1, (lower - f) / max(lower, 0.001)) * 0.8 : 0
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                StreakBadge(count: model.state.plant.streak, alive: model.isStreakAlive(now: now))
                Spacer()
                if model.hasWateredToday(now: now) {
                    WateredTodayTick().font(.system(size: 22))
                }
            }
            .padding(.horizontal, 20).padding(.top, 14)

            PlantView(species: model.species, stage: model.stage, droop: droop)
                .frame(maxWidth: .infinity)
                .layoutPriority(1)

            VStack(spacing: 2) {
                Text(model.species.nameEN)
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                Text(model.species.nameKO)
                    .font(.system(size: 13)).foregroundStyle(.secondary)
            }
            .foregroundStyle(Color(red: 0.28, green: 0.22, blue: 0.16))

            HStack(spacing: 18) {
                DropGauge(fraction: model.moistureFraction, band: band).frame(width: 34, height: 48)
                Button(action: onWater) { Label("Water", systemImage: "drop.fill") }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.36, green: 0.62, blue: 0.86))
                Button(action: onShare) { Image(systemName: "square.and.arrow.up").font(.system(size: 18)) }
                    .buttonStyle(.bordered)
            }
            .padding(.vertical, 18)
        }
        .background(Color(red: 0.99, green: 0.97, blue: 0.92))
    }
}
