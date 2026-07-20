import SwiftUI

/// First-run coach (spec §2.1): three calm beats — water once a day, watch the drop, don't
/// drown it — rebuilt for air. Semantic Dynamic Type throughout; adaptive ink; no animated hero.
public struct OnboardingView: View {
    var onDone: () -> Void
    public init(onDone: @escaping () -> Void) { self.onDone = onDone }

    @ScaledMetric(relativeTo: .largeTitle) private var titleToBeats: CGFloat = 44
    @ScaledMetric(relativeTo: .body) private var beatGap: CGFloat = 28

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 12) {
                Text("Ssak 싹")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .inkText()
                Text("Raise one flower, on the real clock.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: beatGap) {
                beat("drop.fill", "Water once a day", "A little is plenty.")
                beat("eye.fill", "Watch the drop", "It reads the soil.")
                beat("leaf.fill", "Don't drown it", "Too much stalls growth — but it's forgiving.")
            }
            .padding(.horizontal, 30)
            .padding(.top, titleToBeats)
            Spacer()
            Spacer()
            Button(action: onDone) {
                Text("Plant your first seed")
                    .font(.headline)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.36, green: 0.60, blue: 0.34))
            .padding(.horizontal, 30)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ssakGround()
    }

    @ViewBuilder private func beat(_ icon: String, _ title: String, _ sub: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color(red: 0.90, green: 0.94, blue: 0.86)).frame(width: 44, height: 44)
                Image(systemName: icon).font(.system(size: 18))
                    .foregroundStyle(Color(red: 0.34, green: 0.56, blue: 0.30))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).inkText()
                Text(sub).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
