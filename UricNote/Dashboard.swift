import SwiftUI
import UserNotifications

// MARK: - Tab1 仪表盘 v11.1（待办驾驶舱 + TaskRing 圆形任务圈 + 记无痛 + 用药按次）
// 结构：断记横幅 → 状态层（已控制/三数字/记无痛） → 健康档案卡（未填时） → 今日待办行（记完消失）
//       → 常驻快捷区（喝水/饮食/吃药——健哥裁：天天用的长挂） → 查阅卡（中低嘌呤清单） → 事件型快捷区（发作/化验/体重）

struct DashboardView: View {
    @ObservedObject var store = Store.shared
    @State private var showGapConfirm = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    if store.needsGapConfirm { gapBanner }
                    motivationBanner   // 健哥11-21令：引导选的动机上仪表盘铭牌（含L("Other", "其他")自填回显）
                    wellControlledBadge
                    bigNumbers
                    painFreeConfirmRow   // v11.1 #9：记无痛（C 方案）
                    if !store.profile.isComplete { profileCard }
                    todayTodos       // 待办驱动：记完的行消失
                    dailyShortcuts   // v11.1 #5：喝水/饮食常驻快捷
                    greenZoneCard    // 中低嘌呤清单查阅卡（v11.1 #2 改名）
                    quickActions     // 事件型（发作/化验/体重）
                }
                .padding()
            }
            .navigationTitle(L("UricNote", "尿酸笔记"))
            .sheet(isPresented: $showGapConfirm) { GapConfirmView() }
            .onAppear {
                if store.needsGapConfirm { showGapConfirm = true }
            }
        }
    }

    // 动机铭牌（健哥11-21令：你管理尿酸的原因——一直陪着你）
    @ViewBuilder
    private var motivationBanner: some View {
        if let m = store.meta.motivation {
            HStack(spacing: 10) {
                Image(systemName: "quote.opening")
                    .foregroundColor(.brand)
                Text(m == .other ? (store.meta.motivationCustomText ?? L("For myself", "为了自己")) : L("Your reason for managing uric acid: \(m.displayName)", "你管理尿酸，最重要的原因是：\(m.displayName)"))
                    .font(.callout.weight(.medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.brand.opacity(0.08))
            .cornerRadius(12)
        }
    }

    // 断记横幅（D8：文案覆盖全部记录类型，不只服药）
    private var gapBanner: some View {
        Button {
            showGapConfirm = true
        } label: {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                Text(L("A few days unopened — confirm to keep records accurate", "有几天没打开了——补个确认，记录更准确"))
                    .font(.callout)
                Spacer()
                Image(systemName: "chevron.right").font(.caption)
            }
            .padding(12)
            .background(Color.warn.opacity(0.15))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var wellControlledBadge: some View {
        if store.wellControlled {
            VStack(spacing: 4) {
                Label(L("Controlled", "已控制"), systemImage: "rosette")
                    .font(.title2.bold())
                Text(L("gout no longer occupying your mind", "痛风不再占据你的脑子"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.success.opacity(0.12))
            .cornerRadius(16)
        }
    }

    // 三数字（A5：距目标三段式用用户单位；复查倒计时显示推算过程+可调间隔）
    private var bigNumbers: some View {
        HStack(spacing: 12) {
            bigNum(value: store.flareFreeDays.map { "\($0)" } ?? "—", label: L("Pain-free days", "无痛天数"), footnote: store.flareFreeDays == nil ? L("Counting from your first logged flare", "记录第一次发作后开始计数") : flareFootnote)
            NavigationLink { UricReadingPage() } label: {
                bigNum(value: deltaText, label: L("Last uric acid", "上次尿酸值"), footnote: deltaFootnote).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            NavigationLink { UricReadingPage() } label: {
                bigNum(value: reviewText, label: L("Recheck countdown", "复查倒计时"), footnote: reviewFootnote).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // A5/D9：三段式——最新 420 µmol/L → 目标 <360 → 还差 60（全用户单位）
    private var deltaText: String {
        guard let r = store.lastReading else { return "—" }
        if store.meta.unitIsUmol {
            let u = r.urateUnit, goal = 360.0
            return String(format: "%.0f", max(0, u - goal)) + (r.atTarget ? "✓" : "")
        } else {
            return String(format: "%.1f", max(0, r.valueMgDl - 6.0)) + (r.atTarget ? "✓" : "")
        }
    }
    private var deltaFootnote: String {
        guard store.lastReading != nil else { return L("appears after your first lab value", "记一次化验值后出现") }
        return store.meta.unitIsUmol ? L("Target <360 µmol/L", "目标 <360 µmol/L") : L("Target <6.0 mg/dL", "目标 <6.0 mg/dL")
    }

    // A5：复查倒计时显示推算过程（上次 X + 8 周 = 复查 Y）
    private var reviewText: String {
        guard let d = store.daysToReview else { return "—" }
        return d <= 0 ? L("Due now", "该查了") : L("\(d)d", "\(d)天")
    }
    private var reviewFootnote: String {
        guard let next = store.review.nextReviewDate else { return L("Auto-scheduled on first lab entry", "录化验值自动排") }
        let df = DateFormatter(); df.dateFormat = "M/d"
        return L("Every \(store.review.intervalWeeks) wks · next \(df.string(from: next))", "每\(store.review.intervalWeeks)周 · 下次 \(df.string(from: next))")
    }

    private var flareFootnote: String {
        guard let d = store.flareFreeDays else { return "" }
        if d == 0 { return L("Counting from today", "从今天开始计数") }
        if d < 30 { return L("On your way", "正在路上") }
        if d < 90 { return L("Crystals dissolving", "结晶在溶解") }
        return L("Controlled: 90 days + at target", "已控制标准：90 天+达标")
    }

    // A6/C11：健康档案卡（未填时前置，填完消失；趋势页置顶引用）
    private var profileCard: some View {
        NavigationLink { HealthProfileEditor() } label: {
            HStack {
                Image(systemName: "person.text.rectangle").foregroundColor(.brand)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Health profile", "健康档案")).font(.callout.weight(.semibold))
                    Text(L("Height/weight/age/conditions/allergies — what doctors ask first", "身高体重/年龄/现有疾病/过敏史——医生看记录先想知道这些"))
                        .font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.brand.opacity(0.08))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // 今日待办行（B1 驾驶舱核心：该记没记的显示，记完打勾消失）
    private var todayTodos: some View {
        VStack(spacing: 8) {
            // 健哥11-21令：每晚回顾提醒上移到"昨晚几点睡的？"上方
            recallAlarmCardInline
            // ① 昨晚入睡（B2）
            if store.lastNightSleep == nil {
                todoRow(icon: "moon.fill", color: .brand, title: L("What time did you sleep?", "昨晚几点睡的？")) {
                    SleepQuickPicker()
                }
            }
            // ② 吃药打卡（v11.1 #5：一天 N 次出 N 次待办行）
            ForEach(store.todayMedTodos.filter { !$0.done }, id: \.slot) { t in
                medTodoRow(plan: t.plan, slot: t.slot)
            }
            // 全部完成态（情绪出口：一天照顾好自己的可视化）
            if allDone {
                HStack {
                    Image(systemName: "checkmark.seal.fill").foregroundColor(.success)
                    Text(L("All logged for today — a day of taking care of yourself", "今天的都记完了——照顾好自己的一天")).font(.callout)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.success.opacity(0.08))
                .cornerRadius(12)
            }
        }
    }

    // v11.1 #5：常驻快捷区（喝水/饮食/吃药天天用——健哥裁长挂仪表盘）
    private var dailyShortcuts: some View {
        HStack(spacing: 10) {
            NavigationLink {
                WaterPage()
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "drop.fill").font(.title3).foregroundColor(.water)
                    Text(waterShortcutText).font(.caption.weight(.medium))
                    Text(L("Water", "喝水")).font(.caption2).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.water.opacity(0.08))
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
            NavigationLink {
                FoodPage()
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "fork.knife").font(.title3).foregroundColor(.warn)
                    Text(foodShortcutText).font(.caption.weight(.medium))
                    Text(L("Food", "饮食")).font(.caption2).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.warn.opacity(0.08))
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
            NavigationLink {
                MedTodayView()
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "pills").font(.title3).foregroundColor(.brand)
                    Text(medShortcutText).font(.caption.weight(.medium))
                    Text(L("Meds", "吃药")).font(.caption2).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.brand.opacity(0.08))
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
        }
    }

    private var waterShortcutText: String {
        guard let w = store.todayWater else { return "—" }
        if w.provenance == .estimated { return L("auto", "沿用") }
        return "\(w.totalMl)ml"
    }
    private var foodShortcutText: String {
        guard let f = store.todayFood else { return L("not logged", "未记") }
        if f.noTriggerToday { return L("none ✓", "没碰 ✓") }
        return f.items.isEmpty && f.scenes.isEmpty ? L("Not logged", "未记") : L("Logged ✓", "已记 ✓")
    }
    private var medShortcutText: String {
        let todos = store.todayMedTodos
        guard !todos.isEmpty else { return "—" }
        let done = todos.filter { $0.done }.count
        return "\(done)/\(todos.count)"
    }

    // 用药待办行（v11.1：N 次出 N 行，点击直打卡不进页面）
    private func medTodoRow(plan: MedPlan, slot: Int) -> some View {
        Button {
            let log = MedLog(date: Date(), planRef: plan.id, taken: true, slot: slot, provenance: .recorded)
            store.medLogs.append(log)
            Haptic.success()
            UricCelebrate.show(L("Logged \(Store.medSlotLabel(slot)) dose ✓", "已记\(Store.medSlotLabel(slot))的药 ✓"))
        } label: {
            HStack {
                TaskRing(done: false, tint: .brand)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Log \(Store.medSlotLabel(slot)) dose (\(plan.name) \(plan.dose))", "记\(Store.medSlotLabel(slot))的药（\(plan.name) \(plan.dose)）")).font(.callout)
                    Text(L("Tap to log", "点一下直接打卡")).font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(Color.cardBG)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // v11.1 #9：记无痛（C 方案：自动算+确认权）
    @ViewBuilder
    private var painFreeConfirmRow: some View {
        if store.canConfirmPainFreeToday {
            Button {
                store.confirmPainFreeToday()
                Haptic.success()
                UricCelebrate.show(L("Today logged pain-free ✓", "已记录今天无痛 ✓"))
            } label: {
                HStack {
                    Image(systemName: "sun.max.fill").foregroundColor(.success)
                    Text(L("Log a pain-free day", "记今天无痛")).font(.callout.weight(.semibold))
                    Spacer()
                    Text(L("\(store.flareFreeDays ?? 0) pain-free days", "无痛 \(store.flareFreeDays ?? 0) 天")).font(.caption).foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.success.opacity(0.08))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }

    private var allDone: Bool {
        store.lastNightSleep != nil
            && (store.todayWater.map { $0.totalMl > 0 || $0.provenance == .estimated } ?? true)
            && store.todayMedTodos.allSatisfy { $0.done }
            && store.todayFood != nil
    }

    // C3/v11.1 #2：中低嘌呤清单查阅卡（去"今天能吃什么"限制性措辞——引导不限制）
    private var greenZoneCard: some View {
        // 健哥11-22令2：中低嘌呤清单=与管理日常食物页一致（同源PurineDatabase+分类结构）
        NavigationLink { PurineListView() } label: {
            HStack {
                Image(systemName: "leaf.circle.fill").foregroundColor(.success)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Low & moderate purine list", "中低嘌呤清单")).font(.callout.weight(.semibold))
                    Text(L("Safe & moderate foods (tap to browse)", "放心吃与适量注意（点击查阅）")).font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.success.opacity(0.08))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // 事件型快捷区（B1：不是每天发生的，固定保留）
    private var quickActions: some View {
        VStack(spacing: 10) {
            NavigationLink {
                FlareEditorView()
            } label: {
                Label(L("Log a flare", "记一次发作"), systemImage: "exclamationmark.triangle")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.danger)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            HStack(spacing: 10) {
                // 健哥11-21令：记化验值取消（走三数字区入口）——记体重保留
                NavigationLink(L("Log weight", "记体重")) { WeightEditor() }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.cardBG)
                    .cornerRadius(12)
            }
        }
    }

    // B6/C10：回忆闹钟卡（开关+时间可调；健哥11-21令：上移到待办区顶部）
    private var recallAlarmCardInline: some View {
        NavigationLink { RecallAlarmEditor() } label: {
            HStack {
                Image(systemName: "alarm").foregroundColor(.brand)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Evening review reminder", "每晚回顾提醒")).font(.callout.weight(.medium))
                    Text(store.recall.enabled
                         ? L("Daily \(String(format: "%02d:%02d", store.recall.hour, store.recall.minute)) review reminder — no need to log everything on the spot", "每天 \(String(format: "%02d:%02d", store.recall.hour, store.recall.minute)) 提醒你回顾今天（不用每件事当场记）")
                         : L("A fixed evening time to review the day — no need to log everything on the spot", "晚上固定时间提醒你回顾当天——不用每件事当场记"))
                        .font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: store.recall.enabled ? "bell.fill" : "bell.slash")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.cardBG)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// 待办行通用容器（v11.1：TaskRing 圆形任务圈替代图标）
struct todoRow<Dest: View>: View {
    let icon: String
    let color: Color
    let title: String
    @ViewBuilder let dest: () -> Dest

    var body: some View {
        NavigationLink { dest() } label: {
            HStack {
                TaskRing(done: false, tint: color)
                Text(title).font(.callout)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.cardBG)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct bigNum: View {
    let value: String
    let label: String
    let footnote: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title.bold())
            Text(label).font(.caption.weight(.medium))
            Text(footnote).font(.caption2).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.cardBG)
        .cornerRadius(14)
    }
}

// MARK: - 入睡快捷四档（B2：2 秒选完）
struct SleepQuickPicker: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.fill").font(.largeTitle).foregroundColor(.indigo)
            Text(L("What time did you sleep last night?", "昨晚几点睡的？")).font(.title3.bold())
            VStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { b in
                    Button {
                        let lastNight = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
                        store.sleepLogs.append(SleepLog(night: lastNight, bucket: b))
                        UricCelebrate.show(L("Logged", "记下了") + (b >= 2 ? L(" — late nights can trigger flares; rest early tonight", "——睡太晚也会诱发发作，今晚早点休息") : ""))
                        dismiss()
                    } label: {
                        Text([L("before 11 PM", "23 点前"), L("11 PM–12 AM", "23 点-24 点"), L("12–1 AM", "0 点-1 点"), L("after 1 AM", "1 点后")][b])
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.cardBG)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(L("Just log bedtime. Late nights raise inflammation — track it against flares.", "只记入睡就够了（C2）。熬夜会升高炎症水平——记下来看和发作的关联。"))
                .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .padding(24)
    }
}

// MARK: - 中低嘌呤清单查阅页（v11.1 #2 改名去限制性措辞；#3 红区 8 分类+每项 ⓘ 来源）
struct FoodGuideView: View {
    var body: some View {
        List {
            Section(L("🟢 Eat freely (low purine)", "🟢 放心吃（中低嘌呤）")) {
                ForEach(FoodLibrary.greenZone) { f in
                    foodRow(f, tint: .success)
                }
            }
            Section(L("🟡 Moderate — watch portions", "🟡 适量注意")) {
                ForEach(FoodLibrary.yellowZone) { f in
                    foodRow(f, tint: .warn)
                }
            }
            // v11.1 #3：红区 8 分类分组展示
            ForEach(FoodLibrary.groups, id: \.header) { g in
                Section {
                    ForEach(g.items) { f in
                        foodRow(f, tint: .danger)
                    }
                } header: {
                    Text("🔴 \(g.header)")
                }
            }
        }
        .navigationTitle(L("Low & moderate purine list", "中低嘌呤清单"))
        .toolbar {
            NavigationLink {
                FoodSourcePage()
            } label: {
                Label(L("Source", "来源"), systemImage: "info.circle")
            }
        }
    }

    private func foodRow(_ f: FoodItem, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(f.name).font(.body.weight(.medium)).foregroundColor(.primary)
                // v11.1 #3：ⓘ 来源快捷入口（信任件）
                NavigationLink {
                    FoodSourcePage(highlight: f.source)
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.brand)
                }
                .buttonStyle(.plain)
            }
            if let n = f.note { Text(n).font(.caption).foregroundColor(.secondary) }
            Text(L("Source: \(f.source)", "来源：\(f.source)")).font(.caption2).foregroundColor(.secondary.opacity(0.7))
        }
    }
}

// MARK: - 数据来源页（v11.1 #3：官方权威文献出处——信任件）
struct FoodSourcePage: View {
    var highlight: String? = nil   // 从食物项 ⓘ 进来时高亮对应来源

    var body: some View {
        List {
            Section {
                Text(L("Every food rating has a source — we don't decide for you, we show what the evidence says.", "每条食物分级都有出处——不替你决定吃不吃，只告诉你证据怎么说。"))
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            ForEach(FoodSourceCatalog.all, id: \.name) { s in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(s.name).font(.body.weight(.semibold))
                        if s.name == highlight {
                            Text(L("Entry source", "当前条目来源")).font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.brand.opacity(0.12))
                                .foregroundColor(.brand)
                                .clipShape(Capsule())
                        }
                    }
                    Text(s.desc).font(.caption).foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .navigationTitle(L("Data sources", "数据来源"))
    }
}

// MARK: - 回忆闹钟设置（B6/C10：开关+时间+本地通知）
struct RecallAlarmEditor: View {
    @ObservedObject var store = Store.shared

    var body: some View {
        Form {
            Toggle(L("Enable evening review reminder", "开启每晚回顾提醒"), isOn: Binding(
                get: { store.recall.enabled },
                set: { on in
                    var r = store.recall
                    r.enabled = on
                    store.recall = r
                    if on { scheduleRecall() } else { cancelRecall() }
                }
            ))
            if store.recall.enabled {
                DatePicker(L("Reminder time", "提醒时间"), selection: Binding(
                    get: {
                        Calendar.current.date(bySettingHour: store.recall.hour, minute: store.recall.minute, second: 0, of: Date()) ?? Date()
                    },
                    set: { d in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                        var r = store.recall
                        r.hour = c.hour ?? 21; r.minute = c.minute ?? 30
                        store.recall = r
                        scheduleRecall()
                    }
                ), displayedComponents: .hourAndMinute)
            }
        }
        .navigationTitle(L("Evening review reminder", "回顾提醒"))
        .onAppear { if store.recall.enabled { scheduleRecall() } }
    }

    private func scheduleRecall() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "UricNote"
            content.body = L("Review today: meds taken? Enough water? Any high-purine food?", "回顾一下今天：药吃了吗？水喝够了吗？碰高嘌呤了吗？")
            content.sound = .default
            var comps = DateComponents()
            comps.hour = store.recall.hour; comps.minute = store.recall.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            center.add(UNNotificationRequest(identifier: "ur.recall.daily", content: content, trigger: trigger))
        }
    }
    private func cancelRecall() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["ur.recall.daily"])
    }
}

// MARK: - 健康档案编辑（A6/C11 + v11.1 #1 自填与不清楚）
struct HealthProfileEditor: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss
    @State private var customCondition = ""

    private let conditionOptions = [L("Hypertension", "高血压"), L("Diabetes", "糖尿病"), L("High cholesterol", "高血脂"), L("Kidney stones", "肾结石"), L("Fatty liver", "脂肪肝")]   // 健哥11-21令+脂肪肝
    private let familyOptions = [L("Yes", "有"), L("No", "无"), L("Not sure", "不确定")]

    var body: some View {
        Form {
            Section(L("Basics", "基础信息")) {
                HStack {
                    TextField(L("Height", "身高"), text: Binding(get: { store.profile.heightCm.map { String(Int($0)) } ?? "" }, set: { store.profile.heightCm = Double($0) }))
                        .keyboardType(.numberPad)
                    Text("cm").foregroundColor(.secondary)
                }
                HStack {
                    TextField(L("Weight", "体重"), text: Binding(get: { store.profile.weightKg.map { String(format: "%.1f", $0) } ?? "" }, set: { store.profile.weightKg = Double($0) }))
                        .keyboardType(.decimalPad)
                    Text("kg").foregroundColor(.secondary)
                }
                HStack {
                    TextField(L("Age", "年龄"), text: Binding(get: { store.profile.age.map { String($0) } ?? "" }, set: { store.profile.age = Int($0) }))
                        .keyboardType(.numberPad)
                    Text(L("years old", "岁")).foregroundColor(.secondary)
                }
                Picker(L("Gender", "性别"), selection: Binding(get: { store.profile.gender ?? "男" }, set: { store.profile.gender = $0 })) {
                    Text(L("Male", "男")).tag("男"); Text(L("Female", "女")).tag("女"); Text(L("Other", "其他")).tag("其他")
                }
                TextField(L("Region (e.g. Guangzhou)", "地区（如：广东广州）"), text: Binding(get: { store.profile.region ?? "" }, set: { store.profile.region = $0 }))
            }
            Section(L("Conditions (multi-select)", "现有疾病（可多选）")) {
                ForEach(conditionOptions, id: \.self) { c in
                    Button {
                        if store.profile.conditions.contains(c) { store.profile.conditions.removeAll { $0 == c } }
                        else { store.profile.conditions.append(c) }
                    } label: {
                        HStack {
                            Text(c).foregroundColor(.primary)
                            Spacer()
                            if store.profile.conditions.contains(c) { Image(systemName: "checkmark").foregroundColor(.brand) }
                        }
                    }
                }
                // v11.1 #1：不清楚选项
                Button {
                    if store.profile.conditions.contains(L("Not sure", "不清楚")) {
                        store.profile.conditions.removeAll { $0 == L("Not sure", "不清楚") }
                    } else {
                        store.profile.conditions = [L("Not sure", "不清楚")]
                    }
                } label: {
                    HStack {
                        Text(L("Not sure", "不清楚")).foregroundColor(.primary)
                        Spacer()
                        if store.profile.conditions.contains(L("Not sure", "不清楚")) { Image(systemName: "checkmark").foregroundColor(.brand) }
                    }
                }
                // v11.1 #1：自定义输入框
                HStack {
                    TextField(L("Other condition (e.g. thyroid)", "其他疾病自填（如：甲状腺问题）"), text: $customCondition)
                    Button(L("Add", "添加")) {
                        let v = customCondition.trimmingCharacters(in: .whitespaces)
                        if !v.isEmpty && !store.profile.conditions.contains(v) {
                            store.profile.conditions.removeAll { $0 == L("Not sure", "不清楚") }
                            store.profile.conditions.append(v)
                            store.save()   // 健哥11-21令修复：struct内层改动不触发didSet——显式落盘（点了添加无展现根因）
                            UricCelebrate.show(L("Added: \(v)", "已添加：\(v)"))
                        }
                        customCondition = ""
                    }
                    .disabled(customCondition.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                // 健哥11-21令：已添加的自定义疾病可见可删（无展现问题连根修）
                ForEach(store.profile.conditions.filter { !conditionOptions.contains($0) && $0 != L("Not sure", "不清楚") }, id: \.self) { c in
                    HStack {
                        Label(c, systemImage: "stethoscope")
                            .foregroundColor(.primary)
                        Spacer()
                        Button {
                            store.profile.conditions.removeAll { $0 == c }
                            store.save()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            Section(L("Allergies", "过敏史")) {
                TextField(L("Drug allergy (e.g. allopurinol)", "药物过敏（如：别嘌醇过敏）"), text: Binding(get: { store.profile.drugAllergies ?? "" }, set: { store.profile.drugAllergies = $0.isEmpty ? nil : $0 }))
                TextField(L("Food allergy", "食物过敏"), text: Binding(get: { store.profile.foodAllergies ?? "" }, set: { store.profile.foodAllergies = $0.isEmpty ? nil : $0 }))
            }
            Section {
                Picker(L("Immediate family with gout", "直系亲属有痛风吗"), selection: Binding(get: { store.profile.familyGout ?? L("Not sure", "不确定") }, set: { store.profile.familyGout = $0 })) {
                    ForEach(familyOptions, id: \.self) { Text($0).tag($0) }
                }
            } header: {
                Text(L("Family history", "家族史"))
            } footer: {
                Text(L("This info goes only to your profile and clinic report. The app makes no diagnosis.", "以上信息只进你的档案和门诊记录，App 不做任何诊断。"))
            }
            Button(L("Save profile", "保存档案")) {
                store.profile.isComplete = true
                UricCelebrate.show(L("Profile saved — clinic reports will include it", "档案建好了——门诊记录会自动带上"))
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle(L("Health profile", "健康档案"))
    }
}

// MARK: - 断记确认弹层（D4 逐日查重已在 Store；D8 文案已泛化）

struct GapConfirmView: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss
    @State private var answer: String = ""

    private var gapStart: Date {
        store.meta.lastOpenedAt ?? Calendar.current.date(byAdding: .day, value: -3, to: Date())!
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.largeTitle)
                .foregroundColor(.warn)
            Text(L("No records in the past few days", "过去几天没有你的记录"))
                .font(.title3.bold())
            Text(L("Did you take meds as planned in this period? (Only meds are backfilled)", "这段时间服药正常吗？（只补服药打卡，水/饮食不受影响）"))
                .font(.body)
            VStack(spacing: 10) {
                gapButton(L("✓ Normal, took all", "✓ 正常，都吃了"), value: "normal")
                gapButton(L("✗ Missed some", "✗ 有漏"), value: "missed")
                gapButton(L("— Don't remember / skip", "— 不记得 / 不想补"), value: "unknown")
            }
            Text(L("Confirmed days are marked 'as planned'; real logged days aren't overwritten — your doctor can tell them apart.", "确认后这几天标为「按计划」；已有实测打卡的日子不会覆盖——医生能分清实测和补记。"))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(L("Skip for now", "先跳过")) { dismiss() }
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(24)
    }

    private func gapButton(_ title: String, value: String) -> some View {
        Button {
            answer = value
            store.confirmGap(
                start: Calendar.current.date(byAdding: .day, value: -2, to: gapStart) ?? gapStart,
                end: Date(),
                answer: value
            )
            store.meta.lastOpenedAt = Date()
            dismiss()
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.cardBG)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 庆祝组件（D2：全中文；Fogg 动作后 1 秒内）

enum UricCelebrate {
    static func show(_ text: String) {
        let toast = UILabel()
        toast.text = "✓ " + text
        toast.font = .systemFont(ofSize: 14, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.92)
        toast.textAlignment = .center
        toast.numberOfLines = 0
        toast.layer.cornerRadius = 14
        toast.clipsToBounds = true
        toast.frame = CGRect(x: 30, y: 100, width: UIScreen.main.bounds.width - 60, height: 44)
        toast.autoresizingMask = [.flexibleWidth]
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = scene.windows.first(where: { $0.isKeyWindow }) {
            window.addSubview(toast)
            toast.transform = CGAffineTransform(translationX: 0, y: -60)
            UIView.animate(withDuration: 0.25) { toast.transform = .identity }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                UIView.animate(withDuration: 0.3, animations: { toast.alpha = 0 }) { _ in
                    toast.removeFromSuperview()
                }
            }
        }
    }
}

// amber 重复定义已删（CI run 44311079867 编译错误）：Theme.swift 已有 static let amber = warn
// 使用处 RecordListView.swift:310 / TrendView.swift:193 走 Theme 的定义即可
