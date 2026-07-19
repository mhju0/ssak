import Foundation
import SsakCore

let utcCal: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}()

func day(_ n: Int, hour: Int = 9) -> Date {
    utcCal.date(from: DateComponents(year: 2026, month: 7, day: 1 + n, hour: hour))!
}

func tempStore() -> PlantStore {
    PlantStore(url: URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("ssak-app-\(UUID().uuidString).json"))
}
