import SwiftUI
import UserNotifications

// MARK: - Tab1 仪表盘 v11（B1 健哥裁定的"今日待办驾驶舱"框架）
// 结构：断记横幅 → 状态层（已控制/三数字） → 健康档案卡（未填时） → 今日待办行（记完消失）
//       → 查阅卡（建议饮食——健哥裁 C3 必须放仪表盘） → 事件型快捷区（记发作/记化验）

struct DashboardView: View {
    @ObservedObject var store = Store.shared
    @State private var showGapConfirm = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    if store.needsGapConfirm { gapBanner }
                    wellControlledBadge
                    bigNumbers
                    if !store.profile.isComplete { profileCard }
                    todayTodos       // 待办驱动：记完的行消失
                    greenZoneCard    // 建议饮食查阅卡（C3）
                    quickActions     // 事件型（发作/化验不每天发生，固定保留）
                    recallAlarmCard  // 回忆闹钟设置卡（B6）
                }
                .padding()
            }
            .navigationTitle("尿酸笔记")
            .sheet(isPresented: $showGapConfirm) { GapConfirmView() }
            .onAppear {
                if store.needsGapConfirm { showGapConfirm = true }
            }
        }
    }

    // 断记横幅（D8：文案覆盖全部记录类型，不只服药）
    private var gapBanner: some View {
        Button {
            showGapConfirm = true
        } label: {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                Text("有几天没打开了——补个确认，记录更准确")
                    .font(.callout)
                Spacer()
                Image(systemName: "chevron.right").font(.caption)
            }
            .padding(12)
            .background(Color.amber.opacity(0.15))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var wellControlledBadge: some View {
        if store.wellControlled {
            VStack(spacing: 4) {
                Label("已控制", systemImage: "rosette")
                    .font(.title2.bold())
                Text("痛风不再占据你的脑子")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.green.opacity(0.12))
            .cornerRadius(16)
        }
    }

    // 三数字（A5：距目标三段式用用户单位；复查倒计时显示推算过程+可调间隔）
    private var bigNumbers: some View {
        HStack(spacing: 12) {
            bigNum(value: store.flareFreeDays.map { "\($0)" } ?? "—", label: "无痛天数", footnote: store.flareFreeDays == nil ? "记录第一次发作后开始计数" : flareFootnote)
            NavigationLink { UricReadingPage() } label: {
                bigNum(value: deltaText, label: "距目标", footnote: deltaFootnote).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            NavigationLink { UricReadingPage() } label: {
                bigNum(value: reviewText, label: "复查倒计时", footnote: reviewFootnote).contentShape(Rectangle())
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
        guard store.lastReading != nil else { return "记一次化验值后出现" }
        return store.meta.unitIsUmol ? "目标 <360 µmol/L" : "目标 <6.0 mg/dL"
    }

    // A5：复查倒计时显示推算过程（上次 X + 8 周 = 复查 Y）
    private var reviewText: String {
        guard let d = store.daysToReview else { return "—" }
        return d <= 0 ? "该查了" : "\(d)天"
    }
    private var reviewFootnote: String {
        guard let next = store.review.nextReviewDate else { return "录化验值自动排" }
        let df = DateFormatter(); df.dateFormat = "M/d"
        return "每\(store.review.intervalWeeks)周 · 下次 \(df.string(from: next))"
    }

    private var flareFootnote: String {
        guard let d = store.flareFreeDays else { return "" }
        if d == 0 { return "从今天开始计数" }
        if d < 30 { return "正在路上" }
        if d < 90 { return "结晶在溶解" }
        return "已控制标准：90 天+达标"
    }

    // A6/C11：健康档案卡（未填时前置，填完消失；趋势页置顶引用）
    private var profileCard: some View {
        NavigationLink { HealthProfileEditor() } label: {
            HStack {
                Image(systemName: "person.text.rectangle").foregroundColor(.teal)
                VStack(alignment: .leading, spacing: 2) {
                    Text("健康档案").font(.callout.weight(.semibold))
                    Text("身高体重/年龄/现有疾病/过敏史——医生看记录先想知道这些")
                        .font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.teal.opacity(0.08))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // 今日待办行（B1 驾驶舱核心：该记没记的显示，记完打勾消失）
    private var todayTodos: some View {
        VStack(spacing: 8) {
            // ① 昨晚入睡（B2）
            if store.lastNightSleep == nil {
                todoRow(icon: "moon.fill", color: .indigo, title: "昨晚几点睡的？") {
                    SleepQuickPicker()
                }
            }
            // ② 喝水（A2：点一次记一杯，显示今日合计）
            if let w = store.todayWater, w.provenance != .estimated, w.totalMl == 0 {
                todoRow(icon: "drop.fill", color: .cyan, title: "今天还没记水") {
                    WaterPage()
                }
            }
            // ③ 服药打卡
            if store.medPlans.contains(where: { $0.active }),
               !store.medLogs.contains(where: { Calendar.current.isDateInToday($0.date) && $0.taken }) {
                todoRow(icon: "pills", color: .blue, title: "今天的药还没打卡") {
                    MedTodayView()
                }
            }
            // ④ 高嘌呤负面记录（B3：没碰也要记，防诱因排行虚高）
            if store.todayFood == nil {
                todoRow(icon: "fork.knife", color: .orange, title: "今天碰高嘌呤了吗？没碰也记一下") {
                    FoodPage()
                }
            }
            // ⑤ 习惯种子（B5：起步脚手架明示+毕业机制）
            if let seed = store.seed, !seed.graduated {
                seedRow(seed)
            }
            // 全部完成态（情绪出口：一天照顾好自己的可视化）
            if allDone {
                HStack {
                    Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                    Text("今天的都记完了——照顾好自己的一天").font(.callout)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.green.opacity(0.08))
                .cornerRadius(12)
            }
        }
    }

    private var allDone: Bool {
        store.lastNightSleep != nil
            && (store.todayWater.map { $0.totalMl > 0 || $0.provenance == .estimated } ?? true)
            && (!store.medPlans.contains(where: { $0.active })
                || store.medLogs.contains(where: { Calendar.current.isDateInToday($0.date) && $0.taken }))
            && store.todayFood != nil
    }

    // 种子行（B5：起步定位说明+毕业进度）
    private func seedRow(_ seed: Seed) -> some View {
        HStack {
            Image(systemName: "leaf").foregroundColor(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("习惯种子：\(seedTitle(seed.type))").font(.callout.weight(.medium))
                Text("起步阶段脚手架（非永久任务）· 连续 \(seed.realStreak)/14 天").font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Button("打卡") { seedDone(seed) }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func seedTitle(_ t: String) -> String {
        switch t { case "water": return "每天喝一杯水"; case "med": return "每晚记一次药"; case "weigh": return "每周称一次体重"; default: return t }
    }

    // B5/C9：打卡情绪奖励（中文+进度感）；毕业机制（14 天庆祝隐退）
    private func seedDone(_ seed: Seed) {
        var s = seed
        s.realStreak += 1
        if s.realStreak >= 14 { s.unlockedSecond = true }
        store.seed = s
        store.meta.seedVotesTotal += 1
        if s.realStreak == 14 {
            s.graduated = true
            store.seed = s
            UricCelebrate.show("毕业了！14 天连续——这个习惯已经是你的了，种子光荣退役 🎉")
        } else {
            UricCelebrate.show("第 \(s.realStreak) 天 ✓ 还有 \(14 - s.realStreak) 天毕业")
        }
    }

    // C3：建议饮食查阅卡（仪表盘常驻——健哥裁：这是用户打开 App 的理由）
    private var greenZoneCard: some View {
        NavigationLink { FoodGuideView() } label: {
            HStack {
                Image(systemName: "leaf.circle.fill").foregroundColor(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("今天能吃什么？").font(.callout.weight(.semibold))
                    Text("中低嘌呤白名单+适量注意清单（点击查阅）").font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.green.opacity(0.08))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // 事件型快捷区（B1：不是每天发生的，固定保留两三个）
    private var quickActions: some View {
        VStack(spacing: 10) {
            NavigationLink {
                FlareEditorView()
            } label: {
                Label("记一次发作", systemImage: "exclamationmark.triangle")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            HStack(spacing: 10) {
                NavigationLink("记化验值") { UricReadingPage() }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                NavigationLink("记体重") { WeightEditor() }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }

    // B6/C10：回忆闹钟卡（开关+时间可调）
    private var recallAlarmCard: some View {
        NavigationLink { RecallAlarmEditor() } label: {
            HStack {
                Image(systemName: "alarm").foregroundColor(.purple)
                VStack(alignment: .leading, spacing: 2) {
                    Text("每晚回顾提醒").font(.callout.weight(.medium))
                    Text(store.recall.enabled
                         ? "每天 \(String(format: "%02d:%02d", store.recall.hour, store.recall.minute)) 提醒你回顾今天（不用每件事当场记）"
                         : "晚上固定时间提醒你回顾当天——不用每件事当场记")
                        .font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: store.recall.enabled ? "bell.fill" : "bell.slash")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// 待办行通用容器
struct todoRow<Dest: View>: View {
    let icon: String
    let color: Color
    let title: String
    @ViewBuilder let dest: () -> Dest

    var body: some View {
        NavigationLink { dest() } label: {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Text(title).font(.callout)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemGray6))
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
        .background(Color(.systemGray6))
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
            Text("昨晚几点睡的？").font(.title3.bold())
            VStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { b in
                    Button {
                        let lastNight = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
                        store.sleepLogs.append(SleepLog(night: lastNight, bucket: b))
                        UricCelebrate.show("记下了" + (b >= 2 ? "——睡太晚也会诱发发作，今晚早点休息" : ""))
                        dismiss()
                    } label: {
                        Text(["23 点前", "23 点-24 点", "0 点-1 点", "1 点后"][b])
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("只记入睡就够了（C2）。熬夜会升高炎症水平——记下来看和发作的关联。")
                .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .padding(24)
    }
}

// MARK: - 建议饮食查阅页（C3：仪表盘卡点进；绿区+黄区+证据注释）
struct FoodGuideView: View {
    var body: some View {
        List {
            Section("🟢 放心吃") {
                ForEach(FoodLibrary.greenZone) { f in
                    foodRow(f)
                }
            }
            Section("🟡 适量注意") {
                ForEach(FoodLibrary.yellowZone) { f in
                    foodRow(f)
                }
            }
            Section("🔴 高嘌呤红区（记饮食里多选登记）") {
                ForEach(FoodLibrary.redZone) { f in
                    foodRow(f)
                }
            }
        }
        .navigationTitle("今天能吃什么？")
    }

    private func foodRow(_ f: FoodItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(f.name).font(.body.weight(.medium))
            if let n = f.note { Text(n).font(.caption).foregroundColor(.secondary) }
        }
    }
}

// MARK: - 回忆闹钟设置（B6/C10：开关+时间+本地通知）
struct RecallAlarmEditor: View {
    @ObservedObject var store = Store.shared

    var body: some View {
        Form {
            Toggle("开启每晚回顾提醒", isOn: Binding(
                get: { store.recall.enabled },
                set: { on in
                    var r = store.recall
                    r.enabled = on
                    store.recall = r
                    if on { scheduleRecall() } else { cancelRecall() }
                }
            ))
            if store.recall.enabled {
                DatePicker("提醒时间", selection: Binding(
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
        .navigationTitle("回顾提醒")
        .onAppear { if store.recall.enabled { scheduleRecall() } }
    }

    private func scheduleRecall() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "UricNote 回顾"
            content.body = "回顾一下今天：药吃了吗？水喝够了吗？碰高嘌呤了吗？"
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

// MARK: - 健康档案编辑（A6/C11：七基础+共病多选+过敏两栏+家族史+HLA）
struct HealthProfileEditor: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss

    private let conditionOptions = ["高血压", "糖尿病", "高血脂", "肾结石"]
    private let familyOptions = ["有", "无", "不确定"]
    private let hlaOptions = ["查过-阴性", "查过-阳性", "没查过"]

    var body: some View {
        Form {
            Section("基础信息") {
                HStack {
                    TextField("身高", text: Binding(get: { store.profile.heightCm.map { String(Int($0)) } ?? "" }, set: { store.profile.heightCm = Double($0) }))
                        .keyboardType(.numberPad)
                    Text("cm").foregroundColor(.secondary)
                }
                HStack {
                    TextField("体重", text: Binding(get: { store.profile.weightKg.map { String(format: "%.1f", $0) } ?? "" }, set: { store.profile.weightKg = Double($0) }))
                        .keyboardType(.decimalPad)
                    Text("kg").foregroundColor(.secondary)
                }
                HStack {
                    TextField("年龄", text: Binding(get: { store.profile.age.map { String($0) } ?? "" }, set: { store.profile.age = Int($0) }))
                        .keyboardType(.numberPad)
                    Text("岁").foregroundColor(.secondary)
                }
                Picker("性别", selection: Binding(get: { store.profile.gender ?? "男" }, set: { store.profile.gender = $0 })) {
                    Text("男").tag("男"); Text("女").tag("女"); Text("其他").tag("其他")
                }
                TextField("地区（如：广东广州）", text: Binding(get: { store.profile.region ?? "" }, set: { store.profile.region = $0 }))
            }
            Section("现有疾病（可多选）") {
                ForEach(conditionOptions, id: \.self) { c in
                    Button {
                        if store.profile.conditions.contains(c) { store.profile.conditions.removeAll { $0 == c } }
                        else { store.profile.conditions.append(c) }
                    } label: {
                        HStack {
                            Text(c).foregroundColor(.primary)
                            Spacer()
                            if store.profile.conditions.contains(c) { Image(systemName: "checkmark").foregroundColor(.accentColor) }
                        }
                    }
                }
            }
            Section("过敏史") {
                TextField("药物过敏（如：别嘌醇过敏）", text: Binding(get: { store.profile.drugAllergies ?? "" }, set: { store.profile.drugAllergies = $0.isEmpty ? nil : $0 }))
                TextField("食物过敏", text: Binding(get: { store.profile.foodAllergies ?? "" }, set: { store.profile.foodAllergies = $0.isEmpty ? nil : $0 }))
            }
            Section("家族史与基因") {
                Picker("直系亲属有痛风吗", selection: Binding(get: { store.profile.familyGout ?? "不确定" }, set: { store.profile.familyGout = $0 })) {
                    ForEach(familyOptions, id: \.self) { Text($0).tag($0) }
                }
                Picker("HLA-B*5801 检测（别嘌醇基因筛查）", selection: Binding(get: { store.profile.hlaTested ?? "没查过" }, set: { store.profile.hlaTested = $0 })) {
                    ForEach(hlaOptions, id: \.self) { Text($0).tag($0) }
                }
            } footer: {
                Text("汉族人群 HLA-B*5801 携带率较高——别嘌醇超敏反应风险相关，指南建议用药前筛查。以上信息只进你的档案和门诊记录，App 不做任何诊断。")
            }
            Button("保存档案") {
                store.profile.isComplete = true
                UricCelebrate.show("档案建好了——门诊记录会自动带上")
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("健康档案")
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
                .foregroundColor(.amber)
            Text("过去几天没有你的记录")
                .font(.title3.bold())
            Text("这段时间服药正常吗？（只补服药打卡，水/饮食不受影响）")
                .font(.body)
            VStack(spacing: 10) {
                gapButton("✓ 正常，都吃了", value: "normal")
                gapButton("✗ 有漏", value: "missed")
                gapButton("— 不记得 / 不想补", value: "unknown")
            }
            Text("确认后这几天标为「按计划」；已有实测打卡的日子不会覆盖——医生能分清实测和补记。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("先跳过") { dismiss() }
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
                .background(Color(.systemGray6))
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

extension Color {
    static let amber = Color(red: 0.96, green: 0.70, blue: 0.20)
}
