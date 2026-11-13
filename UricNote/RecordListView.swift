import SwiftUI

// MARK: - Tab2 记录（发作/化验/服药/饮水/饮食 五入口+急性模式收纳）

struct RecordListView: View {
    @ObservedObject var store = Store.shared
    @AppStorage("acuteMode") private var acuteMode = false   // v7 稳定/急性双模式

    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink {
                        FlareEditorView()
                    } label: {
                        Label("记发作（3 秒）", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text(acuteMode ? "急性模式：只留最重要的" : "身体")
                }

                if !acuteMode {
                    Section("化验与生活方式") {
                        NavigationLink("尿酸化验值") { UricReadingList() }
                        NavigationLink("饮水与尿色") { WaterEditor() }
                        NavigationLink("饮食简记（红黄绿）") { FoodEditor() }
                        NavigationLink("体重") { WeightEditor() }
                    }
                    Section("用药") {
                        NavigationLink("服药计划与打卡") { MedTodayView() }
                    }
                }

                Section {
                    Toggle(isOn: $acuteMode) {
                        Label("急性发作模式", systemImage: acuteMode ? "bolt.fill" : "bolt.slash")
                    }
                    Text(acuteMode ? "已简化：只保留发作记录和饮水，其余收纳。" : "发作期间打开，界面只留最需要的。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } footer: {
                    Text("痛风宝实证：发作期界面简化（同 Migraine Buddy 暗色模式逻辑）。")
                }
            }
            .navigationTitle("记录")
        }
    }
}

// MARK: - 发作录入（3 秒三问：部位九选/疼痛滑条/能走吗；其余可选后补）

struct FlareEditorView: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss

    private let jointOptions = ["脚趾", "脚踝", "脚跟", "膝盖", "手指", "手腕", "手肘", "足背", "其他"]
    @State private var joints: Set<String> = []
    @State private var pain: Double = 6
    @State private var canWalk = true
    @State private var medsTaken = false
    @State private var notes = ""
    @State private var showDetail = false

    var body: some View {
        Form {
            Section("哪个部位痛？（可多选）") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 8)], spacing: 8) {
                    ForEach(jointOptions, id: \.self) { j in
                        Button(j) {
                            if joints.contains(j) { joints.remove(j) } else { joints.insert(j) }
                        }
                        .font(.callout)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(joints.contains(j) ? Color.red.opacity(0.18) : Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .buttonStyle(.plain)
            }
            Section {
                VStack(alignment: .leading) {
                    Text("疼痛程度：\(Int(pain))/10")
                    Slider(value: $pain, in: 1...10, step: 1)
                }
                Toggle("还能走路吗", isOn: $canWalk)
                Toggle("发作药吃了吗（秋水仙碱等）", isOn: $medsTaken)
            } header: {
                Text("就这三件，3 秒记完")
            }
            Section("可选：发作结束后补") {
                Toggle("对工作有影响吗", isOn: $showDetail)
                if showDetail {
                    Picker("影响程度", selection: $notes) {
                        Text("略有影响").tag("轻微")
                        Text("明显影响").tag("明显")
                        Text("无法工作").tag("无法")
                    }
                }
                TextField("诱因备注（比如：昨晚喝了啤酒）", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }
            Section {
                Button("保存") {
                    let f = Flare(
                        startDate: Date(), endDate: nil,
                        joints: Array(joints), painPeak: Int(pain),
                        canWalk: canWalk, workImpact: 0,
                        medsTaken: medsTaken, triggerNotes: notes.isEmpty ? nil : notes
                    )
                    store.flares.append(f)
                    store.save()
                    // 发作后安抚（v8：全 App 唯一坏时刻，只安抚不统计）
                    UricCelebrate.show("记下了。今晚好好休息，这里都帮你记着，你不用惦记。")
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            } footer: {
                Text("夜间发作风险是白天 2.4 倍——这个入口按「痛醒状态也能用」设计。")
            }
        }
        .navigationTitle("记发作")
    }
}

// MARK: - 化验值录入（双单位自动+设复查节律）

struct UricReadingEditor: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss
    @State private var valueText = ""
    @State private var source = "lab"

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("数值", text: $valueText)
                        .keyboardType(.decimalPad)
                    Text(store.meta.unitIsUmol ? "µmol/L" : "mg/dL")
                        .foregroundColor(.secondary)
                }
                Picker("来源", selection: $source) {
                    Text("医院化验").tag("lab")
                    Text("家里自测").tag("home")
                }
                .pickerStyle(.segmented)
            } header: {
                Text("最近一次尿酸值")
            } footer: {
                Text("录入后自动设复查日（默认 8 周）——临床试验里每 2 个月测一次的人 93% 一年无发作（GoutSMART，2022）。")
            }
            Button("保存") {
                if let v = Double(valueText), v > 0 {
                    let mgDl = store.meta.unitIsUmol ? v / 59.48 : v
                    let r = UricReading(date: Date(), valueMgDl: mgDl, source: source)
                    store.readings.append(r)
                    // 节律联动（v6 难点2 核心：化验值→复查日）
                    store.review.nextReviewDate = Calendar.current.date(byAdding: .weekOfYear, value: store.review.intervalWeeks, to: Date())
                    store.save()
                    if r.atTarget {
                        UricCelebrate.show("达标了。结晶正在悄悄溶解。")
                    } else {
                        UricCelebrate.show("记好了。距目标 \(String(format: "%.1f", r.valueMgDl - 6.0))，复查日已排上。")
                    }
                    dismiss()
                }
            }
        }
        .navigationTitle("记化验值")
    }
}

struct UricReadingList: View {
    @ObservedObject var store = Store.shared

    var body: some View {
        List {
            ForEach(store.readings.sorted { $0.date > $1.date }) { r in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(store.meta.unitIsUmol
                             ? String(format: "%.0f µmol/L", r.urateUnit)
                             : String(format: "%.1f mg/dL", r.valueMgDl))
                            .font(.body.weight(.semibold))
                        Spacer()
                        Text(r.atTarget ? "达标 ✓" : "未达标")
                            .font(.caption)
                            .foregroundColor(r.atTarget ? .green : .amber)
                    }
                    Text(r.date.formatted(date: .abbreviated, time: .omitted) + (r.source == "home" ? " · 家测" : " · 医院化验"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onDelete { store.readings.remove(atOffsets: $0); store.save() }
        }
        .navigationTitle("化验值历史")
        .toolbar {
            NavigationLink("记一次") { UricReadingEditor() }
        }
    }
}

// MARK: - 饮水（目标按体重自动：kg×35ml 下限2000）

struct WaterEditor: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss

    private var goalMl: Int {
        let lastKg = store.weightLogs.max { $0.date < $1.date }?.kg ?? 70
        return max(2000, Int(lastKg * 35))
    }
    private var todayLog: WaterLog? {
        store.waterLogs.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("今天：\(todayLog?.cups ?? 0) 杯（约 \((todayLog?.cups ?? 0) * 250)/\(goalMl) ml）")
                        .font(.body.weight(.medium))
                    Spacer()
                    Button("+ 一杯") {
                        addCup()
                    }
                    .buttonStyle(.borderedProminent)
                }
                ProgressView(value: Double((todayLog?.cups ?? 0) * 250), total: Double(goalMl))
            } footer: {
                Text("目标按体重自动算（体重×35ml）。脱水是痛风发作常见诱因——水是最便宜的药。")
            }
            Section("尿色自评（脱水信号）") {
                Picker("今天尿色", selection: Binding(
                    get: { todayLog?.urineColor ?? 3 },
                    set: { setUrine($0) }
                )) {
                    Text("浅黄（好）").tag(2)
                    Text("正常").tag(3)
                    Text("偏深（该喝水了）").tag(5)
                    Text("很深（脱水）").tag(7)
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("饮水")
    }

    private func addCup() {
        if let i = store.waterLogs.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
            store.waterLogs[i].cups += 1
        } else {
            let w = WaterLog(date: Date(), cups: 1, goalMl: goalMl)
            store.waterLogs.append(w)
            seedCheck(type: "water")
        }
        store.save()
        if (todayLog?.cups ?? 0) * 250 >= goalMl {
            UricCelebrate.show("今天的目标完成了 — that's today handled.")
        }
    }

    private func setUrine(_ c: Int) {
        if let i = store.waterLogs.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
            store.waterLogs[i].urineColor = c
        } else {
            let w = WaterLog(date: Date(), cups: 0, goalMl: goalMl)
            var nw = w
            nw.urineColor = c
            store.waterLogs.append(nw)
        }
        store.save()
    }

    // 种子联动（v9：种子行为打卡自动计入）
    private func seedCheck(type: String) {
        guard var s = store.seed, s.type == type else { return }
        s.realStreak += 1
        store.seed = s
        store.meta.seedVotesTotal += 1
        store.save()
        UricCelebrate.show("That's the seed watered.")
    }
}

// MARK: - 饮食简记（红黄绿触碰；红灯多一秒摩擦——v9 环境设计）

struct FoodEditor: View {
    @ObservedObject var store = Store.shared
    @State private var item = ""

    private let quickRed = ["啤酒", "白酒", "海鲜", "动物内脏", "浓肉汤"]
    private let quickYellow = ["红肉", "豆腐", "豆浆", "果汁"]
    private let quickGreen = ["鸡蛋", "低脂奶", "蔬菜", "樱桃", "水"]

    var body: some View {
        Form {
            Section("刚吃了/喝了什么？") {
                TextField("自定义输入", text: $item)
                ForEach(quickRed, id: \.self) { n in
                    Button {
                        add(n, level: "red", alcohol: n.contains("酒"))
                    } label: {
                        Label(n, systemImage: "circle.fill").foregroundColor(.red)
                    }
                }
                ForEach(quickYellow, id: \.self) { n in
                    Button {
                        add(n, level: "yellow", alcohol: false)
                    } label: {
                        Label(n, systemImage: "circle.lefthalf.filled").foregroundColor(.yellow)
                    }
                }
                ForEach(quickGreen, id: \.self) { n in
                    Button {
                        add(n, level: "green", alcohol: false)
                    } label: {
                        Label(n, systemImage: "checkmark.circle").foregroundColor(.green)
                    }
                }
            } footer: {
                Text("只记「吃了什么」，不用称重算热量。红黄绿按嘌呤含量：红 >150mg/100g，黄 50-150，绿 <50（来源：ACR 2020 指南）。")
            }
        }
        .navigationTitle("饮食简记")
    }

    private func add(_ name: String, level: String, alcohol: Bool) {
        // 红灯/酒精：环境摩擦（v9）——第一次弹确认
        if level == "red" || alcohol {
            let f = FoodLog(date: Date(), itemName: name, level: level, isAlcohol: alcohol)
            store.foodLogs.append(f)
            store.save()
            UricCelebrate.show("记了。偶尔一次没关系，知道规律才重要。")
        } else {
            let f = FoodLog(date: Date(), itemName: name, level: level, isAlcohol: false)
            store.foodLogs.append(f)
            store.save()
        }
        item = ""
    }
}

// MARK: - 体重（周记粒度；v10 微调4：并入改变页，这里留录入入口）

struct WeightEditor: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss
    @State private var kgText = ""

    var body: some View {
        Form {
            Section("这次体重（kg）") {
                HStack {
                    TextField("例如 88.5", text: $kgText)
                        .keyboardType(.decimalPad)
                    Text("kg").foregroundColor(.secondary)
                }
                Button("保存") {
                    if let v = Double(kgText), v > 0 {
                        store.weightLogs.append(WeightLog(date: Date(), kg: v))
                        store.save()
                        seedCheck()
                        UricCelebrate.show("One more brick.")
                        dismiss()
                    }
                }
            } footer: {
                Text("减重是降尿酸最有效的生活方式干预（每减 5kg，尿酸平均降约 1）。每周一次就够。")
            }
        }
        .navigationTitle("体重")
    }

    private func seedCheck() {
        guard var s = store.seed, s.type == "weigh" else { return }
        s.realStreak += 1
        store.seed = s
        store.meta.seedVotesTotal += 1
        store.save()
    }
}
