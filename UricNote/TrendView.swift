import SwiftUI
import Charts

// MARK: - Tab3 趋势 v11（A6 档案置顶 / 趋势图 / 诱因排行含负面记录 / 改变页 / 门诊记录 A1）

struct TrendView: View {
    @ObservedObject var store = Store.shared

    var body: some View {
        NavigationView {
            List {
                // A6：健康档案置顶一行（填了才显示）
                if store.profile.isComplete {
                    Section {
                        NavigationLink { HealthProfileEditor() } label: {
                            HStack {
                                Image(systemName: "person.text.rectangle").foregroundColor(.brand)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profileLine).font(.callout)
                                    Text(L("Health profile (tap to edit)", "健康档案（点击修改）")).font(.caption2).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                Section(L("Three trend lines (real, measurable numbers)", "三线趋势（真实可算指标）")) {
                    trendRow(icon: "pills.fill", color: .brand, title: L("Med adherence (30 days)", "服药依从率（30 天）"), value: adherenceText)
                    trendRow(icon: "sun.max", color: .warn, title: L("Pain-free days", "无痛天数"), value: store.flareFreeDays.map { L("\($0) days", "\($0) 天") } ?? "—")
                    trendRow(icon: "moon.fill", color: .brand, title: L("Sleep (14-day avg)", "近 14 天入睡（平均）"), value: sleepAvgText)
                    trendRow(icon: "drop.fill", color: .water, title: L("Water today", "今天喝水"), value: waterText)
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
                    NavigationLink { UricTrendDetailView() } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("Uric acid trend chart", "尿酸趋势图")).font(.body.weight(.medium))
                                Text(L("Lab values with target line", "化验值折线+目标线")).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(.brand)
                        }
                    }
                    NavigationLink { TriggerRankView() } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("Trigger ranking", "诱因排行")).font(.body.weight(.medium))
                                Text(triggerStatusText).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "sparkles").foregroundColor(.brand)
                        }
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
                        // 健哥11-21令：门诊记录放开——前期免费获真实用户反馈（原Pro锁移除）
                        ClinicReportGenerator.generate(store: store)
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.viewfinder")
                            VStack(alignment: .leading, spacing: 2) {
                                // A1：门诊记录（不是医生报告——发给医生的日常记录）
                                Text(L("Clinic report", "门诊记录")).font(.body.weight(.medium))
                                Text(L("One A4 page: profile + trends + flare history + meds + lifestyle", "一页 A4：档案+趋势+发作史+用药+生活方式")).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "lock.open")
                        }
                    }
                } footer: {
                    Text(L("Your doctor has 15 minutes — this page is enough. Missing data is marked honestly, never faked.", "医生只有 15 分钟——这一页足够。缺失数据标「未记录」，沿用日标「沿用」，绝不冒充实测。"))
                }
            }
            .navigationTitle(L("Trends", "趋势"))
        }
    }

    private var profileLine: String {
        var parts: [String] = []
        if let a = store.profile.age { parts.append(L("\(a) y/o", "\(a)岁")) }
        if let g = store.profile.gender { parts.append(g) }
        if !store.profile.conditions.isEmpty { parts.append(L("Conditions: ", "共病：") + store.profile.conditions.joined(separator: "、")) }
        return parts.isEmpty ? L("Health profile", "健康档案") : parts.joined(separator: " · ")
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
                    UricTrendChart()
                        .frame(height: 240)
                    Text(L("Dashed line = target. Gaps between points show your real testing rhythm — rechecks are already scheduled.", "虚线=达标线。连续点之间的间隔就是你的真实化验节奏——不用等 App 提醒，复查日已有排程。"))
                        .font(.caption).foregroundColor(.secondary)
                } else {
                    Text(L("Trend chart appears after your first lab value", "记一次化验值后出现趋势图")).foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(L("Uric acid trends", "尿酸趋势"))
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
        .toolbar { NavigationLink(L("Log weight", "记体重")) { WeightEditor() } }
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
        let alert = UIAlertController(title: L("Export clinic report", "导出门诊记录"), message: L("Pick a format", "选择格式"), preferredStyle: .actionSheet)
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
        case .pdf, .html:
            let html = buildHTML(store: store, readings: readings, flares: flares)
            let name = format == .pdf ? "UricNote_Clinic.pdf" : "UricNote_Clinic.html"
            tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
            let data = format == .pdf ? (html as NSString).data(using: String.Encoding.utf8.rawValue)! : Data(html.utf8)
            try? data.write(to: tmp)
        case .csv:
            tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("UricNote_Clinic.csv")
            try? buildCSV(store: store, readings: readings, flares: flares).write(to: tmp, atomically: true, encoding: .utf8)
        case .txt:
            tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("UricNote_Clinic.txt")
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

    /// 健哥11-22令2：CSV 生成（Excel 可直接分析）
    private static func buildCSV(store: Store, readings: [UricReading], flares: [Flare]) -> String {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        var rows: [String] = []
        rows.append("Section,Date,Value1,Value2,Note")
        for r in readings {
            let u = store.meta.unitIsUmol ? String(format: "%.0f umol/L", r.urateUnit) : String(format: "%.1f mg/dL", r.valueMgDl)
            let cr = r.creatinineMgDl.map { String(format: "%.1f mg/dL", $0) } ?? ""
            rows.append("Lab,\(df.string(from: r.date)),\(u),\(cr),\(r.source == "home" ? "home" : "lab")")
        }
        for f in flares {
            let pk = f.tookPainkiller.map { $0 ? "painkiller" : "" } ?? ""
            rows.append("Flare,\(df.string(from: f.startDate)),peak \(f.painPeak)/10,\(f.canWalk ? "walkable" : "not walkable"),\(pk)\(f.triggerNotes.map { ";" + $0 } ?? "")")
        }
        if let plan = store.medPlans.first(where: { $0.active }) {
            rows.append("Med,since \(df.string(from: plan.startDate)),\(plan.name) \(plan.dose),\(plan.timesPerDay)x/day,")
        }
        return rows.joined(separator: "\n")
    }

    /// 健哥11-22令2：TXT 生成（纯文本通用）
    private static func buildTXT(store: Store, readings: [UricReading], flares: [Flare]) -> String {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        var t = "===== UricNote Clinic Report =====\n"
        t += "Generated: \(df.string(from: Date()))\n\n"
        t += "[PROFILE]\n"
        let p = store.profile
        if let a = p.age { t += "Age: \(a)\n" }
        if let g = p.gender { t += "Gender: \(g)\n" }
        if !p.conditions.isEmpty { t += "Conditions: \(p.conditions.joined(separator: ", "))\n" }
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

    private static func buildHTML(store: Store, readings: [UricReading], flares: [Flare]) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        // A6/C11：档案头
        var profileHtml = ""
        if store.profile.isComplete {
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
        for f in flares.prefix(10) {
            let med = f.tookMedsToday.map { $0 ? L("Took", "吃了") : L("Didn't take", "没吃") } ?? L("Not logged", "未记")
            let pk = f.tookPainkiller.map { L("Painkiller \($0 ? "✓" : "✗")", "止痛药\($0 ? "✓" : "✗")") } ?? ""
            flareRows += "<tr><td>\(df.string(from: f.startDate))</td><td>\(f.joints.joined(separator: "/"))</td><td>\(f.painPeak)/10</td><td>\(f.canWalk ? "Yes" : "No")</td><td>\(med) \(pk)</td></tr>"
        }
        if flares.isEmpty { flareRows = "<tr><td colspan=5 class=na>Not recorded</td></tr>" }

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

        return """
        <html><head><meta charset=utf-8><style>
        @page{margin:18mm}
        body{font-family:-apple-system,'Helvetica Neue',sans-serif;margin:28px auto;max-width:720px;font-size:14.5px;color:#1a1a1a;line-height:1.6}
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
          <div><h1>UricNote 门诊记录</h1><div class=sub>患者日常自记录整理 · 供门诊参考（非医疗报告）</div></div>
          <div class=meta>生成时间 \(df.string(from: Date()))<br>UricNote App</div>
        </div>
        \(profileHtml)
        <div class=kpi>
          <div><b>\(store.flareFreeDays.map { String($0) } ?? "—")</b><span>无痛天数 Flare-free days</span></div>
          <div><b>\(adherence)</b><span>服药依从率 (30d) Adherence</span></div>
          <div><b>\(store.lastReading.map { String(format: "%.1f", $0.valueMgDl) } ?? "—")</b><span>最近尿酸 mg/dL Latest urate</span></div>
        </div>
        <h2>1. 尿酸化验（含肌酐） <span class=tag>目标 Target &lt;6.0 mg/dL / 360 µmol/L</span></h2>
        <table><tr><th>日期 Date</th><th>尿酸 mg/dL</th><th>肌酐 Creatinine</th><th>判定 Status</th><th>来源 Source</th></tr>\(readingRows)</table>
        <h2>2. 发作史 Flare History（最近 10 次）</h2>
        <table><tr><th>日期 Date</th><th>部位 Joints</th><th>疼痛峰值 Peak</th><th>行走 Walking</th><th>用药 Meds</th></tr>\(flareRows)</table>
        <h2>3. 用药与依从性 Medication & Adherence</h2>
        <p>当前用药 Current medication：<b>\(medLine)</b><br>
        近 30 天依从率 30-day adherence：<b>\(adherence)</b><span class=tag>补记已标注 backfills marked</span></p>
        <h2>4. 生活方式 Lifestyle（日常记录汇总）</h2>
        <p>
        饮水 Hydration：达标 \(onTargetDays) 天 / 沿用均值 \(estimatedWater.count) 天<span class=tag>沿用=按上周平均自动填，非实测</span><br>
        饮食 Diet：登记高嘌呤 \(redTouchDays) 天 · 明确未碰 \(noTriggerDays) 天（负面记录也是数据）<br>
        入睡 Sleep：\(sleepLine)<br>
        体重 Weight：\(weightLine)
        </p>
        <p class=note>本记录由 UricNote App 生成，全部数据为患者日常自记录（非医疗设备测量）。「未记录/No data」=该时段无录入，不代表指标正常；「补记」=患者事后确认；「沿用」=按患者此前一周均值自动填。 Generated by UricNote — self-reported daily log for clinic reference. 参考：ACR 2020 Guideline · Treat-to-target rhythm（GoutSMART, Lancet Rheumatology 2022）· 卫健委2024食养指南。</p>
        </body></html>
        """
    }
}
