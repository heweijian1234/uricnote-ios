import SwiftUI

@main
struct UricNoteApp: App {
    @StateObject private var pro = ProStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(pro)
                .task { await pro.load() }
        }
    }
}

// MARK: - 根视图（四Tab：仪表盘/记录/趋势/了解）+ Onboarding 接管 —— 中文测试版

struct RootView: View {
    @StateObject private var store = Store.shared
    @State private var tab = 0
    @AppStorage("hasLaunchedOnce") private var hasLaunchedOnce = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            // 🔴健哥11-22实测实锤"每次进都弹前三屏"——双保险判断：
            // meta.onboardingDone（Codable 链路）+ 独立 key 直写（绕开一切解码回退）
            if !store.meta.onboardingDone && !UserDefaults.standard.bool(forKey: "ur.onboarded.v2") {
                OnboardingView()
            } else {
                TabView(selection: $tab) {
                    DashboardView()
                        .tabItem { Label(L("Dashboard", "仪表盘"), systemImage: "speedometer") }
                        .tag(0)
                    RecordListView()
                        .tabItem { Label(L("Records", "记录"), systemImage: "square.and.pencil") }
                        .tag(1)
                    TrendView()
                        .tabItem { Label(L("Trends", "趋势"), systemImage: "chart.xyaxis.line") }
                        .tag(2)
                    LearnView()
                        .tabItem { Label(L("Learn", "了解"), systemImage: "book") }
                        .tag(3)
                }
                .onAppear {
                    if !hasLaunchedOnce { hasLaunchedOnce = true }
                    // 2026-11-26：只改 lastOpenedAt（meta 的 didSet 自己会落盘）。
                    // 去掉了原来这里的 store.save()——它是全量写盘，会把 load() 解码失败后
                    // 退回默认值的内存状态**立即覆盖磁盘原始数据**，用户数据一旦读不出就永久没了。
                    store.meta.lastOpenedAt = Date()
                    // 🔴第三重保险：进主界面即写独立 key（杀进程/解码回退都不影响）
                    UserDefaults.standard.set(true, forKey: "ur.onboarded.v2")
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                store.save()   // 进后台即全量落盘——杀进程不丢
            }
        }
    }
}
