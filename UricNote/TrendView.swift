import SwiftUI
import Charts

// MARK: - Tab3 趋势 v11（A6 档案置顶 / 趋势图 / 诱因排行含负面记录 / 改变页 / 门诊记录 A1）

struct TrendView: View {
    @ObservedObject var store = Store.shared
    @EnvironmentObject private var pro: ProStore
    @State private var showPaywall = false

    var body: some View {
        NavigationView {
            List {
                // 2026-11-26：健康档案入口从趋势页移除，统一走记录页顶部那处
                Section(L("Key trends", "关键趋势")) {
                    // 健哥11-23令⑩：依从率→药物使用30天详情（每日吃了没/止痛药）
                    trendRow(icon: "pills.fill", color: .brand, title: L("Medication — last 30 days", "药物使用（近 30 天）"), value: medDetailText)
                    trendRow(icon: "sun.max", color: .warn, title: L("Pain-free days", "无痛天数"), value: store.flareFreeDays.map { L("\($0) days", "\($0) 天") } ?? "—")

                    // 2026-11-26：原来的「近14天入睡平均值」「今天喝水」两行文字→趋势图，
                    // 范围 30 → 90 天（慢病要看长弧，14 天均值和单日值都读不出规律）
                    if store.sleepLogs.count >= 2 {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(L("Bedtime trend (last 90 days)", "入睡趋势（近 90 天）"))
                                .font(.callout)
                            Text(L("Higher dot = later bedtime. Gaps = days not logged.", "点越高睡得越晚。空白=当天没记。"))
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        .padding(.top, 2)

                        Chart(store.sleepLogs.suffix(90)) { s2 in
                            PointMark(
                                x: .value("Night", s2.night, unit: .day),
                                y: .value("bucket", s2.bucket)
                            )
                            .foregroundStyle(s2.bucket >= 2 ? Color.warn : Color.brand)
                        }
                        .chartYScale(domain: -0.5...3.5)
                        .chartYAxis {
                            AxisMarks(values: [0, 1, 2, 3]) { v in
                                AxisValueLabel(["<23", "23-24", "0-1", ">1"][min(v.index, 3)])
                            }
                        }
                        .frame(height: 110)
                        .padding(.vertical, 4)
                    }

                    if store.waterDays.count >= 2 {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(L("Water trend (last 90 days)", "喝水趋势（近 90 天）"))
                                .font(.callout)
                            Text(L("Solid bar = goal reached that day", "实心柱=当天达标"))
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        .padding(.top, 2)

                        Chart(store.waterDays.suffix(90)) { w in
                            BarMark(
                                x: .value("Day", w.day, unit: .day),
                                y: .value("ml", w.totalMl)
                            )
                            .foregroundStyle(w.totalMl >= w.goalMl ? Color.water : Color.water.opacity(0.35))
                        }
                        .chartYAxis { AxisMarks(position: .trailing) }
                        .frame(height: 110)
                        .padding(.vertical, 4)
                    }
                }
                // v11.1：坚持热力格（HabitKit 式——长期管理病的坚持度可视化）
                Section {
                    HeatGrid(levels: heatLevels)
                    HStack(spacing: 12) {
                        heatLegend(0, L("Not recorded", "未记录"))
                        heatLegend(1, L("1 habit", "记 1 类"))
                        heatLegend(2, L("2 habits", "记 2 类"))
                        heatLegend(3, L("All 3", "记满 3 类"))
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                } header: {
                    Text(L("Consistency (last 90 days)", "记录坚持（近 90 天）"))
                } footer: {
                    Text(L("Three habits: meds, water, food (sleep counts too). The grid shows your streaks — no judgment for missed days.", "三类=吃药打卡/喝水/饮食（入睡也算）。格子只给坚持可视化——不评判漏掉的格子。"))
                }
                Section {
                    // 2026-11-26：尿酸趋势图 + 诱因排行 纳入 Pro（健哥令）
                    if pro.isPro {
                        NavigationLink { UricTrendDetailView() } label: {
                            linkRow(icon: "chart.line.uptrend.xyaxis",
                                    title: L("Uric acid trend chart", "尿酸趋势图"),
                                    subtitle: L("Lab values with target line", "化验值折线+目标线"))
                        }
                        NavigationLink { TriggerRankView() } label: {
                            linkRow(icon: "sparkles",
                                    title: L("Trigger ranking", "诱因排行"),
                                    subtitle: triggerStatusText)
                        }
                    } else {
                        Button { showPaywall = true } label: {
                            linkRow(icon: "chart.line.uptrend.xyaxis",
                                    title: L("Uric acid trend chart", "尿酸趋势图"),
                                    subtitle: L("Pro — full history with target line", "Pro 功能——全部化验值+目标线"),
                                    locked: true)
                        }
                        .buttonStyle(.plain)

                        Button { showPaywall = true } label: {
                            linkRow(icon: "sparkles",
                                    title: L("Trigger ranking", "诱因排行"),
                                    subtitle: L("Pro — what you ate before each flare", "Pro 功能——每次发作前你吃了什么"),
                                    locked: true)
                        }
                        .buttonStyle(.plain)
                    }
                    NavigationLink { ChangeView() } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("the Change page", "「改变」页")).font(.body.weight(.medium))
                                Text(L("90 days vs sooner — your body's answer", "90 天 vs 更早——身体给你的答案")).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right").foregroundColor(.brand)
                        }
                    }
                } header: {
                    Text(L("It understands you better over time", "它越来越懂你"))
                }
                Section {
                    Button {
                        // 2026-11-25：11-21「前期免费换反馈」阶段结束，按 11-23 十资产报告恢复 Pro 收费
                        if pro.isPro {
                            ClinicReportGenerator.generate(store: store)
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: pro.isPro ? "doc.text.viewfinder" : "lock.fill")
                                .foregroundColor(pro.isPro ? .brand : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                // A1：门诊记录（不是医生报告——发给医生的日常记录）
                                HStack(spacing: 6) {
                                    Text(L("Life record export", "生活记录导出")).font(.body.weight(.medium))
                                    if !pro.isPro { ProTag() }
                                }
                                Text(pro.isPro
                                     ? L("Your complete life record — for doctor visits or self review", "完整生活记录——就诊时给医生看，或自己回顾")
                                     : L("Pro — one page your doctor can read in 15 minutes", "Pro 功能——一页纸，医生 15 分钟能看完"))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                } footer: {
                    Text(L("Your doctor has 15 minutes — this page is enough. Missing data is marked honestly, never faked.", "医生只有 15 分钟——这一页足够。缺失数据标「未记录」，沿用日标「沿用」，绝不冒充实测。"))
                }
            }
            .navigationTitle(L("Trends", "趋势"))
        }
        .sheet(isPresented: $showPaywall) { ProPaywallView().environmentObject(pro) }
    }

    private var profileLine: String {
        var parts: [String] = []
        if let a = store.profile.age { parts.append(L("\(a) y/o", "\(a)岁")) }
        if let g = store.profile.gender { parts.append(g) }
        if !store.profile.conditions.isEmpty { parts.append(L("Conditions: ", "共病：") + store.profile.conditions.joined(separator: "、")) }
        return parts.isEmpty ? L("Health profile", "健康档案") : parts.joined(separator: " · ")
    }

    /// 健哥11-23令⑩：药物30天详情文字（X天服用·Y天未服·Z次发作日止痛药）
    private var medDetailText: String {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let logs = store.medLogs.filter { $0.date >= cutoff }
        let active = store.medPlans.first(where: { $0.active })
        let takenDays = Set(logs.filter { $0.taken }.map { Calendar.current.startOfDay(for: $0.date) }).count
        let missedDays = Set(logs.filter { !$0.taken }.map { Calendar.current.startOfDay(for: $0.date) }).count
        // 止痛药=发作记录里的tookPainkiller为真且在30天内
        let pkCount = store.flares.filter { $0.startDate >= cutoff && ($0.tookPainkiller ?? false) }.count
        if active == nil && logs.isEmpty { return L("no plan", "无用药计划") }
        return L("\(takenDays)d taken · \(missedDays)d held · \(pkCount) painkiller uses", "\(takenDays)天服·\(missedDays)天未服·止痛药\(pkCount)次")
    }

    private var adherenceText: String {
        guard let r = store.adherenceRate else { return L("appears once you start logging", "开始记录后出现") }
        return String(format: "%.0f%%", r * 100)
    }

    private var sleepAvgText: String {
        let recent = store.sleepLogs.suffix(14)
        guard !recent.isEmpty else { return "—" }
        let avg = Double(recent.map { $0.bucket }.reduce(0, +)) / Double(recent.count)
        let idx = Int(avg.rounded())
        return [L("before 11 PM", "23点前"), L("11 PM–12 AM", "23-24点"), L("12–1 AM", "0-1点"), L("after 1 AM", "1点后")][min(idx, 3)]
    }

    private var waterText: String {
        guard let w = store.todayWater else { return L("not started", "未开始") }
        if w.provenance == .estimated { return L("auto \(w.totalMl)ml", "沿用 \(w.totalMl)ml") }
        return "\(w.totalMl)/\(w.goalMl) ml"
    }

    // B3：负面记录日也计入样本
    private var triggerStatusText: String {
        let distinctDays = Set(store.foodDays.map { Calendar.current.startOfDay(for: $0.day) }).count
        if store.flares.count >= 3 && distinctDays >= 30 {
            return L("Enough data — tap to see your top triggers", "已有足够数据，点开看你的 Top 诱因")
        }
        return L("\(max(0, 30 - distinctDays)) more days needed (30-day minimum) · \(distinctDays) logged", "还差 \(max(0, 30 - distinctDays)) 天数据（需 30 天记录）· 已记 \(distinctDays) 天")
    }

    private func trendRow(icon: String, color: Color, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).frame(width: 24)
            Text(title)
            Spacer()
            Text(value).font(.body.weight(.semibold)).foregroundColor(.secondary)
        }
    }

    /// 带图标的功能入口行（Pro 锁态复用同一套排版）
    private func linkRow(icon: String, title: String, subtitle: String, locked: Bool = false) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title).font(.body.weight(.medium))
                    if locked { ProTag() }
                }
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: locked ? "lock.fill" : icon)
                .foregroundColor(locked ? .secondary : .brand)
        }
    }

    // v11.1：热力格数据聚合（吃药/喝水/饮食/入睡四类按日计数→0-3 档）
    private var heatLevels: [Date: Int] {
        var levels: [Date: Int] = [:]
        func bump(_ d: Date) {
            let day = Calendar.current.startOfDay(for: d)
            levels[day, default: 0] += 1
        }
        for l in store.medLogs where l.taken { bump(l.date) }
        for w in store.waterDays where w.provenance == .recorded && !w.cups.isEmpty { bump(w.day) }
        for f in store.foodDays { bump(f.day) }
        for s in store.sleepLogs { bump(s.night) }
        return levels
    }

    private func heatLegend(_ level: Int, _ label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(level == 0 ? Color.cardBG : Color.brand.opacity(level == 3 ? 1.0 : (level == 2 ? 0.65 : 0.35)))
                .frame(width: 10, height: 10)
            Text(label)
        }
    }
}

// 尿酸趋势大图（A5）
struct UricTrendDetailView: View {
    @ObservedObject var store = Store.shared
    @EnvironmentObject private var pro: ProStore
    @State private var showPaywall = false

    /// 免费版看不到的旧读数条数（Pro 解锁）
    private var hiddenCount: Int {
        guard !pro.isPro else { return 0 }
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        return store.readings.filter { $0.date < cutoff }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if store.lastReading != nil {
                    HStack {
                        Text(store.meta.unitIsUmol
                             ? L("Latest \(String(format: "%.0f", store.lastReading!.urateUnit)) µmol/L", "最新 \(String(format: "%.0f", store.lastReading!.urateUnit)) µmol/L")
                             : L("Latest \(String(format: "%.1f", store.lastReading!.valueMgDl)) mg/dL", "最新 \(String(format: "%.1f", store.lastReading!.valueMgDl)) mg/dL"))
                            .font(.title3.bold())
                        Spacer()
                        Text(store.isAtTarget == true ? L("At target ✓", "达标 ✓") : L("Target <\(store.meta.unitIsUmol ? "360" : "6.0")", "目标 <\(store.meta.unitIsUmol ? "360" : "6.0")"))
                            .foregroundColor(store.isAtTarget == true ? .green : .amber)
                    }
                    UricTrendChart(limitDays: pro.isPro ? nil : 90)
                        .frame(height: 240)
                    Text(L("Dashed line = target. Gaps between points show your real testing rhythm — rechecks are already scheduled.", "虚线=达标线。连续点之间的间隔就是你的真实化验节奏——不用等 App 提醒，复查日已有排程。"))
                        .font(.caption).foregroundColor(.secondary)

                    if hiddenCount > 0 {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(Color.brand))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L("\(hiddenCount) earlier values are hidden", "还有 \(hiddenCount) 条更早的化验值未显示"))
                                        .font(.callout.weight(.medium))
                                        .foregroundColor(.primary)
                                    Text(L("Free shows 90 days. Pro shows every value you have ever logged.", "免费版显示 90 天。Pro 显示你记录过的全部。"))
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBG))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text(L("Trend chart appears after your first lab value", "记一次化验值后出现趋势图")).foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(L("Uric acid trends", "尿酸趋势"))
        .sheet(isPresented: $showPaywall) { ProPaywallView().environmentObject(pro) }
    }
}

// MARK: - 诱因排行（B3：负面记录纳入样本；规则级可解释）

struct TriggerRankView: View {
    @ObservedObject var store = Store.shared

    private var ranked: [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for flare in store.flares {
            let window = Calendar.current.date(byAdding: .hour, value: -72, to: flare.startDate)!
            let days = store.foodDays.filter { $0.day >= window && $0.day <= flare.startDate && !$0.noTriggerToday }
            for d in days {
                for item in d.items + d.scenes {
                    counts[item, default: 0] += 1
                }
            }
        }
        return counts.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
    }

    var body: some View {
        List {
            if ranked.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles").font(.largeTitle).foregroundColor(.secondary)
                    Text(L("Still building your personal data", "还在积累你的个人数据")).font(.body.weight(.medium))
                    Text(L("After 30 days of food logs + 3 flares, this shows what you commonly ate before flares — not a score, your own pattern. Clean days count too.", "记录 30 天饮食 + 3 次发作后，这里会告诉你「最近几次发作前你共同碰了什么」——不是评分，是你自己的规律。没碰高嘌呤的日子也算数据。"))
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                Section {
                    ForEach(Array(ranked.enumerated()), id: \.offset) { i, r in
                        HStack {
                            Text("\(i + 1).").font(.headline).foregroundColor(.brand)
                            Text(r.name)
                            Spacer()
                            Text(L("Appeared within 72h before \(r.count) flares", "\(r.count) 次发作前 72h 内出现过"))
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(L("Foods common before your last \(store.flares.count) flares", "你最近 \(store.flares.count) 次发作前的共同饮食"))
                } footer: {
                    Text(L("This is your own data, not generic advice. A personally relevant list beats any generic one (patient research).", "这是你自己的数据，不是通用建议。「对我相关的列表」比任何通用清单都有用（患者研究实证）。"))
                }
            }
        }
        .navigationTitle(L("Trigger ranking", "诱因排行"))
    }
}

// MARK: - 改变页（含入睡维度）

struct ChangeView: View {
    @ObservedObject var store = Store.shared

    private var recent90Flares: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        return store.flares.filter { $0.startDate >= cutoff }.count
    }
    private var prior90Flares: Int {
        let c1 = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        let c2 = Calendar.current.date(byAdding: .day, value: -180, to: Date())!
        return store.flares.filter { $0.startDate >= c2 && $0.startDate < c1 }.count
    }

    var body: some View {
        List {
            Section {
                Text(L("One less flare, one more day of freedom.", "少一次发作，多一份自由。"))
                    .font(.title3.bold())
            }
            Section(L("Your last 90 days", "你最近 90 天")) {
                changeRow(L("Flare count", "发作次数"), current: L("\(recent90Flares) flares", "\(recent90Flares) 次"), prior: prior90Flares > 0 ? L("Prior 90 days: \(prior90Flares) flares", "更早 90 天：\(prior90Flares) 次") : L("Appears once you start logging", "开始记录后出现"))
                changeRow(L("Pain-free days", "无痛天数"), current: store.flareFreeDays.map { L("\($0) days", "\($0) 天") } ?? "—", prior: L("Counting from your first logged flare", "记录第一次发作后开始计数"))
                if !store.weightLogs.isEmpty {
                    let first = store.weightLogs.min { $0.date < $1.date }?.kg ?? 0
                    let last = store.weightLogs.max { $0.date < $1.date }?.kg ?? 0
                    changeRow(L("Weight", "体重"), current: String(format: "%.1f kg", last), prior: String(format: L("At start: %.1f kg", "记录开始时：%.1f kg"), first))
                }
                if store.sleepLogs.count >= 4 {
                    let recent = store.sleepLogs.suffix(14)
                    let avg = Double(recent.map { $0.bucket }.reduce(0, +)) / Double(recent.count)
                    let idx = Int(avg.rounded())
                    changeRow(L("Sleep (last 14 days)", "入睡（近 14 天）"), current: [L("before 11 PM", "23点前"), L("11 PM–12 AM", "23-24点"), L("12–1 AM", "0-1点"), L("after 1 AM", "1点后")][min(idx, 3)], prior: L("\(store.sleepLogs.count) nights logged", "共 \(store.sleepLogs.count) 晚记录"))
                }
            }
            Section {
                HStack {
                    Text(L("\(store.meta.seedVotesTotal) votes for yourself", "你给自己投了 \(store.meta.seedVotesTotal) 票")).font(.body.weight(.semibold))
                    Spacer()
                    Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                }
                Text(L("Every same-day log is a vote for 'the person who takes care of himself'. Backfilled and auto-filled days don't count — votes should count.", "每一次实时记录都是给「照顾好自己的人」投的一票。补记和沿用不计数——因为投票要算数。"))
                    .font(.caption).foregroundColor(.secondary)
            }
            if let m = store.meta.motivation {
                Section {
                    Text(L("When your body is well, \(m == .other ? (store.meta.motivationCustomText ?? "everything gets easier.") : m.rawValue == "陪家人更久" ? "the days with family are steady." : m.rawValue == "不再被疼醒" ? "no more waking in pain." : "work stays on track.")", "身体好了，\(m == .other ? (store.meta.motivationCustomText ?? "一切才更从容。") : m.rawValue == "陪家人更久" ? "陪家人的日子才安稳。" : m.rawValue == "不再被疼醒" ? "才不用再被疼醒。" : "工作才有着落。")"))
                        .font(.callout).foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(L("Change", "改变"))
        
    }

    private func changeRow(_ label: String, current: String, prior: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label).font(.body)
                Spacer()
                Text(current).font(.body.weight(.semibold))
            }
            Text(prior).font(.caption).foregroundColor(.secondary)
        }
    }
}

// MARK: - 门诊记录生成 v11（A1：改名+档案头+生活方式第4节；诚实标记补记/沿用）

enum ClinicReportGenerator {
    enum ExportFormat: String, CaseIterable, Identifiable {
        case pdf = "PDF"
        case html = "HTML"
        case csv = "CSV"
        case txt = "TXT"
        var id: String { rawValue }
        /// 显示名（双语——rawValue只做存储/文件名，不直接显示）
        var displayName: String {
            switch self {
            case .pdf: return L("PDF (best for doctors · print)", "PDF（医生最佳·打印）")
            case .html: return L("HTML (opens in browser · keeps layout)", "HTML（浏览器打开·保排版）")
            case .csv: return L("CSV (for Excel analysis)", "CSV（Excel 分析）")
            case .txt: return L("TXT (plain text · universal)", "TXT（纯文本·通用）")
            }
        }
    }

    /// 健哥11-22令2：导出格式选择弹层（多种常用格式）
    static func generate(store: Store) {
        let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        guard let root = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        var top = root
        while let p = top.presentedViewController { top = p }
        let alert = UIAlertController(title: L("Export life record", "导出生活记录"), message: L("Pick a format", "选择格式"), preferredStyle: .actionSheet)
        for fmt in ExportFormat.allCases {
            alert.addAction(UIAlertAction(title: fmt.displayName, style: .default) { _ in
                export(store: store, format: fmt)
            })
        }
        alert.addAction(UIAlertAction(title: L("Cancel", "取消"), style: .cancel))
        top.present(alert, animated: true)
    }

    private static func export(store: Store, format: ExportFormat) {
        let readings = store.readings.sorted { $0.date < $1.date }
        let flares = store.flares.sorted { $0.startDate > $1.startDate }
        let tmp: URL
        switch format {
        case .pdf:
            // 2026-11-26 重做：原实现只调一次 ctx.beginPage()，把整份 HTML 转富文本
            // 硬画到一张 A4 上，超出页面的明细全部被裁掉（健哥实测"导出只有很少信息"）。
            // 改用 ClinicReportPDF：Core Graphics 手绘多页 + 尿酸折线/发作频次/饮水/入睡图
            // + 诱因排行 + 全部化验与发作明细。
            tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("UricNote_SelfRecord.pdf")
            try? ClinicReportPDF.make(store: store).write(to: tmp)
        case .html:
            let html = buildHTML(store: store, readings: readings, flares: flares)
            tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("UricNote_SelfRecord.html")
            try? Data(html.utf8).write(to: tmp)
        case .csv:
            tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("UricNote_SelfRecord.csv")
            try? buildCSV(store: store, readings: readings, flares: flares).write(to: tmp, atomically: true, encoding: .utf8)
        case .txt:
            tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("UricNote_SelfRecord.txt")
            try? buildTXT(store: store, readings: readings, flares: flares).write(to: tmp, atomically: true, encoding: .utf8)
        }
        DispatchQueue.main.async {
            let vc = UIActivityViewController(activityItems: [tmp], applicationActivities: nil)
            var top: UIViewController? = nil
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                top = root
                while let p = top?.presentedViewController { top = p }
            }
            top?.present(vc, animated: true)
        }
    }

    /// 健哥11-22令2/3/5：CSV 生成（全维度+双语表头——Excel 可直接分析）
    private static func buildCSV(store: Store, readings: [UricReading], flares: [Flare]) -> String {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let T = { (en: String, zh: String) -> String in L(en, zh) }
        var rows: [String] = []
        let esc = { (v: String) -> String in v.contains(",") ? "\"\(v)\"" : v }
        // ── 档案 ──
        rows.append("\(T("Field", "字段")),\(T("Value", "值"))")
        let p = store.profile
        if let a = p.age { rows.append("\(T("Age", "年龄")),\(a)") }
        if let g = p.gender { rows.append("\(T("Gender", "性别")),\(g)") }
        if let h = p.heightCm { rows.append("\(T("Height cm", "身高 cm")),\(Int(h))") }
        if let w = p.weightKg { rows.append("\(T("Weight kg", "体重 kg")),\(String(format: "%.1f", w))") }
        if !p.conditions.isEmpty { rows.append("\(T("Conditions", "共病")),\(esc(p.conditions.joined(separator: "; ")))") }
        if let d = p.drugAllergies, !d.isEmpty { rows.append("\(T("Drug allergy", "药物过敏")),\(esc(d))") }
        if let fam = p.familyGout { rows.append("\(T("Family gout history", "家族痛风史")),\(fam)") }
        // ── 化验 ──
        rows.append("")
        rows.append("\(T("LABS 日", "化验")),\(T("Date", "日期")),\(T("Urate", "尿酸")),\(T("Creatinine", "肌酐")),\(T("At target", "达标")),\(T("Source", "来源"))")
        for r in readings {
            let u = store.meta.unitIsUmol ? String(format: "%.0f umol/L", r.urateUnit) : String(format: "%.1f mg/dL", r.valueMgDl)
            let cr = r.creatinineMgDl.map { String(format: "%.1f", $0) } ?? ""
            rows.append("Lab,\(df.string(from: r.date)),\(u),\(cr),\(r.atTarget ? T("Yes","是") : T("No","否")),\(r.source == "home" ? T("Home","家测") : T("Lab","医院"))")
        }
        // ── 发作 ──
        rows.append("")
        rows.append("\(T("FLARES", "发作")),\(T("Date", "日期")),\(T("Joints", "部位")),\(T("Peak /10", "峰值/10")),\(T("Walking", "行走")),\(T("Painkiller", "止痛药")),\(T("Trigger note", "诱因备注"))")
        for f in flares {
            let pk = f.tookPainkiller.map { $0 ? T("Yes","是") : T("No","否") } ?? ""
            rows.append("Flare,\(df.string(from: f.startDate)),\(esc(f.joints.joined(separator: "; "))),\(f.painPeak),\(f.canWalk ? T("Yes","能走") : T("No","不能走")),\(pk),\(esc(f.triggerNotes ?? ""))")
        }
        // ── 用药 ──
        rows.append("")
        rows.append("\(T("MEDS", "用药")),\(T("Name", "名称")),\(T("Dose", "剂量")),\(T("Times/day", "次/日")),\(T("Since", "始于"))")
        for plan in store.medPlans where plan.active {
            rows.append("Med,\(esc(plan.name)),\(plan.dose),\(plan.timesPerDay),\(df.string(from: plan.startDate))")
        }
        // ── 每日生活方式 ──
        rows.append("")
        rows.append("\(T("DAILY", "每日")),\(T("Date", "日期")),\(T("Water ml", "饮水 ml")),\(T("Water mode", "饮水方式")),\(T("High-purine logged", "碰高嘌呤")),\(T("Sleep bucket", "入睡档")),\(T("Weight kg", "体重 kg"))")
        var daySet = Set<Date>()
        for d in store.waterDays { daySet.insert(Calendar.current.startOfDay(for: d.day)) }
        for d in store.foodDays { daySet.insert(Calendar.current.startOfDay(for: d.day)) }
        for d in store.sleepLogs { daySet.insert(Calendar.current.startOfDay(for: d.night)) }
        for d in store.weightLogs { daySet.insert(Calendar.current.startOfDay(for: d.date)) }
        let allDays = daySet.sorted()
        let cal = Calendar.current
        for day in allDays {
            let w = store.waterDays.first { cal.isDate($0.day, inSameDayAs: day) }
            let fd = store.foodDays.first { cal.isDate($0.day, inSameDayAs: day) }
            let slg = store.sleepLogs.first { cal.isDate($0.night, inSameDayAs: day) }
            let wl = store.weightLogs.first { cal.isDate($0.date, inSameDayAs: day) }
            let foodStr: String
            if let fd {
                if fd.noTriggerToday { foodStr = T("none logged", "未碰") }
                else { foodStr = esc((fd.scenes + fd.items).map(foodDisplayName).joined(separator: "; ")) }
            } else { foodStr = "" }
            rows.append("Daily,\(df.string(from: day)),\(w.map { String($0.totalMl) } ?? ""),\(w.map { $0.provenance == .estimated ? T("auto","沿用") : T("logged","实测") } ?? ""),\(foodStr),\(slg.map { ["<23","23-24","0-1",">1"][$0.bucket] } ?? ""),\(wl.map { String(format: "%.1f", $0.kg) } ?? "")")
        }
        return rows.joined(separator: "\n")
    }


    /// 健哥11-22令2/5：TXT 生成（纯文本通用·跟随语言）
    private static func buildTXT(store: Store, readings: [UricReading], flares: [Flare]) -> String {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let T = { (en: String, zh: String) -> String in L(en, zh) }
        var t = "===== \(T("UricNote Self-Recorded Log", "UricNote 自我记录")) =====\n"
        t += "\(T("Generated", "生成时间")): \(df.string(from: Date()))\n\n"
        t += "[\(T("PROFILE", "档案"))]\n"
        let p = store.profile
        if let a = p.age { t += "\(T("Age", "年龄")): \(a)\n" }
        if let g = p.gender { t += "\(T("Gender", "性别")): \(g)\n" }
        if !p.conditions.isEmpty { t += "\(T("Conditions", "共病")): \(p.conditions.joined(separator: ", "))\n" }
        t += "\n[LAB VALUES]\n"
        for r in readings {
            let u = store.meta.unitIsUmol ? String(format: "%.0f umol/L", r.urateUnit) : String(format: "%.1f mg/dL", r.valueMgDl)
            let cr = r.creatinineMgDl.map { String(format: ", creatinine %.1f", $0) } ?? ""
            t += "  \(df.string(from: r.date))  \(u)\(cr)  \(r.atTarget ? "(at target)" : "")\n"
        }
        t += "\n[FLARES] (newest first)\n"
        for f in flares {
            t += "  \(df.string(from: f.startDate))  peak \(f.painPeak)/10, \(f.canWalk ? "walkable" : "not walkable")\(f.triggerNotes.map { " — \($0)" } ?? "")\n"
        }
        if let plan = store.medPlans.first(where: { $0.active }) {
            t += "\n[CURRENT MED]\n  \(plan.name) \(plan.dose), \(plan.timesPerDay)x/day since \(df.string(from: plan.startDate))\n"
        }
        t += "\n===== A logging tool, not medical advice =====\n"
        return t
    }

    // MARK: HTML 图表（2026-11-26：原来 HTML 只有表没有图，趋势看不出来）

    /// 尿酸折线（内联 SVG——浏览器打开即见，不依赖任何外部资源）
    private static func svgUricChart(readings: [UricReading], unitIsUmol: Bool) -> String {
        guard readings.count >= 2 else { return "" }
        let w = 660.0, h = 150.0, padL = 36.0, padT = 10.0, padB = 20.0
        let vals = readings.map { unitIsUmol ? $0.urateUnit : $0.valueMgDl }
        let target = unitIsUmol ? 360.0 : 6.0
        let lo = min(vals.min() ?? 0, target) * 0.92
        let hi = max(vals.max() ?? 1, target) * 1.06
        let span = max(hi - lo, 0.001)
        let t0 = readings.first!.date.timeIntervalSince1970
        let t1 = readings.last!.date.timeIntervalSince1970
        let tSpan = max(t1 - t0, 1)
        let plotW = w - padL - 10
        let plotH = h - padT - padB

        func px(_ t: Double) -> Double { padL + (t - t0) / tSpan * plotW }
        func py(_ v: Double) -> Double { padT + (hi - v) / span * plotH }

        var poly: [String] = []
        var dots = ""
        for r in readings {
            let v = unitIsUmol ? r.urateUnit : r.valueMgDl
            let x = px(r.date.timeIntervalSince1970)
            let yv = py(v)
            poly.append(String(format: "%.1f,%.1f", x, yv))
            let c = v <= target ? "#389E63" : "#D2423D"
            dots += "<circle cx='\(String(format: "%.1f", x))' cy='\(String(format: "%.1f", yv))' r='2.6' fill='\(c)'/>"
        }

        var grid = ""
        for i in 0...3 {
            let gy = padT + plotH * Double(i) / 3
            let val = hi - span * Double(i) / 3
            grid += "<line x1='\(padL)' y1='\(String(format: "%.1f", gy))' x2='\(String(format: "%.1f", w - 10))' y2='\(String(format: "%.1f", gy))' stroke='#eeeeee' stroke-width='1'/>"
            grid += "<text x='\(padL - 5)' y='\(String(format: "%.1f", gy + 3))' font-size='8' fill='#888' text-anchor='end'>\(String(format: "%.0f", val))</text>"
        }

        let ty = String(format: "%.1f", py(target))
        let df = DateFormatter(); df.dateFormat = "M/d"
        let first = df.string(from: readings.first!.date)
        let last = df.string(from: readings.last!.date)

        return """
        <svg viewBox="0 0 \(Int(w)) \(Int(h))" width="100%" style="margin:8px 0">
        \(grid)
        <line x1='\(padL)' y1='\(ty)' x2='\(w - 10)' y2='\(ty)' stroke='#389E63' stroke-width='1' stroke-dasharray='4 3'/>
        <polyline points='\(poly.joined(separator: " "))' fill='none' stroke='#0E7C66' stroke-width='1.8'/>
        \(dots)
        <text x='\(padL)' y='\(h - 5)' font-size='8' fill='#888'>\(first)</text>
        <text x='\(w - 10)' y='\(h - 5)' font-size='8' fill='#888' text-anchor='end'>\(last)</text>
        </svg>
        """
    }

    /// 发作频次（近 12 个月，div 条形——打印也清楚）
    private static func htmlMonthlyFlares(flares: [Flare]) -> String {
        let cal = Calendar.current
        let now = Date()
        var bars: [(String, Int)] = []
        let f = DateFormatter(); f.dateFormat = L("MMM", "M月")
        for back in stride(from: 11, through: 0, by: -1) {
            guard let ms = cal.date(byAdding: .month, value: -back, to: cal.startOfDay(for: now)),
                  let range = cal.dateInterval(of: .month, for: ms) else { continue }
            bars.append((f.string(from: ms), flares.filter { $0.startDate >= range.start && $0.startDate < range.end }.count))
        }
        guard bars.contains(where: { $0.1 > 0 }) else { return "" }
        let maxC = max(bars.map { $0.1 }.max() ?? 1, 1)
        var cells = ""
        for (label, c) in bars {
            let hPct = Double(c) / Double(maxC) * 100
            let color = c == 0 ? "#e8e8e8" : "#D2423D"
            cells += """
            <div style="flex:1;text-align:center">
              <div style="height:64px;display:flex;align-items:flex-end;justify-content:center">
                <div style="width:60%;height:\(String(format: "%.0f", max(hPct, 3)))%;background:\(color);border-radius:2px"></div>
              </div>
              <div style="font-size:9px;color:#666;margin-top:3px">\(label)</div>
              <div style="font-size:10px;font-weight:600;color:#333">\(c)</div>
            </div>
            """
        }
        return "<div style='display:flex;gap:4px;margin:8px 0'>\(cells)</div>"
    }

    private static func buildHTML(store: Store, readings: [UricReading], flares: [Flare]) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        // A6/C11：档案头
        var profileHtml = ""
        if store.profile.hasContent {
            let p = store.profile
            var parts: [String] = []
            if let a = p.age { parts.append(L("Age \(a)", "年龄 \(a)岁")) }
            if let g = p.gender { parts.append(g) }
            if let h = p.heightCm, let w = p.weightKg { parts.append(L("Height \(Int(h))cm / Weight \(String(format: "%.1f", w))kg", "身高 \(Int(h))cm / 体重 \(String(format: "%.1f", w))kg")) }
            if let r = p.region, !r.isEmpty { parts.append(L("Region \(r)", "地区 \(r)")) }
            if !p.conditions.isEmpty { parts.append(L("Conditions: ", "共病 ") + p.conditions.joined(separator: "、")) }
            if let d = p.drugAllergies, !d.isEmpty { parts.append(L("Drug allergy \(d)", "药物过敏 \(d)")) }
            if let f = p.foodAllergies, !f.isEmpty { parts.append(L("Food allergy \(f)", "食物过敏 \(f)")) }
            if let fam = p.familyGout { parts.append(L("Family history \(fam)", "家族史 \(fam)")) }
            if let hla = p.hlaTested { parts.append("HLA-B*5801 \(hla)") }
            profileHtml = "<p><b>Patient profile:</b>" + parts.joined(separator: " · ") + "</p>"
        }

        var readingRows = ""
        for r in readings {
            let cr = r.creatinineMgDl.map { String(format: "%.1f", $0) } ?? "—"
            readingRows += "<tr><td>\(df.string(from: r.date))</td><td>\(String(format: "%.2f", r.valueMgDl))</td><td>\(cr)</td><td>\(r.atTarget ? "At target" : "Above goal")</td><td>\(r.source == "home" ? "Home" : "Lab")</td></tr>"
        }
        if readings.isEmpty { readingRows = "<tr><td colspan=5 class=na>Not recorded</td></tr>" }

        var flareRows = ""
        for f in flares {
            let med = f.tookMedsToday.map { $0 ? L("Took", "吃了") : L("Didn't take", "没吃") } ?? L("Not logged", "未记")
            let pk = f.tookPainkiller.map { L("Painkiller \($0 ? "✓" : "✗")", "止痛药\($0 ? "✓" : "✗")") } ?? ""
            flareRows += "<tr><td>\(df.string(from: f.startDate))</td><td>\(f.joints.joined(separator: "/"))</td><td>\(f.painPeak)/10</td><td>\(f.canWalk ? "Yes" : "No")</td><td>\(med) \(pk)</td></tr>"
        }
        if flares.isEmpty { flareRows = "<tr><td colspan=5 class=na>Not recorded</td></tr>" }

        // 诱因排行（与 TriggerRankView / PDF 报告同源逻辑：每次发作前 72h 的饮食项）
        var triggerCounts: [String: Int] = [:]
        for flare in flares {
            guard let win = Calendar.current.date(byAdding: .hour, value: -72, to: flare.startDate) else { continue }
            let days = store.foodDays.filter { $0.day >= win && $0.day <= flare.startDate && !$0.noTriggerToday }
            for d in days {
                for item in d.items + d.scenes {
                    triggerCounts[item, default: 0] += 1
                }
            }
        }
        let topTriggers = triggerCounts.sorted { $0.value > $1.value }.prefix(5)
        let triggerHtml: String
        if topTriggers.isEmpty {
            triggerHtml = "<p class=na>\(L("Not enough food + flare data yet — needs both kinds of entry.", "饮食与发作的配对数据还不够——两类记录都要有。"))</p>"
        } else {
            let tRows = topTriggers.map { (key, cnt) -> String in
                "<tr><td>\(foodDisplayName(key))</td><td>\(cnt)</td><td>\(L("in the 72h before that many flares", "在该次数发作前 72 小时内出现过"))</td></tr>"
            }.joined()
            triggerHtml = "<table><tr><th>\(L("Food", "食物"))</th><th>\(L("Count", "次数"))</th><th>\(L("Meaning", "含义"))</th></tr>\(tRows)</table>"
        }

        // A1 第4节：生活方式（饮水/饮食/入睡/体重）
        let recordedWater = store.waterDays.filter { $0.provenance == .recorded && !$0.cups.isEmpty }
        let estimatedWater = store.waterDays.filter { $0.provenance == .estimated }
        let onTargetDays = recordedWater.filter { $0.totalMl >= $0.goalMl }.count
        let redTouchDays = store.foodDays.filter { !$0.noTriggerToday && (!$0.items.isEmpty || !$0.scenes.isEmpty) }.count
        let noTriggerDays = store.foodDays.filter { $0.noTriggerToday }.count
        let weightLine: String
        if let first = store.weightLogs.min(by: { $0.date < $1.date }), let last = store.weightLogs.max(by: { $0.date < $1.date }) {
            weightLine = L("\(String(format: "%.1f", first.kg))kg → \(String(format: "%.1f", last.kg))kg (since \(df.string(from: first.date)))", "\(String(format: "%.1f", first.kg))kg → \(String(format: "%.1f", last.kg))kg（\(df.string(from: first.date)) 起）")
        } else { weightLine = L("Not recorded", "未记录") }
        let sleepLine: String
        if store.sleepLogs.count >= 4 {
            let recent = store.sleepLogs.suffix(14)
            let avg = Double(recent.map { $0.bucket }.reduce(0, +)) / Double(recent.count)
            sleepLine = [L("before 11 PM", "23点前"), L("11 PM–12 AM", "23-24点"), L("12–1 AM", "0-1点"), L("after 1 AM", "1点后")][min(Int(avg.rounded()), 3)] + L("(14-day avg, \(store.sleepLogs.count) nights)", "（近14天平均，共\(store.sleepLogs.count)晚记录）")
        } else { sleepLine = L("Not recorded", "未记录") }

        let adherence = store.adherenceRate.map { String(format: "%.0f%%", $0 * 100) } ?? L("Not recorded", "未记录")
        let activeMed = store.medPlans.first(where: { $0.active })
        let medLine = activeMed.map { L("\($0.name) \($0.dose) ×\($0.timesPerDay)/day", "\($0.name) \($0.dose) ×\($0.timesPerDay)/日") } ?? L("Not recorded", "未记录")

        // 健哥11-22令2/5：模板文字跟随语言（医生能看懂）
        let T = { (en: String, zh: String) -> String in L(en, zh) }
        return """
        <html><head><meta charset=utf-8><style>
        @page{margin:18mm}
        body{font-family:-apple-system,'Helvetica Neue','PingFang SC',sans-serif;margin:28px auto;max-width:720px;font-size:14.5px;color:#1a1a1a;line-height:1.6}
        .header{border-bottom:3px solid #0E7C66;padding-bottom:12px;margin-bottom:18px;display:flex;justify-content:space-between;align-items:flex-end}
        h1{font-size:24px;color:#0E7C66;margin:0}
        .sub{color:#666;font-size:12px;margin-top:4px}
        .meta{font-size:12px;color:#555;text-align:right}
        h2{font-size:16.5px;margin:20px 0 8px;color:#0E7C66;border-bottom:2px solid #0E7C66;padding-bottom:5px}
        h2::before{content:'▍';margin-right:4px}
        table{width:100%;border-collapse:collapse;font-size:13.5px;margin:6px 0}
        th{background:#0E7C66;color:#fff;padding:7px 10px;text-align:left;font-weight:600}
        tr:nth-child(even) td{background:#f6faf8}
        td{border-bottom:1px solid #ddd;padding:6px 10px}
        .na{color:#b0b0b0;font-style:italic;background:#fafafa}
        .kpi{display:flex;gap:8px;margin:10px 0}
        .kpi div{flex:1;background:#f2f8f5;border:1px solid #d5e5df;border-radius:8px;padding:8px 10px;text-align:center}
        .kpi b{display:block;font-size:17px;color:#0E7C66}
        .kpi span{font-size:10px;color:#666}
        .note{color:#777;font-size:10px;margin-top:18px;border-top:1px dashed #ccc;padding-top:8px}
        .tag{display:inline-block;background:#e8f4f0;color:#0E7C66;border-radius:4px;padding:1px 6px;font-size:10px;margin-left:4px}
        </style></head><body>
        <div class=header>
          <div><h1>\(T("UricNote Self-Recorded Log", "UricNote 自我记录"))</h1><div class=sub>\(T("Self-recorded daily log — share with your doctor or review yourself (not a medical report)", "自我记录的日常生活档案——就诊时给医生参考，或自己回顾（非医疗报告）"))</div></div>
          <div class=meta>\(T("Generated", "生成时间")) \(df.string(from: Date()))<br>UricNote App</div>
        </div>
        \(profileHtml)
        <div class=kpi>
          <div><b>\(store.flareFreeDays.map { String($0) } ?? "—")</b><span>\(T("Flare-free days", "无痛天数"))</span></div>
          <div><b>\(adherence)</b><span>\(T("Adherence (30d)", "服药依从率 (30d)"))</span></div>
          <div><b>\(store.lastReading.map { String(format: "%.1f", $0.valueMgDl) } ?? "—")</b><span>\(T("Latest urate mg/dL", "最近尿酸 mg/dL"))</span></div>
        </div>
        \(svgUricChart(readings: readings, unitIsUmol: store.meta.unitIsUmol))
        <h2>1. \(T("Uric Acid Labs (incl. creatinine)", "尿酸化验（含肌酐）")) <span class=tag>\(T("Target &lt;6.0 mg/dL / 360 µmol/L", "目标 &lt;6.0 mg/dL / 360 µmol/L"))</span></h2>
        <table><tr><th>\(T("Date", "日期"))</th><th>\(T("Urate mg/dL", "尿酸 mg/dL"))</th><th>\(T("Creatinine", "肌酐"))</th><th>\(T("Status", "判定"))</th><th>\(T("Source", "来源"))</th></tr>\(readingRows)</table>
        <h2>2. \(T("Flare history (all episodes)", "发作史（全部记录）"))</h2>
        \(htmlMonthlyFlares(flares: flares))
        <table><tr><th>\(T("Date", "日期"))</th><th>\(T("Joints", "部位"))</th><th>\(T("Peak", "疼痛峰值"))</th><th>\(T("Walking", "行走"))</th><th>\(T("Meds", "用药"))</th></tr>\(flareRows)</table>
        <h2>3. \(T("Foods common before flares", "发作前共同出现的饮食"))</h2>
        \(triggerHtml)
        <h2>4. \(T("Medication & Adherence", "用药与依从性"))</h2>
        <p>\(T("Current medication", "当前用药"))：<b>\(medLine)</b><br>
        \(T("30-day adherence", "近 30 天依从率"))：<b>\(adherence)</b><span class=tag>\(T("backfills marked", "补记已标注"))</span></p>
        <h2>5. \(T("Lifestyle (daily log summary)", "生活方式（日常记录汇总）"))</h2>
        <p>
        \(T("Hydration", "饮水"))：\(T("on-goal \(onTargetDays) d / auto-avg \(estimatedWater.count) d", "达标 \(onTargetDays) 天 / 沿用均值 \(estimatedWater.count) 天"))<span class=tag>\(T("auto=weekly average, not measured", "沿用=按上周平均自动填，非实测"))</span><br>
        \(T("Diet", "饮食"))：\(T("high-purine logged \(redTouchDays) d · clean \(noTriggerDays) d", "登记高嘌呤 \(redTouchDays) 天 · 明确未碰 \(noTriggerDays) 天"))<br>
        \(T("Sleep", "入睡"))：\(sleepLine)<br>
        \(T("Weight", "体重"))：\(weightLine)
        </p>
        <h2>6. \(T("Details (last 30 days)", "细节（近 30 天）"))</h2>
        <table><tr><th>\(T("Metric", "指标"))</th><th>\(T("Value", "数值"))</th><th>\(T("Note", "说明"))</th></tr>
        <tr><td>\(T("Flares", "发作次数"))</td><td>\(store.flares.filter { $0.startDate >= Calendar.current.date(byAdding: .day, value: -30, to: Date())! }.count)</td><td>\(T("worst pain \(store.flares.filter { $0.startDate >= Calendar.current.date(byAdding: .day, value: -30, to: Date())! }.map(\.painPeak).max() ?? 0)/10", "最痛 \(store.flares.filter { $0.startDate >= Calendar.current.date(byAdding: .day, value: -30, to: Date())! }.map(\.painPeak).max() ?? 0)/10"))</td></tr>
        <tr><td>\(T("Water on-goal rate", "饮水达标率"))</td><td>\(Int(Double(onTargetDays) / Double(max(recordedWater.count, 1)) * 100))%</td><td>\(T("\(onTargetDays)/\(recordedWater.count) recorded days", "实测 \(recordedWater.count) 天中达标 \(onTargetDays) 天"))</td></tr>
        <tr><td>\(T("Body rhythm", "身体节律"))</td><td>\(store.sexualLogs.filter { $0.date >= Calendar.current.date(byAdding: .day, value: -30, to: Date())! }.count)</td><td>\(T("known trigger factor", "已知诱因之一"))</td></tr>
        <tr><td>\(T("Meds taken days", "服药天数"))</td><td>\(Set(store.medLogs.filter { $0.taken && Calendar.current.isDateInToday($0.date) == false && $0.date >= Calendar.current.date(byAdding: .day, value: -30, to: Date())! }.map { Calendar.current.startOfDay(for: $0.date) }).count)</td><td>\(T("urate-lowering only; painkillers counted separately", "仅降酸药；止痛药另计"))</td></tr>
        </table>
        <p class=note>\(T("Generated by UricNote. All data is patient self-reported (not medical-device measurements). 'Not recorded' = no entry that period, not a normal result; 'backfill' = patient confirmed later; 'auto' = filled from the patient's prior-week average. Refs: ACR 2020 Guideline · Treat-to-target (GoutSMART, Lancet Rheum 2022) · NHHC 2024.", "本记录由 UricNote App 生成，全部数据为患者日常自记录（非医疗设备测量）。「未记录」=该时段无录入，不代表指标正常；「补记」=患者事后确认；「沿用」=按患者此前一周均值自动填。参考：ACR 2020 指南 · Treat-to-target（GoutSMART, Lancet Rheumatology 2022）· 卫健委2024食养指南。"))</p>
        </body></html>
        """
    }
}
