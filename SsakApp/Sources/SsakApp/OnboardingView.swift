import SwiftUI

/// First-run coach (spec §6): three calm beats — water once a day, watch the
/// drop, don't drown it — then plant the first seed.
public struct OnboardingView: View {
    var onDone: () -> Void
    public init(onDone: @escaping () -> Void) { self.onDone = onDone }

    private let ink = Color(red: 0.28, green: 0.22, blue: 0.16)

    public var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 8)
            VStack(spacing: 4) {
                Text("Ssak 싹").font(.system(size: 34, weight: .bold, design: .serif)).foregroundStyle(ink)
                Text("Raise one flower, on the real clock.")
                    .font(.system(size: 14)).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 18) {
                beat("drop.fill", "Water once a day", "A little is plenty.")
                beat("eye.fill", "Watch the drop", "It shows the soil's moisture.")
                beat("leaf.fill", "Don't drown it", "Too much stalls growth — but it's forgiving.")
            }
            .padding(.horizontal, 30)
            Spacer()
            Button(action: onDone) {
                Text("Plant your first seed")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.36, green: 0.60, blue: 0.34))
            .padding(.horizontal, 30).padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.99, green: 0.97, blue: 0.92))
    }

    @ViewBuilder private func beat(_ icon: String, _ title: String, _ sub: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color(red: 0.90, green: 0.94, blue: 0.86)).frame(width: 44, height: 44)
                Image(systemName: icon).font(.system(size: 18))
                    .foregroundStyle(Color(red: 0.34, green: 0.56, blue: 0.30))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(ink)
                Text(sub).font(.system(size: 13)).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
