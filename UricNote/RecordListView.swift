import SwiftUI
import Charts

// MARK: - Tab2 记录 v11（A9 本体唯一原则：每个类目=一个完整本体页：记一次+趋势+历史可改可删）
// A10：急性发作模式已取消（健哥裁）。仪表盘按钮=快捷入口直达本体页，不另做界面。

struct RecordListView: View {
    @ObservedObject var store = Store.shared

    var body: some View {
        NavigationView {
            List {
                Section("身体") {
                    NavigationLink { FlarePage() } label: {
                        Label("发作记录", systemImage: "exclamationmark.triangle.fill").foregroundColor(.danger)
                    }
                    NavigationLink { UricReadingPage() } label: {
                        Label("尿酸化验值", systemImage: "list.clipboard")
                    }
                }
                Section("生活方式") {
                    NavigationLink { WaterPage() } label: {
                        Label("饮水与尿色", systemImage: "drop.fill").foregroundColor(.water)
                    }
                    NavigationLink { FoodPage() } label: {
                        Label("饮食（高嘌呤登记）", systemImage: "fork.knife").foregroundColor(.warn)
                    }
                    NavigationLink { SleepPage() } label: {
                        Label("入睡时间", systemImage: "moon.fill").foregroundColor(.brand)
                    }
                    NavigationLink { WeightPage() } label: {
                        Label("体重", systemImage: "scalemass").foregroundColor(.success)
                    }
                }
                Section("用药") {
                    NavigationLink { MedTodayView() } label: {
                        Label("当前使用药物药量", systemImage: "pills").foregroundColor(.brand)
                    }
                }
                #if DEBUG
                Section("测试") {
                    ResetDataButton()
                }
                #endif
            }
            .navigationTitle("记录")
        }
    }
}

// v11.1 #8：重置所有数据（测试专用——#if DEBUG，上架 Release 自动消失）
struct ResetDataButton: View {
    @ObservedObject var store = Store.shared
    @State private var confirm1 = false
    @State private var confirm2 = false
    @State private var inputText = ""

    var body: some View {
        Button(role: .destructive) {
            confirm1 = true
        } label: {
            Label("重置所有数据（测试用）", systemImage: "trash")
        }
        .alert("确定要清空全部记录吗？", isPresented: $confirm1) {
            Button("取消", role: .cancel) {}
            Button("继续", role: .destructive) { confirm2 = true }
        } message: {
            Text("所有发作/化验/饮水/饮食/档案数据将永久删除，不可恢复。")
        }
        .alert("最后确认", isPresented: $confirm2) {
            TextField("输入 RESET 确认", text: $inputText)
            Button("取消", role: .cancel) { inputText = "" }
            Button("执行重置", role: .destructive) {
                if inputText == "RESET" {
                    store.resetAllData()
                }
                inputText = ""
            }
        } message: {
            Text("输入 RESET（全大写）执行。")
        }
    }
}

// MARK: - 发作本体页（A9：记一次 + 历史列表可改可删）

struct FlarePage: View {
    @ObservedObject var store = Store.shared

    var body: some View {
        List {
            Section {
                NavigationLink { FlareEditorView() } label: {
                    Label("记一次发作（3 秒）", systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold)).foregroundColor(.brand)
                }
            }
            Section("发作历史（点一条可改，左滑删除）") {
                if store.flares.isEmpty {
                    Text("还没有发作记录").font(.callout).foregroundColor(.secondary)
                }
                ForEach(store.flares.sorted { $0.startDate > $1.startDate }) { f in
                    NavigationLink { FlareEditorView(editing: f) } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dateText(f.startDate) + " · " + f.joints.joined(separator: "/"))
                                .font(.body.weight(.medium))
                            Text("疼痛峰值 \(f.painPeak)/10 · \(f.canWalk ? "能走" : "不能走")")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { idx in
                    let sorted = store.flares.sorted { $0.startDate > $1.startDate }
                    for i in idx { if let f = sorted[safe: i] { store.flares.removeAll { $0.id == f.id } } }
                }
            }
        }
        .navigationTitle("发作记录")
    }

    private func dateText(_ d: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "M月d日"
        return df.string(from: d)
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

// MARK: - 发作编辑器（A7 文字锚点 / A8 药问题 / D1 变量分离 / D5 默认不选 / A4 可编辑）

struct FlareEditorView: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss
    var editing: Flare? = nil

    private let jointOptions = ["脚趾", "脚踝", "脚跟", "膝盖", "手指", "手腕", "手肘", "足背", "其他"]
    // A7：1-10 文字锚点（美国诊所 NRS 量表的语感补充）
    private let painAnchors = [
        1: "几乎注意不到", 2: "有点不舒服", 3: "疼，但不影响做事", 4: "疼，开始在意",
        5: "明显疼", 6: "挺疼的", 7: "很痛，影响走路", 8: "很痛，走路困难",
        9: "剧痛，只想躺着", 10: "最剧烈的疼，想去急诊",
    ]
    private let impactOptions = ["轻微", "明显", "无法"]

    @State private var joints: Set<String> = []
    @State private var pain: Double = 0        // D5：默认不选（0=未选，保存前校验）
    @State private var canWalk = true
    @State private var showPainkiller = false       // A8：止痛药默认收起
    @State private var tookPainkiller = false
    @State private var painkillerName = ""
    @State private var showWorkImpact = false
    @State private var workImpactNote = ""     // D1：与诱因备注分离
    @State private var notes = ""

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
                        .background(joints.contains(j) ? Color.danger.opacity(0.18) : Color.cardBG)
                        .cornerRadius(10)
                    }
                }
                .buttonStyle(.plain)
            }
            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Text(pain == 0 ? "疼痛程度：拖一下选" : "疼痛程度：\(Int(pain))/10 —— \(painAnchors[Int(pain)] ?? "")")
                        Spacer()
                        if pain > 0 {
                            // v11.1 Daylio 式色彩编码：拖动时数值底色随程度变绿→红
                            Text("\(Int(pain))")
                                .font(.caption.bold())
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.pain(Int(pain)).opacity(0.18))
                                .foregroundColor(Color.pain(Int(pain)))
                                .clipShape(Capsule())
                        }
                    }
                    Slider(value: $pain, in: 1...10, step: 1)
                        .onChange(of: pain) { _ in if pain == 0 { pain = 1 } }
                    if pain == 0 {
                        Text("1=几乎注意不到 · 7=很痛影响走路 · 10=想去急诊")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
                Toggle("还能走路吗", isOn: $canWalk)
                // v11.1 #7：删"今天吃过药吗"（药打卡已独立成仪表盘待办行，不再重复采集）
            } header: {
                Text("就这两件，3 秒记完")
            }
            Section("很痛才看这里（止痛药）") {
                Toggle("用了止痛药", isOn: $showPainkiller)
                if showPainkiller {
                    Toggle("刚才吃了吗", isOn: $tookPainkiller)
                    TextField("止痛药名（记一次固定，如：布洛芬）", text: $painkillerName)
                }
            }
            Section {
                Toggle("对工作有影响吗", isOn: $showWorkImpact)
                if showWorkImpact {
                    // D1 修复：影响程度独立变量，不再污染诱因备注
                    Picker("影响程度", selection: $workImpactNote) {
                        ForEach(impactOptions, id: \.self) { Text($0).tag($0) }
                    }
                }
                TextField("诱因备注（比如：昨晚喝了啤酒）", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("可选：发作结束后补")
            }
            Section {
                Button(editing == nil ? "保存" : "保存修改") {
                    save()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .disabled(pain == 0 || joints.isEmpty)
            } footer: {
                Text("夜间发作风险是白天 2.4 倍——这个入口按「痛醒状态也能用」设计。")
            }
        }
        .navigationTitle(editing == nil ? "记发作" : "改发作记录")
        .onAppear { if let e = editing { load(e) } }
    }

    private func load(_ e: Flare) {
        joints = Set(e.joints)
        pain = Double(e.painPeak)
        canWalk = e.canWalk
        tookPainkiller = e.tookPainkiller ?? false
        showPainkiller = e.tookPainkiller != nil
        painkillerName = e.painkillerName ?? ""
        showWorkImpact = e.workImpact > 0
        workImpactNote = e.workImpactNote ?? ""
        notes = e.triggerNotes ?? ""
    }

    private func save() {
        let impactIdx = impactOptions.firstIndex(of: workImpactNote).map { $0 + 1 } ?? 0
        if var e = editing, let idx = store.flares.firstIndex(where: { $0.id == e.id }) {
            // A4：编辑现有记录
            e.joints = Array(joints); e.painPeak = Int(pain); e.canWalk = canWalk
            e.tookPainkiller = showPainkiller ? tookPainkiller : nil
            e.painkillerName = showPainkiller && !painkillerName.isEmpty ? painkillerName : nil
            e.workImpact = showWorkImpact ? impactIdx : 0
            e.workImpactNote = showWorkImpact && !workImpactNote.isEmpty ? workImpactNote : nil
            e.triggerNotes = notes.isEmpty ? nil : notes
            store.flares[idx] = e
            UricCelebrate.show("改好了")
        } else {
            let f = Flare(startDate: Date(), endDate: nil, joints: Array(joints), painPeak: Int(pain),
                          canWalk: canWalk, workImpact: showWorkImpact ? impactIdx : 0,
                          workImpactNote: showWorkImpact && !workImpactNote.isEmpty ? workImpactNote : nil,
                          tookMedsToday: nil,   // v11.1：药打卡独立成仪表盘待办，发作页不再采集
                          tookPainkiller: showPainkiller ? tookPainkiller : nil,
                          painkillerName: showPainkiller && !painkillerName.isEmpty ? painkillerName : nil,
                          triggerNotes: notes.isEmpty ? nil : notes)
            store.flares.append(f)
            UricCelebrate.show("记下了。今晚好好休息，这里都帮你记着，你不用惦记。")
        }
        dismiss()
    }
}

// MARK: - 化验值本体页（A5 趋势图免费 + A9 本体 + A4 可改 + C12 肌酐）

struct UricReadingPage: View {
    @ObservedObject var store = Store.shared

    var body: some View {
        List {
            Section {
                NavigationLink { UricReadingEditor() } label: {
                    Label("记一次化验值", systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold)).foregroundColor(.brand)
                }
            }
            // A5：趋势折线图（Swift Charts，iOS16；免费功能——给自己看的）
            if store.readings.count >= 2 {
                Section("趋势") {
                    UricTrendChart()
                        .frame(height: 180)
                }
            }
            Section("历史（点一条可改，左滑删除）") {
                if store.readings.isEmpty {
                    Text("还没有化验记录").font(.callout).foregroundColor(.secondary)
                }
                ForEach(store.readings.sorted { $0.date > $1.date }) { r in
                    NavigationLink { UricReadingEditor(editing: r) } label: {
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
                            HStack(spacing: 8) {
                                Text(r.date.formatted(date: .abbreviated, time: .omitted))
                                Text(r.source == "home" ? "家测" : "医院化验")
                                if let cr = r.creatinineMgDl {
                                    Text("肌酐 \(String(format: "%.1f", cr)) mg/dL")
                                }
                            }
                            .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { idx in
                    let sorted = store.readings.sorted { $0.date > $1.date }
                    for i in idx { if let r = sorted[safe: i] { store.readings.removeAll { $0.id == r.id } } }
                }
            }
        }
        .navigationTitle("尿酸化验值")
        .toolbar {
            NavigationLink("调间隔") { ReviewIntervalEditor() }
        }
    }
}

// A5：趋势折线（双单位自适应；目标线 6.0/360）
struct UricTrendChart: View {
    @ObservedObject var store = Store.shared

    var body: some View {
        let data = store.readings.sorted { $0.date < $1.date }
        Chart {
            ForEach(data, id: \.id) { r in
                LineMark(x: .value("日期", r.date),
                         y: .value("尿酸", store.meta.unitIsUmol ? r.urateUnit : r.valueMgDl))
                PointMark(x: .value("日期", r.date),
                          y: .value("尿酸", store.meta.unitIsUmol ? r.urateUnit : r.valueMgDl))
            }
            RuleMark(y: .value("目标", store.meta.unitIsUmol ? 360.0 : 6.0))
                .foregroundStyle(Color.green.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
        }
        .chartYAxis {
            AxisMarks(position: .trailing)
        }
        .accessibilityLabel("尿酸趋势图")
    }
}

// A5：复查间隔可调（4/6/8/12 周）
struct ReviewIntervalEditor: View {
    @ObservedObject var store = Store.shared

    var body: some View {
        Form {
            Picker("复查间隔", selection: Binding(
                get: { store.review.intervalWeeks },
                set: { w in
                    store.review.intervalWeeks = w
                    if store.lastReading != nil {
                        store.review.nextReviewDate = Calendar.current.date(byAdding: .weekOfYear, value: w, to: Date())
                    }
                }
            )) {
                Text("4 周").tag(4); Text("6 周").tag(6); Text("8 周").tag(8); Text("12 周").tag(12)
            }
            .pickerStyle(.segmented)
        }
        .navigationTitle("复查节律")
    }
}

// MARK: - 化验值编辑器（C12 肌酐 + A4 编辑 + 联动复查日）

struct UricReadingEditor: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss
    var editing: UricReading? = nil

    @State private var valueText = ""
    @State private var creatinineText = ""   // C12：可选
    @State private var source = "lab"

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("数值", text: $valueText).keyboardType(.decimalPad)
                    Text(store.meta.unitIsUmol ? "µmol/L" : "mg/dL").foregroundColor(.secondary)
                }
                HStack {
                    TextField("肌酐（可选）", text: $creatinineText).keyboardType(.decimalPad)
                    Text("mg/dL").foregroundColor(.secondary)
                }
                Picker("来源", selection: $source) {
                    Text("医院化验").tag("lab")
                    Text("家里自测").tag("home")
                }
                .pickerStyle(.segmented)
            } header: {
                Text(editing == nil ? "最近一次尿酸值" : "修改化验值")
            } footer: {
                Text("肌酐是降酸药选择依据（苯溴马隆肾功能禁忌/别嘌醇按肾功能调量）——报告单上有就顺手填。录完自动排复查日（默认 8 周，可调）。")
            }
            Button(editing == nil ? "保存" : "保存修改") {
                save()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle(editing == nil ? "记化验值" : "改化验值")
        .onAppear { if let e = editing { load(e) } }
    }

    private func load(_ e: UricReading) {
        valueText = store.meta.unitIsUmol ? String(format: "%.0f", e.urateUnit) : String(format: "%.1f", e.valueMgDl)
        creatinineText = e.creatinineMgDl.map { String(format: "%.1f", $0) } ?? ""
        source = e.source
    }

    private func save() {
        guard let v = Double(valueText), v > 0 else { return }
        let mgDl = store.meta.unitIsUmol ? v / 59.48 : v
        let cr = Double(creatinineText)
        if var e = editing, let idx = store.readings.firstIndex(where: { $0.id == e.id }) {
            e.valueMgDl = mgDl; e.creatinineMgDl = cr; e.source = source
            store.readings[idx] = e
            UricCelebrate.show("改好了")
        } else {
            let r = UricReading(date: Date(), valueMgDl: mgDl, creatinineMgDl: cr, source: source)
            store.readings.append(r)
            store.review.nextReviewDate = Calendar.current.date(byAdding: .weekOfYear, value: store.review.intervalWeeks, to: Date())
            if r.atTarget {
                UricCelebrate.show("达标了。结晶正在悄悄溶解。")
            } else {
                UricCelebrate.show("记好了。复查日已排上。")
            }
        }
        dismiss()
    }
}

// MARK: - 饮水本体页（A2 重做：自填杯量/逐杯明细/今日合计/早午晚尿色/沿用开关）

struct WaterPage: View {
    @ObservedObject var store = Store.shared
    @State private var showAutoFillAsk = false

    var body: some View {
        List {
            Section("今天") {
                if let w = store.todayWater {
                    if w.provenance == .estimated {
                        // A3：沿用日诚实标记
                        HStack {
                            Image(systemName: "sparkles").foregroundColor(.brand)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("今天按上周平均沿用（\(w.totalMl)ml）").font(.callout.weight(.medium))
                                Text("不算连续打卡；想重新手记就在设置里关掉沿用").font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("重记") {
                                if let i = store.waterDays.firstIndex(where: { $0.id == w.id }) {
                                    store.waterDays[i].cups = []
                                    store.waterDays[i].provenance = .recorded
                                }
                            }
                            .font(.caption)
                        }
                    } else {
                        // v11.1 Waterllama 式水位杯：数字之外的即时可视化
                        HStack(spacing: 16) {
                            WaterGaugeView(fraction: CGFloat(w.totalMl) / CGFloat(max(w.goalMl, 1)))
                                .frame(width: 56, height: 88)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("今日 \(w.totalMl) ml").font(.title3.bold()).foregroundColor(.water)
                                Text("\(w.cups.count) 杯 · 目标 \(w.goalMl) ml").font(.caption).foregroundColor(.secondary)
                                // v11.1 #11：每杯容量提前到记一杯下方（就近原则）
                                Stepper("每杯 \(w.cupSizeMl) ml（容器不一可改）", value: Binding(
                                    get: { store.todayWater?.cupSizeMl ?? 250 },
                                    set: { v in if let i = store.waterDays.firstIndex(where: { Calendar.current.isDate($0.day, inSameDayAs: Date()) }) { store.waterDays[i].cupSizeMl = v } }
                                ), in: 100...800, step: 50)
                                .font(.caption)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        Button { addCup() } label: {
                            Label("记一杯", systemImage: "plus.circle.fill")
                                .font(.body.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.water)
                        // A2：逐杯明细
                        if !w.cups.isEmpty {
                            ForEach(w.cups.reversed()) { c in
                                HStack {
                                    Image(systemName: "drop.fill").font(.caption).foregroundColor(.water)
                                    Text(c.time.formatted(date: .omitted, time: .shortened))
                                    Spacer()
                                    Text("\(c.ml) ml").font(.caption).foregroundColor(.secondary)
                                }
                                .swipeActions {
                                    Button("删", role: .destructive) { removeCup(c) }
                                }
                            }
                        }
                    }
                }
            }
            Section {
                urinePicker("早", slot: 0)
                urinePicker("午", slot: 1)
                urinePicker("晚", slot: 2)
            } header: {
                Text("尿色自评（脱水信号，早午晚）")
            } footer: {
                Text("没记的时段就空着——不猜。")
            }
            Section {
                Toggle("沿用上周平均（不想每天记时用）", isOn: Binding(
                    get: { store.meta.waterAutoFillActive },
                    set: { on in on ? store.enableWaterAutoFill() : store.disableWaterAutoFill() }
                ))
            } header: {
                Text("设置")
            } footer: {
                Text("开启后，没手记的日子自动按最近 7 天平均填，报告标「沿用」不算打卡。随时可关，关掉后恢复手记。")
            }
        }
        .navigationTitle("饮水与尿色")
        .onAppear {
            // A2：满 7 天实测后问一次（只问一次）
            if store.meta.waterAutoFillAsked && !store.meta.waterAutoFillActive && !UserDefaults.standard.bool(forKey: "ur.waterAskShown") {
                showAutoFillAsk = true
                UserDefaults.standard.set(true, forKey: "ur.waterAskShown")
            }
        }
        .alert("已经手记 7 天了", isPresented: $showAutoFillAsk) {
            Button("沿用上周平均") { store.enableWaterAutoFill() }
            Button("继续手记", role: .cancel) {}
        } message: {
            Text("可以改成自动按上周平均填，不想记的时候少一件事。随时可关。")
        }
    }

    @ViewBuilder
    private func urinePicker(_ label: String, slot slotIndex: Int) -> some View {
        Picker(label, selection: Binding(
            get: { urineValue(slotIndex) ?? 0 },
            set: { v in setUrine(slotIndex, v == 0 ? nil : v) }
        )) {
            Text("未记").tag(0)
            Text("浅黄（好）").tag(2)
            Text("正常").tag(3)
            Text("偏深").tag(5)
            Text("很深（脱水）").tag(7)
        }
    }

    private func urineValue(_ slotIndex: Int) -> Int? {
        guard let w = store.todayWater else { return nil }
        switch slotIndex {
        case 0: return w.urine.morning
        case 1: return w.urine.noon
        default: return w.urine.evening
        }
    }

    private func addCup() {
        let size = store.todayWater?.cupSizeMl ?? 250
        if let i = store.waterDays.firstIndex(where: { Calendar.current.isDate($0.day, inSameDayAs: Date()) }) {
            let wasBelowGoal = store.waterDays[i].totalMl < store.waterDays[i].goalMl
            store.waterDays[i].cups.append(WaterCup(time: Date(), ml: size))
            Haptic.tap()
            let total = store.waterDays[i].totalMl
            if wasBelowGoal && total >= store.waterDays[i].goalMl {
                // v11.1：达标庆祝只弹一次（防重复键）
                let df = DateFormatter(); df.dateFormat = "yyyyMMdd"
                let key = "ur.waterGoalToasted_" + df.string(from: Date())
                if !UserDefaults.standard.bool(forKey: key) {
                    UserDefaults.standard.set(true, forKey: key)
                    Haptic.success()
                    UricCelebrate.show("今日喝水达标 🎉 水是最便宜的药")
                }
            } else {
                UricCelebrate.show("第 \(store.waterDays[i].cups.count) 杯 · 今日 \(total) ml")
            }
        }
    }

    private func removeCup(_ c: WaterCup) {
        if let i = store.waterDays.firstIndex(where: { Calendar.current.isDate($0.day, inSameDayAs: Date()) }) {
            store.waterDays[i].cups.removeAll { $0.id == c.id }
        }
    }

    private func setUrine(_ slotIndex: Int, _ v: Int?) {
        let today = Calendar.current.startOfDay(for: Date())
        if let i = store.waterDays.firstIndex(where: { Calendar.current.isDate($0.day, inSameDayAs: today) }) {
            switch slotIndex {
            case 0: store.waterDays[i].urine.morning = v
            case 1: store.waterDays[i].urine.noon = v
            default: store.waterDays[i].urine.evening = v
            }
        }
    }
}

// MARK: - 饮食本体页（B3 重做：红区多选+场景+负面记录+自定义；不分早午晚）

struct FoodPage: View {
    @ObservedObject var store = Store.shared
    @State private var custom = ""

    var body: some View {
        List {
            if let f = store.todayFood {
                Section("今天") {
                    if f.noTriggerToday {
                        Label("已记：今天没碰高嘌呤 ✓", systemImage: "checkmark.seal.fill").foregroundColor(.success)
                    } else if !f.items.isEmpty || !f.scenes.isEmpty {
                        Text("已记：" + (f.scenes + f.items).joined(separator: "、"))
                            .font(.callout)
                    }
                }
            }
            Section {
                Button {
                    markNoTrigger()
                } label: {
                    Label("今天没吃高嘌呤，记一笔 ✓", systemImage: "checkmark.circle")
                        .foregroundColor(.success)
                }
            } header: {
                Text("今天没碰高嘌呤？（负面记录很重要）")
            } footer: {
                Text("只记「吃了」会让排行虚高——没吃的日子也是数据。")
            }
            // v11.1 Daylio 式 chip 网格：点选高亮，零键盘
            Section {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(FoodLibrary.redZone) { item in
                        FoodChip(
                            name: item.name,
                            selected: store.todayFood?.items.contains(item.name) == true,
                            tint: .danger
                        ) { toggle(item.name) }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("碰到的高嘌呤（多选，不分早午晚）")
            } footer: {
                Text("红肉已移到「适量注意」——碰了就记，请勿大量。")
            }
            Section {
                ForEach(FoodLibrary.scenes, id: \.name) { s in
                    Button {
                        addScene(s.name, auto: s.autoItems)
                    } label: {
                        HStack {
                            Text(s.name).foregroundColor(.primary)
                            Spacer()
                            if store.todayFood?.scenes.contains(s.name) == true {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.danger)
                            }
                        }
                    }
                }
            } header: {
                Text("今天吃的是一整场？（场景一键）")
            } footer: {
                Text("火锅/烧烤/快餐点了自动带上关联红区项（汤底/红肉/啤酒/可乐）。")
            }
            Section("其他（自定义）") {
                HStack {
                    TextField("比如：小龙虾", text: $custom)
                    Button("记") { if !custom.isEmpty { Haptic.tap(); toggle(custom); custom = "" } }
                }
            }
        }
        .navigationTitle("饮食")
    }

    private func ensureToday() -> Int {
        if let i = store.foodDays.firstIndex(where: { Calendar.current.isDate($0.day, inSameDayAs: Date()) }) {
            return i
        }
        let nd = FoodDayLog(day: Date(), items: [], scenes: [], noTriggerToday: false)
        store.foodDays.append(nd)
        return store.foodDays.count - 1
    }

    private func toggle(_ name: String) {
        let i = ensureToday()
        if let j = store.foodDays[i].items.firstIndex(of: name) {
            store.foodDays[i].items.remove(at: j)
        } else {
            store.foodDays[i].items.append(name)
            store.foodDays[i].noTriggerToday = false
        }
    }

    private func addScene(_ scene: String, auto: [String]) {
        let i = ensureToday()
        if store.foodDays[i].scenes.contains(scene) {
            store.foodDays[i].scenes.removeAll { $0 == scene }
        } else {
            store.foodDays[i].scenes.append(scene)
            for a in auto where !store.foodDays[i].items.contains(a) {
                store.foodDays[i].items.append(a)
            }
            store.foodDays[i].noTriggerToday = false
            UricCelebrate.show("记了。偶尔一次没关系，知道规律才重要。")
        }
    }

    private func markNoTrigger() {
        let i = ensureToday()
        store.foodDays[i].noTriggerToday = true
        store.foodDays[i].items = []
        store.foodDays[i].scenes = []
        UricCelebrate.show("记了——这一天也是数据")
    }
}

// MARK: - 入睡历史页（B2）

struct SleepPage: View {
    @ObservedObject var store = Store.shared

    private var avgBucket: String {
        let recent = store.sleepLogs.suffix(14)
        guard !recent.isEmpty else { return "—" }
        let avg = Double(recent.map { $0.bucket }.reduce(0, +)) / Double(recent.count)
        let idx = Int(avg.rounded())
        return ["23点前", "23-24点", "0-1点", "1点后"][min(idx, 3)]
    }

    var body: some View {
        List {
            Section {
                NavigationLink { SleepQuickPicker() } label: {
                    Label("记昨晚入睡（快捷四档）", systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold)).foregroundColor(.brand)
                }
            }
            Section {
                Text("近 14 天平均：\(avgBucket)").font(.callout)
            }
            Section("历史（左滑删除）") {
                ForEach(store.sleepLogs.sorted { $0.night > $1.night }) { s in
                    HStack {
                        Text(s.night.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        Text(s.bucketText).font(.callout.weight(.medium))
                    }
                }
                .onDelete { idx in
                    let sorted = store.sleepLogs.sorted { $0.night > $1.night }
                    for i in idx { if let s = sorted[safe: i] { store.sleepLogs.removeAll { $0.id == s.id } } }
                }
            }
        }
        .navigationTitle("入睡时间")
    }
}

// MARK: - 体重本体页（A4 可改可删）

struct WeightPage: View {
    @ObservedObject var store = Store.shared

    var body: some View {
        List {
            Section {
                NavigationLink { WeightEditor() } label: {
                    Label("记一次体重", systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold)).foregroundColor(.brand)
                }
            }
            Section("历史（点一条可改，左滑删除）") {
                ForEach(store.weightLogs.sorted { $0.date > $1.date }) { w in
                    NavigationLink { WeightEditor(editing: w) } label: {
                        HStack {
                            Text(w.date.formatted(date: .abbreviated, time: .omitted))
                            Spacer()
                            Text(String(format: "%.1f kg", w.kg)).font(.callout.weight(.medium))
                        }
                    }
                }
                .onDelete { idx in
                    let sorted = store.weightLogs.sorted { $0.date > $1.date }
                    for i in idx { if let w = sorted[safe: i] { store.weightLogs.removeAll { $0.id == w.id } } }
                }
            }
        }
        .navigationTitle("体重")
    }
}

struct WeightEditor: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss
    var editing: WeightLog? = nil
    @State private var kgText = ""

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("例如 88.5", text: $kgText).keyboardType(.decimalPad)
                    Text("kg").foregroundColor(.secondary)
                }
                Button(editing == nil ? "保存" : "保存修改") {
                    if let v = Double(kgText), v > 0 {
                        if var e = editing, let idx = store.weightLogs.firstIndex(where: { $0.id == e.id }) {
                            e.kg = v
                            store.weightLogs[idx] = e
                            UricCelebrate.show("改好了")
                        } else {
                            store.weightLogs.append(WeightLog(date: Date(), kg: v))
                            UricCelebrate.show("记好了。减重是降尿酸最有效的生活方式干预。")
                        }
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            } header: {
                Text(editing == nil ? "这次体重（kg）" : "改体重")
            } footer: {
                Text("减重是降尿酸最有效的生活方式干预（每减 5kg，尿酸平均降约 1）。每周一次就够。")
            }
        }
        .navigationTitle(editing == nil ? "体重" : "改体重")
        .onAppear { if let e = editing { kgText = String(format: "%.1f", e.kg) } }
    }
}
