import SwiftUI

@main
struct UricNoteApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - 根视图（四Tab：仪表盘/记录/趋势/了解）+ Onboarding 接管 —— 中文测试版

struct RootView: View {
    @StateObject private var store = Store.shared
    @State private var tab = 0
    @AppStorage("hasLaunchedOnce") private var hasLaunchedOnce = false

    var body: some View {
        if !store.meta.onboardingDone {
            OnboardingView()
        } else {
            TabView(selection: $tab) {
                DashboardView()
                    .tabItem { Label("仪表盘", systemImage: "speedometer") }
                    .tag(0)
                RecordListView()
                    .tabItem { Label("记录", systemImage: "square.and.pencil") }
                    .tag(1)
                TrendView()
                    .tabItem { Label("趋势", systemImage: "chart.xyaxis.line") }
                    .tag(2)
                LearnView()
                    .tabItem { Label("了解", systemImage: "book") }
                    .tag(3)
            }
            .onAppear {
                if !hasLaunchedOnce { hasLaunchedOnce = true }
                store.meta.lastOpenedAt = Date()
                store.save()
            }
        }
    }
}
