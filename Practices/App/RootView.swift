import SwiftUI

/// Five tabs with the custom tab bar. Insights and Mood are pushed inside Today, so Today stays active.
struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            NavigationStack(path: $router.todayPath) {
                TodayView()
                    .navigationDestination(for: TodayRoute.self) { route in
                        switch route {
                        case .insights: PlaceholderScreen(title: "Insights", backTitle: "Today")
                        case .mood: MoodView()
                        }
                    }
            }
            .toolbar(.hidden, for: .tabBar)
            .tag(AppTab.today)

            PlaceholderScreen(title: "Journal").toolbar(.hidden, for: .tabBar).tag(AppTab.journal)
            PlaceholderScreen(title: "Meditation").toolbar(.hidden, for: .tabBar).tag(AppTab.meditate)
            PlaceholderScreen(title: "Exercise").toolbar(.hidden, for: .tabBar).tag(AppTab.exercise)
            PlaceholderScreen(title: "Vision").toolbar(.hidden, for: .tabBar).tag(AppTab.vision)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TabBar(selection: $router.tab)
        }
        .environment(router)
        .background(Theme.background.ignoresSafeArea())
        #if DEBUG
        .onAppear(perform: applyDebugStartScreen)
        #endif
    }

    #if DEBUG
    /// Debug-only launch arguments for checking screens against the design:
    /// `-startTab journal`, `-startRoute mood|insights`, `-startLogger journal|meditation|exercise`.
    private func applyDebugStartScreen() {
        let defaults = UserDefaults.standard
        if let tab = defaults.string(forKey: "startTab").flatMap(AppTab.init(rawValue:)) { router.tab = tab }
        if defaults.string(forKey: "startRoute") == "mood" { router.todayPath = [.mood] }
        if defaults.string(forKey: "startRoute") == "insights" { router.todayPath = [.insights] }
        if let practice = defaults.string(forKey: "startLogger").flatMap(Practice.init(rawValue:)) {
            router.openLogger(for: practice)
        }
    }
    #endif
}

/// Stand-in for screens that later milestones build.
struct PlaceholderScreen: View {
    let title: String
    var backTitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let backTitle { BackButton(title: backTitle) }
            ScreenTitle(title: title)
            Spacer()
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    RootView()
        .modelContainer(SampleData.previewContainer)
        .preferredColorScheme(.dark)
}
