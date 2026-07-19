import SwiftUI
import SsakArt
import SsakCore

@main
struct Render {
    @MainActor static func main() {
        let out = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("rendered", isDirectory: true)
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

        let placeholder = ZStack {
            Color(red: 0.98, green: 0.95, blue: 0.88)
            Circle().fill(.orange).frame(width: 80, height: 80)
        }
        if let data = pngData(for: placeholder, size: CGSize(width: 120, height: 140)) {
            try? data.write(to: out.appendingPathComponent("_loop_check.png"))
            print("wrote \(out.appendingPathComponent("_loop_check.png").path)")
        } else {
            print("RENDER FAILED"); exit(1)
        }
    }
}
