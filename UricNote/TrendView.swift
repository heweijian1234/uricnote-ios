import SwiftUI

// MARK: - Tab3 趋势（三线图+诱因排行倒计时+改变页+医生报告 Pro）

struct TrendView: View {
    @ObservedObject var store = Store.shared

    var body: some View {
        NavigationView {
            List {
                Section("三线趋势（真实可算指标）") {
                    trendRow(icon: "pills.fill", color: .blue, title: "服药依从率（30 天）", value: adherenceText)
                    trendRow(icon: "sun.max", color: .orange, title: "无痛天数", value: "\(store.flareFreeDays) 天")
                    trendRow(icon: "drop.fill", color: .cyan, title: "今天喝水达标", value: waterText)
                }

                Section {
                    NavigationLink {
                        TriggerRankView()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("诱因排行").font(.body.weight(.medium))
                                Text(triggerStatusText).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "sparkles").foregroundColor(.accentColor)
                        }
                    }
                } header: {
                    Text("它越来越懂你")
                }

                Section {
                    NavigationLink {
                        ChangeView()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("「改变」页").font(.body.weight(.medium))
                                Text("90 天 vs 更早——身体给你的答案").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right").foregroundColor(.accentColor)
                        }
                    }
                }

                Section {
                    Button {
                        // Pro 门（v1：meta.proUnlocked；发布版接 IAP）
                        if store.meta.proUnlocked {
                            ReportGenerator.generate(store: store)
                        } else {
                            UricCelebrate.show("医生报告是 Pro 功能——一次买断，无订阅。")
                        }
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.viewfinder")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("生成医生报告").font(.body.weight(.medium))
                                Text("一页 A4：趋势+发作史+依从率+用药清单").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: store.meta.proUnlocked ? "lock.open" : "lock")
                        }
                    }
                } footer: {
                    Text("医生只有 15 分钟——这一页足够。缺失数据会标「未记录」，绝不冒充实测。")
                }
            }
            .navigationTitle("趋势")
        }
    }

    private var adherenceText: String {
        guard let r = store.adherenceRate else { return "开始记录后出现" }
        return String(format: "%.0f%%", r * 100)
    }

    private var waterText: String {
        let today = store.waterLogs.first { Calendar.current.isDateInToday($0.date) }
        guard let w = today else { return "未开始" }
        return "\((w.cups * 250) >= w.goalMl ? "达标 ✓" : "\(w.cups * 250)/\(w.goalMl) ml")"
    }

    // 诱因排行空态=倒计时进度（v10 微调1）
    private var triggerStatusText: String {
        let days = store.foodLogs.compactMap { Calendar.current.isDateInToday($0.date) ? $0.date : nil }.count
        _ = days
        let distinctDays = Set(store.foodLogs.map { Calendar.current.startOfDay(for: $0.date) }).count
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
}

// MARK: - 诱因排行（规则级可解释：发作前72h红黄绿食物交集——不做黑盒评分）

struct TriggerRankView: View {
    @ObservedObject var store = Store.shared

    private var ranked: [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for flare in store.flares {
            let window = Calendar.current.date(byAdding: .hour, value: -72, to: flare.startDate)!
            let foods = store.foodLogs.filter { $0.date >= window && $0.date <= flare.startDate && $0.level != "green" }
            for f in Set(foods.map(\.itemName)) {
                counts[f, default: 0] += 1
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
                    Text("记录 30 天饮食 + 3 次发作后，这里会告诉你「最近几次发作前你共同吃了什么」——不是评分，是你自己的规律。")
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
                            Text("\(i + 1).")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                            Text(r.name)
                            Spacer()
                            Text("\(r.count) 次发作前 72h 内出现过")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("你最近 \(store.flares.count) 次发作前的共同食物")
                } footer: {
                    Text("这是你自己的数据，不是通用建议。「对我相关的列表」比任何通用清单都有用（患者研究实证）。")
                }
            }
        }
        .navigationTitle("诱因排行")
    }
}

// MARK: - 改变页（疼痛减少→生活质量→幸福感的因果链可视化；身份投票行）

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
                changeRow("无痛天数", current: "\(store.flareFreeDays) 天", prior: "无痛天数会随坚持增长")
                if !store.weightLogs.isEmpty {
                    let first = store.weightLogs.min { $0.date < $1.date }?.kg ?? 0
                    let last = store.weightLogs.max { $0.date < $1.date }?.kg ?? 0
                    changeRow("体重", current: String(format: "%.1f kg", last), prior: String(format: "记录开始时：%.1f kg", first))
                }
            }

            Section {
                HStack {
                    Text("你给自己投了 \(store.meta.seedVotesTotal) 票")
                        .font(.body.weight(.semibold))
                    Spacer()
                    Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                }
                Text("每一次实时记录都是给「照顾好自己的人」投的一票。补记的不计数——因为投票要算数。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let m = store.meta.motivation {
                Section {
                    Text("身体好了，\(m.rawValue == "陪家人更久" ? "陪家人的日子才安稳。" : m.rawValue == "不再被疼醒" ? "才不用再被疼醒。" : "工作才有着落。")")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("改变")
        .toolbar {
            NavigationLink("记体重") { WeightEditor() }
        }
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

// MARK: - 医生报告生成（Pro；HTML 打印一页 A4；缺失灰标）

enum ReportGenerator {
    static func generate(store: Store) {
        let readings = store.readings.sorted { $0.date < $1.date }
        let flares = store.flares.sorted { $0.startDate > $1.startDate }
        let html = buildHTML(store: store, readings: readings, flares: flares)

        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("UricNote_Report.html")
        try? html.write(to: tmp, atomically: true, encoding: .utf8)

        // 用 Quick Look 打印/导出 PDF（ShareSheet）
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

        var readingRows = ""
        for r in readings {
            readingRows += "<tr><td>\(df.string(from: r.date))</td><td>\(String(format: "%.2f", r.valueMgDl))</td><td>\(r.atTarget ? "At target" : "Above goal")</td><td>\(r.source == "home" ? "Home" : "Lab")</td></tr>"
        }
        if readings.isEmpty {
            readingRows = "<tr><td colspan=4 class=na>未记录 No data</td></tr>"
        }

        var flareRows = ""
        for f in flares.prefix(10) {
            flareRows += "<tr><td>\(df.string(from: f.startDate))</td><td>\(f.joints.joined(separator: "/"))</td><td>\(f.painPeak)/10</td><td>\(f.canWalk ? "Yes" : "No")</td></tr>"
        }
        if flares.isEmpty {
            flareRows = "<tr><td colspan=4 class=na>未记录 No data</td></tr>"
        }

        let adherence = store.adherenceRate.map { String(format: "%.0f%%", $0 * 100) } ?? "未记录"
        let activeMed = store.medPlans.first(where: { $0.active })
        let medLine = activeMed.map { "\($0.name) \($0.dose) ×\($0.timesPerDay)/日" } ?? "未记录"

        return """
        <html><head><meta charset=utf-8><style>
        body{font-family:-apple-system;margin:32px;font-size:13px}
        h1{font-size:20px;margin-bottom:2px} .sub{color:#666;margin-bottom:16px}
        h2{font-size:15px;margin:18px 0 6px;border-bottom:1px solid #ddd;padding-bottom:4px}
        table{width:100%;border-collapse:collapse} td,th{border:1px solid #ddd;padding:5px 8px;text-align:left}
        .na{color:#aaa;font-style:italic} .note{color:#666;font-size:11px;margin-top:20px}
        </style></head><body>
        <h1>UricNote 尿酸健康报告</h1>
        <div class=sub>生成时间 \(df.string(from: Date())) · 由患者自记录数据生成 · 供门诊参考</div>
        <h2>1. 尿酸化验趋势（目标 <6.0 mg/dL / 360 µmol/L）</h2>
        <table><tr><th>日期</th><th>mg/dL</th><th>判定</th><th>来源</th></tr>\(readingRows)</table>
        <h2>2. 发作史（最近 10 次）</h2>
        <table><tr><th>日期</th><th>部位</th><th>疼痛峰值</th><th>能否行走</th></tr>\(flareRows)</table>
        <h2>3. 依从性与用药</h2>
        <p>近 30 天服药依从率：<b>\(adherence)</b>（补记已浅标）<br>当前用药：\(medLine)<br>饮水达标：按体重目标记录中</p>
        <p class=note>本报告由 UricNote App 生成，全部数据为患者自记录（非医疗设备测量）。灰色/「未记录」= 该时段无数据，不代表正常。<br>Generated by UricNote. All data self-reported. "未记录/No data" means no entry — not normal status.</p>
        </body></html>
        """
    }
}
