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
                                    Text("健康档案（点击修改）").font(.caption2).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                Section("三线趋势（真实可算指标）") {
                    trendRow(icon: "pills.fill", color: .brand, title: "服药依从率（30 天）", value: adherenceText)
                    trendRow(icon: "sun.max", color: .warn, title: "无痛天数", value: store.flareFreeDays.map { "\($0) 天" } ?? "—")
                    trendRow(icon: "moon.fill", color: .brand, title: "近 14 天入睡（平均）", value: sleepAvgText)
                    trendRow(icon: "drop.fill", color: .water, title: "今天喝水", value: waterText)
                }
                // v11.1：坚持热力格（HabitKit 式——长期管理病的坚持度可视化）
                Section {
                    HeatGrid(levels: heatLevels)
                    HStack(spacing: 12) {
                        heatLegend(0, "未记录")
                        heatLegend(1, "记 1 类")
                        heatLegend(2, "记 2 类")
                        heatLegend(3, "记满 3 类")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                } header: {
                    Text("记录坚持（近 90 天）")
                } footer: {
                    Text("三类=吃药打卡/喝水/饮食（入睡也算）。格子只给坚持可视化——不评判漏掉的格子。")
                }
                Section {
                    NavigationLink { UricTrendDetailView() } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("尿酸趋势图").font(.body.weight(.medium))
                                Text("化验值折线+目标线").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(.brand)
                        }
                    }
                    NavigationLink { TriggerRankView() } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("诱因排行").font(.body.weight(.medium))
                                Text(triggerStatusText).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "sparkles").foregroundColor(.brand)
                        }
                    }
                    NavigationLink { ChangeView() } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("「改变」页").font(.body.weight(.medium))
                                Text("90 天 vs 更早——身体给你的答案").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right").foregroundColor(.brand)
                        }
                    }
                } header: {
                    Text("它越来越懂你")
                }
                Section {
                    Button {
                        if store.meta.proUnlocked {
                            ClinicReportGenerator.generate(store: store)
                        } else {
                            UricCelebrate.show("门诊记录是 Pro 功能——一次买断，无订阅。")
                        }
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.viewfinder")
                            VStack(alignment: .leading, spacing: 2) {
                                // A1：门诊记录（不是医生报告——发给医生的日常记录）
                                Text("门诊记录").font(.body.weight(.medium))
                                Text("一页 A4：档案+趋势+发作史+用药+生活方式").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: store.meta.proUnlocked ? "lock.open" : "lock")
                        }
                    }
                } footer: {
                    Text("医生只有 15 分钟——这一页足够。缺失数据标「未记录」，沿用日标「沿用」，绝不冒充实测。")
                }
            }
            .navigationTitle("趋势")
        }
    }

    private var profileLine: String {
        var parts: [String] = []
        if let a = store.profile.age { parts.append("\(a)岁") }
        if let g = store.profile.gender { parts.append(g) }
        if !store.profile.conditions.isEmpty { parts.append("共病：" + store.profile.conditions.joined(separator: "、")) }
        return parts.isEmpty ? "健康档案" : parts.joined(separator: " · ")
    }

    private var adherenceText: String {
        guard let r = store.adherenceRate else { return "开始记录后出现" }
        return String(format: "%.0f%%", r * 100)
    }

    private var sleepAvgText: String {
        let recent = store.sleepLogs.suffix(14)
        guard !recent.isEmpty else { return "—" }
        let avg = Double(recent.map { $0.bucket }.reduce(0, +)) / Double(recent.count)
        let idx = Int(avg.rounded())
        return ["23点前", "23-24点", "0-1点", "1点后"][min(idx, 3)]
    }

    private var waterText: String {
        guard let w = store.todayWater else { return "未开始" }
        if w.provenance == .estimated { return "沿用 \(w.totalMl)ml" }
        return "\(w.totalMl)/\(w.goalMl) ml"
    }

    // B3：负面记录日也计入样本
    private var triggerStatusText: String {
        let distinctDays = Set(store.foodDays.map { Calendar.current.startOfDay(for: $0.day) }).count
        if store.flares.count >= 3 && distinctDays >= 30 {
            return "已有足够数据，点开看你的 Top 诱因"
        }
        return "还差 \(max(0, 30 - distinctDays)) 天数据（需 30 天记录）· 已记 \(distinctDays) 天"
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
                             ? "最新 \(String(format: "%.0f", store.lastReading!.urateUnit)) µmol/L"
                             : "最新 \(String(format: "%.1f", store.lastReading!.valueMgDl)) mg/dL")
                            .font(.title3.bold())
                        Spacer()
                        Text(store.isAtTarget == true ? "达标 ✓" : "目标 <\(store.meta.unitIsUmol ? "360" : "6.0")")
                            .foregroundColor(store.isAtTarget == true ? .green : .amber)
                    }
                    UricTrendChart()
                        .frame(height: 240)
                    Text("虚线=达标线。连续点之间的间隔就是你的真实化验节奏——不用等 App 提醒，复查日已有排程。")
                        .font(.caption).foregroundColor(.secondary)
                } else {
                    Text("记一次化验值后出现趋势图").foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("尿酸趋势")
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
                    Text("还在积累你的个人数据").font(.body.weight(.medium))
                    Text("记录 30 天饮食 + 3 次发作后，这里会告诉你「最近几次发作前你共同碰了什么」——不是评分，是你自己的规律。没碰高嘌呤的日子也算数据。")
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
                            Text("\(r.count) 次发作前 72h 内出现过")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("你最近 \(store.flares.count) 次发作前的共同饮食")
                } footer: {
                    Text("这是你自己的数据，不是通用建议。「对我相关的列表」比任何通用清单都有用（患者研究实证）。")
                }
            }
        }
        .navigationTitle("诱因排行")
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
                Text("少一次发作，多一份自由。")
                    .font(.title3.bold())
            }
            Section("你最近 90 天") {
                changeRow("发作次数", current: "\(recent90Flares) 次", prior: prior90Flares > 0 ? "更早 90 天：\(prior90Flares) 次" : "开始记录后出现")
                changeRow("无痛天数", current: store.flareFreeDays.map { "\($0) 天" } ?? "—", prior: "记录第一次发作后开始计数")
                if !store.weightLogs.isEmpty {
                    let first = store.weightLogs.min { $0.date < $1.date }?.kg ?? 0
                    let last = store.weightLogs.max { $0.date < $1.date }?.kg ?? 0
                    changeRow("体重", current: String(format: "%.1f kg", last), prior: String(format: "记录开始时：%.1f kg", first))
                }
                if store.sleepLogs.count >= 4 {
                    let recent = store.sleepLogs.suffix(14)
                    let avg = Double(recent.map { $0.bucket }.reduce(0, +)) / Double(recent.count)
                    let idx = Int(avg.rounded())
                    changeRow("入睡（近 14 天）", current: ["23点前", "23-24点", "0-1点", "1点后"][min(idx, 3)], prior: "共 \(store.sleepLogs.count) 晚记录")
                }
            }
            Section {
                HStack {
                    Text("你给自己投了 \(store.meta.seedVotesTotal) 票").font(.body.weight(.semibold))
                    Spacer()
                    Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                }
                Text("每一次实时记录都是给「照顾好自己的人」投的一票。补记和沿用不计数——因为投票要算数。")
                    .font(.caption).foregroundColor(.secondary)
            }
            if let m = store.meta.motivation {
                Section {
                    Text("身体好了，\(m.rawValue == "陪家人更久" ? "陪家人的日子才安稳。" : m.rawValue == "不再被疼醒" ? "才不用再被疼醒。" : "工作才有着落。")")
                        .font(.callout).foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("改变")
        .toolbar { NavigationLink("记体重") { WeightEditor() } }
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
    static func generate(store: Store) {
        let readings = store.readings.sorted { $0.date < $1.date }
        let flares = store.flares.sorted { $0.startDate > $1.startDate }
        let html = buildHTML(store: store, readings: readings, flares: flares)
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("UricNote_Clinic.html")
        try? html.write(to: tmp, atomically: true, encoding: .utf8)
        let vc = UIActivityViewController(activityItems: [tmp], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        var top = root
        while let p = top.presentedViewController { top = p }
        top.present(vc, animated: true)
    }

    private static func buildHTML(store: Store, readings: [UricReading], flares: [Flare]) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        // A6/C11：档案头
        var profileHtml = ""
        if store.profile.isComplete {
            let p = store.profile
            var parts: [String] = []
            if let a = p.age { parts.append("年龄 \(a)岁") }
            if let g = p.gender { parts.append(g) }
            if let h = p.heightCm, let w = p.weightKg { parts.append("身高 \(Int(h))cm / 体重 \(String(format: "%.1f", w))kg") }
            if let r = p.region, !r.isEmpty { parts.append("地区 \(r)") }
            if !p.conditions.isEmpty { parts.append("共病 " + p.conditions.joined(separator: "、")) }
            if let d = p.drugAllergies, !d.isEmpty { parts.append("药物过敏 \(d)") }
            if let f = p.foodAllergies, !f.isEmpty { parts.append("食物过敏 \(f)") }
            if let fam = p.familyGout { parts.append("家族史 \(fam)") }
            if let hla = p.hlaTested { parts.append("HLA-B*5801 \(hla)") }
            profileHtml = "<p><b>患者档案：</b>" + parts.joined(separator: " · ") + "</p>"
        }

        var readingRows = ""
        for r in readings {
            let cr = r.creatinineMgDl.map { String(format: "%.1f", $0) } ?? "—"
            readingRows += "<tr><td>\(df.string(from: r.date))</td><td>\(String(format: "%.2f", r.valueMgDl))</td><td>\(cr)</td><td>\(r.atTarget ? "At target" : "Above goal")</td><td>\(r.source == "home" ? "Home" : "Lab")</td></tr>"
        }
        if readings.isEmpty { readingRows = "<tr><td colspan=5 class=na>未记录 No data</td></tr>" }

        var flareRows = ""
        for f in flares.prefix(10) {
            let med = f.tookMedsToday.map { $0 ? "吃了" : "没吃" } ?? "未记"
            let pk = f.tookPainkiller.map { "止痛药\($0 ? "✓" : "✗")" } ?? ""
            flareRows += "<tr><td>\(df.string(from: f.startDate))</td><td>\(f.joints.joined(separator: "/"))</td><td>\(f.painPeak)/10</td><td>\(f.canWalk ? "Yes" : "No")</td><td>\(med) \(pk)</td></tr>"
        }
        if flares.isEmpty { flareRows = "<tr><td colspan=5 class=na>未记录 No data</td></tr>" }

        // A1 第4节：生活方式（饮水/饮食/入睡/体重）
        let recordedWater = store.waterDays.filter { $0.provenance == .recorded && !$0.cups.isEmpty }
        let estimatedWater = store.waterDays.filter { $0.provenance == .estimated }
        let onTargetDays = recordedWater.filter { $0.totalMl >= $0.goalMl }.count
        let redTouchDays = store.foodDays.filter { !$0.noTriggerToday && (!$0.items.isEmpty || !$0.scenes.isEmpty) }.count
        let noTriggerDays = store.foodDays.filter { $0.noTriggerToday }.count
        let weightLine: String
        if let first = store.weightLogs.min(by: { $0.date < $1.date }), let last = store.weightLogs.max(by: { $0.date < $1.date }) {
            weightLine = "\(String(format: "%.1f", first.kg))kg → \(String(format: "%.1f", last.kg))kg（\(df.string(from: first.date)) 起）"
        } else { weightLine = "未记录" }
        let sleepLine: String
        if store.sleepLogs.count >= 4 {
            let recent = store.sleepLogs.suffix(14)
            let avg = Double(recent.map { $0.bucket }.reduce(0, +)) / Double(recent.count)
            sleepLine = ["23点前", "23-24点", "0-1点", "1点后"][min(Int(avg.rounded()), 3)] + "（近14天平均，共\(store.sleepLogs.count)晚记录）"
        } else { sleepLine = "未记录" }

        let adherence = store.adherenceRate.map { String(format: "%.0f%%", $0 * 100) } ?? "未记录"
        let activeMed = store.medPlans.first(where: { $0.active })
        let medLine = activeMed.map { "\($0.name) \($0.dose) ×\($0.timesPerDay)/日" } ?? "未记录"

        return """
        <html><head><meta charset=utf-8><style>
        @page{margin:18mm}
        body{font-family:-apple-system,'Helvetica Neue',sans-serif;margin:24px;font-size:13px;color:#1a1a1a;line-height:1.45}
        .header{border-bottom:3px solid #0E7C66;padding-bottom:10px;margin-bottom:14px;display:flex;justify-content:space-between;align-items:flex-end}
        h1{font-size:21px;color:#0E7C66;margin:0}
        .sub{color:#666;font-size:11px}
        .meta{font-size:11px;color:#555;text-align:right}
        h2{font-size:14px;margin:16px 0 6px;color:#0E7C66;border-bottom:1px solid #d5e5df;padding-bottom:4px}
        table{width:100%;border-collapse:collapse;font-size:12px}
        th{background:#e8f4f0;padding:6px 8px;text-align:left;font-weight:600}
        td{border-bottom:1px solid #eee;padding:5px 8px}
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
