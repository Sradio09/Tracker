import Foundation
import AppMetricaCore

enum AnalyticsEvent: String {
    case open
    case close
    case click
}

enum AnalyticsScreen: String {
    case main = "Main"
}

enum AnalyticsItem: String {
    case addTrack = "add_track"
    case track = "track"
    case filter = "filter"
    case edit = "edit"
    case delete = "delete"
}

final class AnalyticsService {

    static let shared = AnalyticsService()

    private let apiKey = "f80690cf-590d-41ee-9f54-e8e2ca228c5c"

    private var isActivated = false

    private init() {}

    func activateIfNeeded() {
        guard !isActivated else { return }

        guard !apiKey.isEmpty else {
            assertionFailure("⚠️ AppMetrica API key is empty.")
            return
        }

        guard let configuration = AppMetricaConfiguration(apiKey: apiKey) else {
            assertionFailure("⚠️ Failed to create AppMetricaConfiguration.")
            return
        }

        AppMetrica.activate(with: configuration)
        isActivated = true

        #if DEBUG
        print("📈 AppMetrica activated")
        #endif
    }

    func report(event: AnalyticsEvent, screen: AnalyticsScreen, item: AnalyticsItem? = nil) {
        var params: [AnyHashable: Any] = [
            "event": event.rawValue,
            "screen": screen.rawValue
        ]

        if let item {
            params["item"] = item.rawValue
        }

        #if DEBUG
        print("📈 AppMetrica event:", params)
        #endif

        AppMetrica.reportEvent(name: "tracker_event", parameters: params, onFailure: { error in
            #if DEBUG
            print("📈 REPORT ERROR:", error.localizedDescription)
            #endif
        })
    }
}

