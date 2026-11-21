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
    let accent: Color?

    init(snapshot: WidgetSnapshot?, scheme: ColorScheme) {
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
        case "match": accent = nil
        default: accent = WidgetTokens.accents[config?.accent ?? ""]
        }
    }

    func accent(for game: String) -> Color {
        accent ?? WidgetTokens.accents[game] ?? WidgetTokens.lime
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
        let max = item.max ?? 0
        let allBack = item.doneAt.map { $0 <= now } ?? false
        switch item.key {
        case "videoStore":
            return snapshot.label("videoStore.\(item.state ?? "closed")")
        case "scratchCard":
            return item.state == "done" ? snapshot.label("done") : "0/1"
        case "realm":
            return NumberFormatter.localizedString(from: NSNumber(value: item.value ?? 0), number: .decimal)
        case "transformer":
            guard let doneAt = item.doneAt, !allBack else { return snapshot.label("ready") }
            return time(doneAt)
        case "expeditions", "assignments":
            return "\(allBack ? max : item.value ?? 0)/\(max)"
        default:
            return "\(item.value ?? 0)/\(max)"
        }
    }

    static func deepLink(_ role: WidgetRole?) -> URL? {
        guard let role else { return URL(string: "hoyoaio://dashboard") }
        return URL(string: "hoyoaio://dashboard?game=\(role.game)&role=\(role.uid)")
    }

    static func progress(_ stamina: WidgetStamina, _ now: Date) -> Double {
        Double(stamina.current(at: now)) / Double(Swift.max(stamina.max, 1))
    }
}

struct StaminaRing: View {
    static let stroke: CGFloat = 7

    let progress: Double
    let color: Color
    let track: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: Self.stroke)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: Self.stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

struct StaminaBar: View {
    let progress: Double
    let color: Color
    let track: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(color).frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 6)
    }
}

struct HoYoWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme
    let entry: SnapshotEntry

    var body: some View {
        let snapshot = entry.snapshot
        let role = snapshot?.roles.first
        let style = WidgetStyle(snapshot: snapshot, scheme: scheme)
        content(snapshot: snapshot, role: role, style: style)
            .font(.system(size: 12))
            .foregroundStyle(style.palette.text2)
            .monospacedDigit()
            .widgetURL(WidgetFormat.deepLink(role))
            .containerBackground(for: .widget) { style.palette.background }
    }

    @ViewBuilder
    private func content(snapshot: WidgetSnapshot?, role: WidgetRole?, style: WidgetStyle) -> some View {
        if let snapshot, let role {
            switch family {
            case .systemSmall:
                medium(snapshot: snapshot, role: role, style: style)
            case .systemMedium:
                large(snapshot: snapshot, style: style)
            default:
                VStack(spacing: 16) {
                    large(snapshot: snapshot, style: style)
                    small(snapshot: snapshot, role: role, style: style)
                }
            }
        } else {
            Text("Open HoYo AIO to load your notes")
        }
    }

    private func small(snapshot: WidgetSnapshot, role: WidgetRole, style: WidgetStyle) -> some View {
        HStack(spacing: 12) {
            StaminaRing(
                progress: WidgetFormat.progress(role.stamina, entry.date),
                color: style.accent(for: role.game),
                track: style.palette.track,
                size: 44
            )
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(role.stamina.current(at: entry.date))")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(style.palette.text)
                    Text("/\(role.stamina.max)")
                }
                Text(WidgetFormat.full(snapshot, role, entry.date))
            }
            Spacer(minLength: 0)
        }
    }

    private func medium(snapshot: WidgetSnapshot, role: WidgetRole, style: WidgetStyle) -> some View {
        let accent = style.accent(for: role.game)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(accent).frame(width: 8, height: 8)
                Text(snapshot.label("game.\(role.game)"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(style.palette.text)
                Spacer(minLength: 0)
                Button(intent: ReloadWidgetsIntent()) {
                    Text(WidgetFormat.time(role.fetchedAt))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                StaminaRing(
                    progress: WidgetFormat.progress(role.stamina, entry.date),
                    color: accent,
                    track: style.palette.track,
                    size: 52
                )
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(role.stamina.current(at: entry.date))")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(style.palette.text)
                    Text(WidgetFormat.full(snapshot, role, entry.date))
                }
            }
            Spacer(minLength: 0)
            ForEach(role.items.prefix(3), id: \.key) { item in
                HStack {
                    Text(snapshot.label(item.key)).lineLimit(1)
                    Spacer(minLength: 4)
                    Text(WidgetFormat.item(snapshot, item, entry.date))
                        .fontWeight(.bold)
                        .foregroundStyle(style.palette.text)
                }
            }
        }
    }

    private func large(snapshot: WidgetSnapshot, style: WidgetStyle) -> some View {
        let latest = snapshot.roles.map(\.fetchedAt).max() ?? entry.date
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(snapshot.label("app"))
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(style.palette.text)
                Spacer(minLength: 0)
                Button(intent: ReloadWidgetsIntent()) {
                    Text(
                        snapshot.label("updated")
                            .replacingOccurrences(of: "{time}", with: WidgetFormat.time(latest))
                    )
                }
                .buttonStyle(.plain)
            }
            ForEach(snapshot.roles.prefix(3), id: \.roleId) { role in
                HStack(spacing: 8) {
                    Circle().fill(style.accent(for: role.game)).frame(width: 8, height: 8)
                    Text(snapshot.label("short.\(role.stamina.key)"))
                        .fontWeight(.semibold)
                        .foregroundStyle(style.palette.text)
                        .frame(width: 64, alignment: .leading)
                    StaminaBar(
                        progress: WidgetFormat.progress(role.stamina, entry.date),
                        color: style.accent(for: role.game),
                        track: style.palette.track
                    )
                    Text("\(role.stamina.current(at: entry.date))/\(role.stamina.max)")
                        .fontWeight(.bold)
                        .foregroundStyle(style.palette.text)
                }
            }
            Spacer(minLength: 0)
            if snapshot.checkIn.total > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                    Text(
                        snapshot.label("checkedIn")
                            .replacingOccurrences(of: "{done}", with: "\(snapshot.checkIn.done)")
                            .replacingOccurrences(of: "{total}", with: "\(snapshot.checkIn.total)")
                    )
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(style.palette.success)
            }
        }
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
