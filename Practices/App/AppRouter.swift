import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case today, journal, meditate, exercise, vision

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today: "Today"
        case .journal: "Journal"
        case .meditate: "Meditate"
        case .exercise: "Exercise"
        case .vision: "Vision"
        }
    }

    init(_ practice: Practice) {
        switch practice {
        case .journal: self = .journal
        case .meditation: self = .meditate
        case .exercise: self = .exercise
        }
    }
}

enum TodayRoute: Hashable {
    case insights
    case mood
}

/// Shared navigation state: the selected tab, Today's push stack, and a logger to open on arrival.
@Observable
final class AppRouter {
    var tab: AppTab = .today
    var todayPath: [TodayRoute] = []
    /// Set when a buddy is long-pressed; the practice's tab opens its detailed logger.
    var pendingLogger: Practice?
    /// The past day Today was showing when the logger was requested (nil = now).
    var pendingLoggerDate: Date?

    func open(_ practice: Practice) {
        tab = AppTab(practice)
    }

    func openLogger(for practice: Practice, on date: Date? = nil) {
        pendingLoggerDate = date
        pendingLogger = practice
        tab = AppTab(practice)
    }
}

// Keep the edge swipe-back gesture working on screens that draw their own back button.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
