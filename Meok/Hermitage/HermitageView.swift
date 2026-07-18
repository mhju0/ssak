import SwiftUI
import GameKernel
import Persistence
import SkyState

extension Room {
    var displayName: String {
        Locale.current.language.languageCode?.identifier == "ko" ? nameKO : nameEN
    }
}

/// The hermitage hub (spec §2): the home base. Sweep the path, work the bench
/// (crafting is the entry skill), and restore the rooms one by one — a restored
/// kitchen unlocks cooking. The craft → repair kit → restore → cook loop lives
/// here.
struct HermitageView: View {
    let conditions: WorldConditions
    let store: GameStore
    let onClose: () -> Void

    @State private var restored: Set<String> = []
    @State private var showSweep = false
    @State private var showCraft = false
    @State private var showCook = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    hubRow("Sweep the path", "wind") { showSweep = true }
                    hubRow("Workbench", "hammer") { showCraft = true }
                    if restored.contains("kitchen") {
                        hubRow("Kitchen", "flame") { showCook = true }
                    }
                } header: {
                    Text("The grounds")
                }

                Section {
                    ForEach(Hermitage.rooms) { room in
                        roomRow(room)
                    }
                } header: {
                    Text("Restore the rooms")
                } footer: {
                    Text("Craft repair kits at the workbench, then restore the hermitage room by room.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text("Hermitage"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: onClose) { Text("Done") }
                }
            }
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-meok-hermitage-demo") {
                store.add("repair-kit", count: 2)  // so restoration is demoable
            }
            restored = store.restoredRooms()
        }
        .fullScreenCover(isPresented: $showSweep) {
            SweepView(conditions: conditions) { showSweep = false }
        }
        .fullScreenCover(isPresented: $showCraft) {
            MakerView(store: store, kind: .crafting) { showCraft = false; restored = store.restoredRooms() }
        }
        .fullScreenCover(isPresented: $showCook) {
            MakerView(store: store, kind: .cooking) { showCook = false }
        }
    }

    private func hubRow(_ title: LocalizedStringKey, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: symbol).frame(width: 24).foregroundStyle(.secondary)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .foregroundStyle(.primary)
    }

    private func roomRow(_ room: Room) -> some View {
        let done = restored.contains(room.id)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(room.displayName)
                if done {
                    Text(unlockNote(room.unlocks))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(verbatim: costText(room))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if done {
                Image(systemName: "checkmark.seal").foregroundStyle(.secondary)
            } else {
                Button {
                    if store.restore(room) { restored = store.restoredRooms() }
                } label: {
                    Text("Restore")
                }
                .buttonStyle(.bordered)
                .disabled(!store.has(room.cost))
            }
        }
    }

    private func costText(_ room: Room) -> String {
        room.cost
            .map { "\(goodName($0.item)) \(store.count(of: $0.item))/\($0.count)" }
            .joined(separator: "  ")
    }

    /// A crafted good's localized name, resolved from the craftable that makes it.
    private func goodName(_ id: String) -> String {
        let ko = Locale.current.language.languageCode?.identifier == "ko"
        if let maker = CraftingTable.all.first(where: {
            if case .good(let g) = $0.effect { return g == id }
            return false
        }) {
            return ko ? maker.nameKO : maker.nameEN
        }
        return id
    }

    private func unlockNote(_ function: RoomFunction) -> LocalizedStringKey {
        switch function {
        case .kitchen: "Restored — cooking unlocked."
        case .toolShed: "Restored — tools stored."
        case .studio: "Restored — larger paintings come with the gallery (M5)."
        case .gallery: "Restored — the display walls come with the gallery (M5)."
        }
    }
}
