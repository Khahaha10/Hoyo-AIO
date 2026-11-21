import Foundation

struct WidgetStamina: Decodable {
    let key: String
    let current: Int
    let max: Int
    let fetchedAt: Date
    let fullAt: Date
    let recoverySeconds: Int

    func current(at now: Date) -> Int {
        guard current < max, now > fetchedAt, recoverySeconds > 0 else { return current }
        let remaining = fullAt.timeIntervalSince(now)
        guard remaining > 0 else { return max }
        let missing = Int((remaining / Double(recoverySeconds)).rounded(.up))
        return Swift.min(Swift.max(max - missing, current), max)
    }

    func isFull(at now: Date) -> Bool { current(at: now) >= max }
}

struct WidgetItem: Decodable {
    let key: String
    let value: Int?
    let max: Int?
    let doneAt: Date?
    let state: String?
}

struct WidgetRole: Decodable {
    let roleId: Int
    let game: String
    let uid: String
    let name: String
    let fetchedAt: Date
    let stale: Bool
    let stamina: WidgetStamina
    let items: [WidgetItem]
}

struct WidgetCheckIn: Decodable {
    let done: Int
    let total: Int
}

struct WidgetConfig: Decodable {
    let widgetId: Int
    let roleId: Int?
    let theme: String
    let opacity: Double
    let accent: String
    let fontSize: String
    let visibleItems: [String]
}

struct WidgetSnapshot: Decodable {
    static let appGroup = "group.com.hoyoaio.app"
    static let key = "hoyo_aio_snapshot"

    let roles: [WidgetRole]
    let checkIn: WidgetCheckIn
    let widgets: [WidgetConfig]
    let labels: [String: String]

    func label(_ key: String) -> String { labels[key] ?? key }

    static func load() -> WidgetSnapshot? {
        guard
            let raw = UserDefaults(suiteName: appGroup)?.string(forKey: key),
            let data = raw.data(using: .utf8)
        else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: text) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: text) { return date }
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: text)
            )
        }
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }
}
