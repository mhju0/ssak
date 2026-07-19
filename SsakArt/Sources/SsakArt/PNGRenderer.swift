import SwiftUI
import ImageIO
import UniformTypeIdentifiers

/// Render any SwiftUI view to PNG bytes. Main-actor because ImageRenderer is.
@MainActor
public func pngData(for view: some View, size: CGSize, scale: CGFloat = 3) -> Data? {
    let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
    renderer.scale = scale
    guard let cg = renderer.cgImage else { return nil }
    let data = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(
        data as CFMutableData, UTType.png.identifier as CFString, 1, nil) else { return nil }
    CGImageDestinationAddImage(dest, cg, nil)
    guard CGImageDestinationFinalize(dest) else { return nil }
    return data as Data
}
