import AppIntents
import SwiftUI
import WidgetKit

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct SnapshotProvider: TimelineProvider {
    private static let step: TimeInterval = 15 * 60
    private static let entries = 8

    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: Date(), snapshot: WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load()
        let now = Date()
        let entries = (0..<Self.entries).map { index in
            SnapshotEntry(date: now.addingTimeInterval(Double(index) * Self.step), snapshot: snapshot)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct ReloadWidgetsIntent: AppIntent {
    static let title: LocalizedStringResource = "Reload"

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct WidgetStyle {
    let palette: WidgetPalette
    let accent: Color

    init(snapshot: WidgetSnapshot?, role: WidgetRole?, scheme: ColorScheme) {
        let config = snapshot?.widgets.first
        let theme: String
        switch config?.theme {
        case "light", "dark", "clear": theme = config?.theme ?? "light"
        default: theme = scheme == .dark ? "dark" : "light"
        }
        palette = WidgetTokens.palettes[theme] ?? WidgetTokens.light
        switch config?.accent ?? "match" {
        case "lime": accent = WidgetTokens.lime
        case "neutral": accent = palette.text2
        case "match": accent = WidgetTokens.accents[role?.game ?? ""] ?? WidgetTokens.lime
        default: accent = WidgetTokens.accents[config?.accent ?? ""] ?? WidgetTokens.lime
        }
    }
}

enum WidgetFormat {
    private static let clock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static func time(_ date: Date) -> String { clock.string(from: date) }

    static func full(_ snapshot: WidgetSnapshot, _ role: WidgetRole, _ now: Date) -> String {
        role.stamina.isFull(at: now)
            ? snapshot.label("full")
            : "\(snapshot.label("full")) \(time(role.stamina.fullAt))"
    }

    static func item(_ snapshot: WidgetSnapshot, _ item: WidgetItem, _ now: Date) -> String {
        if item.key == "videoStore", let state = item.state {
            return snapshot.label("videoStore.\(state)")
        }
        if item.key == "scratchCard" {
            return item.state == "done" ? snapshot.label("done") : "0/1"
        }
        if item.key != "realm", let doneAt = item.doneAt {
            if doneAt <= now {
                return snapshot.label(item.key == "transformer" ? "ready" : "done")
            }
            return time(doneAt)
        }
        return "\(item.value ?? 0)/\(item.max ?? 0)"
    }

    static func deepLink(_ role: WidgetRole?) -> URL? {
        guard let role else { return URL(string: "hoyoaio://dashboard") }
        return URL(string: "hoyoaio://dashboard?game=\(role.game)&role=\(role.uid)")
    }
}

struct StaminaBar: View {
    let progress: Double
    let style: WidgetStyle

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(style.palette.track)
                Capsule().fill(style.accent).frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 6)
    }
}

struct RoleStaminaView: View {
    let snapshot: WidgetSnapshot
    let role: WidgetRole
    let now: Date
    let style: WidgetStyle
    let valueSize: CGFloat

    var body: some View {
        let current = role.stamina.current(at: now)
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle().fill(style.accent).frame(width: 8, height: 8)
                Text(snapshot.label("game.\(role.game)"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(style.palette.text2)
            }
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(current)").font(.system(size: valueSize, weight: .bold))
                Text("/\(role.stamina.max)").font(.system(size: 13))
                    .foregroundStyle(style.palette.text2)
            }
            .foregroundStyle(style.palette.text)
            StaminaBar(
                progress: Double(current) / Double(Swift.max(role.stamina.max, 1)),
                style: style
            )
            Text(WidgetFormat.full(snapshot, role, now))
                .font(.system(size: 12))
                .foregroundStyle(style.palette.text2)
        }
        .monospacedDigit()
    }
}

struct HoYoWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme
    let entry: SnapshotEntry

    var body: some View {
        let snapshot = entry.snapshot
        let role = snapshot?.roles.first
        let style = WidgetStyle(snapshot: snapshot, role: role, scheme: scheme)
        content(snapshot: snapshot, role: role, style: style)
            .widgetURL(WidgetFormat.deepLink(role))
            .containerBackground(for: .widget) { style.palette.background }
    }

    @ViewBuilder
    private func content(snapshot: WidgetSnapshot?, role: WidgetRole?, style: WidgetStyle) -> some View {
        if let snapshot, let role {
            switch family {
            case .systemSmall:
                RoleStaminaView(snapshot: snapshot, role: role, now: entry.date, style: style, valueSize: 26)
            case .systemMedium:
                rolesList(snapshot: snapshot, style: style, limit: 3)
            default:
                VStack(alignment: .leading, spacing: 12) {
                    rolesList(snapshot: snapshot, style: style, limit: 3)
                    itemsList(snapshot: snapshot, role: role, style: style)
                }
            }
        } else {
            Text("Open HoYo AIO to load your notes")
                .font(.system(size: 13))
                .foregroundStyle(style.palette.text2)
        }
    }

    private func rolesList(snapshot: WidgetSnapshot, style: WidgetStyle, limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(snapshot.roles.prefix(limit), id: \.roleId) { role in
                let roleStyle = WidgetStyle(snapshot: snapshot, role: role, scheme: scheme)
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Circle().fill(roleStyle.accent).frame(width: 8, height: 8)
                        Text(snapshot.label(role.stamina.key))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(style.palette.text)
                        Spacer()
                        Text("\(role.stamina.current(at: entry.date))/\(role.stamina.max)  \(WidgetFormat.full(snapshot, role, entry.date))")
                            .font(.system(size: 12))
                            .foregroundStyle(style.palette.text2)
                    }
                    StaminaBar(
                        progress: Double(role.stamina.current(at: entry.date))
                            / Double(Swift.max(role.stamina.max, 1)),
                        style: roleStyle
                    )
                }
            }
            HStack {
                Text(
                    snapshot.label("checkedIn")
                        .replacingOccurrences(of: "{done}", with: "\(snapshot.checkIn.done)")
                        .replacingOccurrences(of: "{total}", with: "\(snapshot.checkIn.total)")
                )
                .font(.system(size: 12))
                .foregroundStyle(style.palette.text2)
                Spacer()
                Button(intent: ReloadWidgetsIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(style.palette.text2)
                }
                .buttonStyle(.plain)
            }
        }
        .monospacedDigit()
    }

    private func itemsList(snapshot: WidgetSnapshot, role: WidgetRole, style: WidgetStyle) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(role.items.prefix(3), id: \.key) { item in
                HStack {
                    Text(snapshot.label(item.key)).foregroundStyle(style.palette.text2)
                    Spacer()
                    Text(WidgetFormat.item(snapshot, item, entry.date))
                        .fontWeight(.bold)
                        .foregroundStyle(style.palette.text)
                }
                .font(.system(size: 12))
            }
        }
        .monospacedDigit()
    }
}

@main
struct HoYoWidgets: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HoYoWidgets", provider: SnapshotProvider()) { entry in
            HoYoWidgetView(entry: entry)
        }
        .configurationDisplayName("HoYo AIO")
        .description("Stamina, dailies and check-in at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
