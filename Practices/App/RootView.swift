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
                        case .mood: PlaceholderScreen(title: "Mood", backTitle: "Today")
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
    }
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
