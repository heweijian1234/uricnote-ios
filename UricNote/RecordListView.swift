import SwiftUI
import Charts

// MARK: - Tab2 记录 v11（A9 本体唯一原则：每个类目=一个完整本体页：记一次+趋势+历史可改可删）
// A10：急性发作模式已取消（健哥裁）。仪表盘按钮=快捷入口直达本体页，不另做界面。

struct RecordListView: View {
    @ObservedObject var store = Store.shared

    /// 测试入口开关（2026-11-26 健哥令：手工攒 90 天太慢）。
    /// 🔴 上架前把 TestFlags.enabled 改成 false，入口即消失、Pro 强制解锁同时失效。
    /// 注意不能用 #if DEBUG —— CI 出的是 Release 包，DEBUG 块在 TestFlight 里不存在。
    private let showsTestTools = TestFlags.enabled

    var body: some View {
        NavigationView {
            List {
                Section(L("Body", "身体")) {
                    // 健哥11-23令⑧：健康档案入口在记录页身体区
                    NavigationLink { HealthProfileEditor() } label: {
                        Label(L("Health profile", "健康档案"), systemImage: "person.text.rectangle")
                    }
                    NavigationLink { FlarePage() } label: {
                        Label(L("Flare records", "发作记录"), systemImage: "exclamationmark.triangle.fill").foregroundColor(.danger)
                    }
                    NavigationLink { UricReadingPage() } label: {
                        Label(L("Uric acid lab values", "尿酸化验值"), systemImage: "list.clipboard")
                    }
                    NavigationLink { WeightPage() } label: {
                        Label(L("Weight", "体重"), systemImage: "scalemass").foregroundColor(.success)
                    }
                }
                Section(L("Lifestyle", "生活方式")) {
                    NavigationLink { WaterPage() } label: {
                        Label(L("Water & urine color", "饮水与尿色"), systemImage: "drop.fill").foregroundColor(.water)
                    }
                    NavigationLink { FoodPage() } label: {
                        Label(L("Food (high-purine log)", "饮食（高嘌呤登记）"), systemImage: "fork.knife").foregroundColor(.warn)
                    }
                    NavigationLink { SleepPage() } label: {
                        Label(L("Sleep time", "入睡时间"), systemImage: "moon.fill").foregroundColor(.brand)
                    }
                    // 健哥11-23令⑨：身体节律（房事/自慰频率——痛风诱因记录，隐私最小化）
                    NavigationLink { RhythmPage() } label: {
                        Label(L("Body rhythm (private)", "身体节律（私密）"), systemImage: "waveform.path.ecg").foregroundColor(.pink)
                    }
                }
                Section(L("Medication", "用药")) {
                    NavigationLink { MedTodayView() } label: {
                        Label(L("Current medication & dose", "当前使用药物药量"), systemImage: "pills").foregroundColor(.brand)
                    }
                }
                if showsTestTools {
                    Section(L("Testing", "测试")) {
                        NavigationLink { TestDataView() } label: {
                            Label(L("Generate test data", "生成测试数据"), systemImage: "wand.and.stars")
                                .foregroundColor(.brand)
                        }
                    }
                }
                #if DEBUG
                Section(L("Testing", "测试")) {
                    ResetDataButton()
                }
                #endif
            }
            .navigationTitle(L("Records", "记录"))
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
            Label(L("Reset all data (testing)", "重置所有数据（测试用）"), systemImage: "trash")
        }
        .alert(L("Erase all records?", "确定要清空全部记录吗？"), isPresented: $confirm1) {
            Button(L("Cancel", "取消"), role: .cancel) {}
            Button(L("Continue", "继续"), role: .destructive) { confirm2 = true }
        } message: {
            Text(L("All flares / labs / water / food / profile data will be permanently deleted.", "所有发作/化验/饮水/饮食/档案数据将永久删除，不可恢复。"))
        }
        .alert(L("Final confirmation", "最后确认"), isPresented: $confirm2) {
            TextField(L("Type RESET to confirm", "输入 RESET 确认"), text: $inputText)
            Button(L("Cancel", "取消"), role: .cancel) { inputText = "" }
            Button(L("Execute reset", "执行重置"), role: .destructive) {
                if inputText == "RESET" {
                    store.resetAllData()
                }
                inputText = ""
            }
        } message: {
            Text(L("Type RESET (all caps) to execute.", "输入 RESET（全大写）执行。"))
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
                    Label(L("Log a flare (3 sec)", "记一次发作（3 秒）"), systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold)).foregroundColor(.brand)
                }
            }
            Section(L("Flare history (tap to edit, swipe to delete)", "发作历史（点一条可改，左滑删除）")) {
                if store.flares.isEmpty {
                    Text(L("No flare records yet", "还没有发作记录")).font(.callout).foregroundColor(.secondary)
                }
                ForEach(store.flares.sorted { $0.startDate > $1.startDate }) { f in
                    NavigationLink { FlareEditorView(editing: f) } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dateText(f.startDate) + " · " + f.joints.joined(separator: "/"))
                                .font(.body.weight(.medium))
                            Text(L("Peak \(f.painPeak)/10 · \(f.canWalk ? "can walk" : "can't walk")", "疼痛峰值 \(f.painPeak)/10 · \(f.canWalk ? "能走" : "不能走")"))
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
        .navigationTitle(L("Flare records", "发作记录"))
    }

    private func dateText(_ d: Date) -> String {
        let df = DateFormatter(); df.dateFormat = L("MMM d", "M月d日")
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

    private let jointOptions = [L("Toes", "脚趾"), L("Ankles", "脚踝"), L("Heels", "脚跟"), L("Knees", "膝盖"), L("Fingers", "手指"), L("Wrists", "手腕"), L("Elbows", "手肘"), L("Foot top", "足背"), L("Other", "其他")]
    // A7：1-10 文字锚点（美国诊所 NRS 量表的语感补充）
    private let painAnchors = [
        1: L("Barely noticeable", "几乎注意不到"), 2: L("A bit uncomfortable", "有点不舒服"), 3: L("Painful, but functional", "疼，但不影响做事"), 4: L("Painful, getting attention", "疼，开始在意"),
        5: L("Clearly painful", "明显疼"), 6: L("Quite painful", "挺疼的"), 7: L("Very painful, affects walking", "很痛，影响走路"), 8: L("Very painful, hard to walk", "很痛，走路困难"),
        9: L("Excruciating — bed-bound", "剧痛，只想躺着"), 10: L("Worst pain ever — ER level", "最剧烈的疼，想去急诊"),
    ]
    private let impactOptions = [L("Slightly", "轻微"), L("Noticeably", "明显"), L("Can't work", "无法")]

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
            Section(L("Where does it hurt? (multi-select)", "哪个部位痛？（可多选）")) {
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
                        Text(pain == 0 ? L("Pain level: drag to select", "疼痛程度：拖一下选") : L("Pain \(Int(pain))/10 — \(painAnchors[Int(pain)] ?? "")", "疼痛程度：\(Int(pain))/10 —— \(painAnchors[Int(pain)] ?? "")"))
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
                        Text(L("1 = barely noticeable · 7 = painful, hard to walk · 10 = ER-level pain", "1=几乎注意不到 · 7=很痛影响走路 · 10=想去急诊"))
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
                Toggle(L("Can you still walk", "还能走路吗"), isOn: $canWalk)
                // v11.1 #7：删"今天吃过药吗"（药打卡已独立成仪表盘待办行，不再重复采集）
            } header: {
                Text(L("Just two things, 3 seconds to log", "就这两件，3 秒记完"))
            }
            Section(L("Only for bad flares (painkillers)", "很痛才看这里（止痛药）")) {
                Toggle(L("Took a painkiller", "用了止痛药"), isOn: $showPainkiller)
                if showPainkiller {
                    Toggle(L("Did you just take it", "刚才吃了吗"), isOn: $tookPainkiller)
                    TextField(L("Painkiller name (saved once, e.g. ibuprofen)", "止痛药名（记一次固定，如：布洛芬）"), text: $painkillerName)
                }
            }
            Section {
                Toggle(L("Does it affect work", "对工作有影响吗"), isOn: $showWorkImpact)
                if showWorkImpact {
                    // D1 修复：影响程度独立变量，不再污染诱因备注
                    Picker(L("Impact level", "影响程度"), selection: $workImpactNote) {
                        ForEach(impactOptions, id: \.self) { Text($0).tag($0) }
                    }
                }
                TextField(L("Trigger note (e.g. beer last night)", "诱因备注（比如：昨晚喝了啤酒）"), text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text(L("Optional: after the flare ends", "可选：发作结束后补"))
            }
            Section {
                Button(editing == nil ? L("Save", "保存") : L("Save changes", "保存修改")) {
                    save()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .disabled(pain == 0 || joints.isEmpty)
            } footer: {
                Text(L("Nighttime flare risk is 2.4× daytime — this entry is designed for use while in pain.", "夜间发作风险是白天 2.4 倍——这个入口按「痛醒状态也能用」设计。"))
            }
            // 健哥11-23令⑤：最下方显示今天已记录的历史（发作/喝水/饮食/昨晚入睡）
            Section(L("Today's records", "今天的记录历史")) {
                let todaysFlares = store.flares.filter { Calendar.current.isDate($0.startDate, inSameDayAs: Date()) }
                if todaysFlares.isEmpty {
                    Text(L("No flares logged today", "今天暂无发作记录")).font(.caption).foregroundColor(.secondary)
                } else {
                    ForEach(todaysFlares) { f in
                        HStack {
                            Text(f.joints.joined(separator: "/")).font(.caption)
                            Spacer()
                            Text(L("peak \(f.painPeak)/10", "峰值\(f.painPeak)/10")).font(.caption).foregroundColor(.danger)
                        }
                    }
                }
                if let w = store.waterDays.first(where: { Calendar.current.isDate($0.day, inSameDayAs: Date()) }) {
                    HStack { Text(L("Water", "喝水")).font(.caption); Spacer(); Text("\(w.totalMl) ml").font(.caption).foregroundColor(.secondary) }
                }
                if let f2 = store.foodDays.first(where: { Calendar.current.isDate($0.day, inSameDayAs: Date()) }) {
                    HStack { Text(L("Diet", "饮食")).font(.caption); Spacer(); Text(f2.noTriggerToday ? L("clean ✓", "未碰 ✓") : L("\(f2.items.count + f2.scenes.count) items", "\(f2.items.count + f2.scenes.count) 项")).font(.caption).foregroundColor(.secondary) }
                }
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
                if let s2 = store.sleepLogs.first(where: { Calendar.current.isDate($0.night, inSameDayAs: yesterday) }) {
                    HStack { Text(L("Sleep (last night)", "入睡（昨晚）")).font(.caption); Spacer(); Text(["<23", "23-24", "0-1", ">1"][min(s2.bucket, 3)]).font(.caption).foregroundColor(.secondary) }
                }
            }
        }
        .navigationTitle(editing == nil ? L("Log flare", "记发作") : L("Edit flare record", "改发作记录"))
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
            UricCelebrate.show(L("Saved", "改好了"))
        } else {
            let f = Flare(startDate: Date(), endDate: nil, joints: Array(joints), painPeak: Int(pain),
                          canWalk: canWalk, workImpact: showWorkImpact ? impactIdx : 0,
                          workImpactNote: showWorkImpact && !workImpactNote.isEmpty ? workImpactNote : nil,
                          tookMedsToday: nil,   // v11.1：药打卡独立成仪表盘待办，发作页不再采集
                          tookPainkiller: showPainkiller ? tookPainkiller : nil,
                          painkillerName: showPainkiller && !painkillerName.isEmpty ? painkillerName : nil,
                          triggerNotes: notes.isEmpty ? nil : notes)
            store.flares.append(f)
            UricCelebrate.show(L("Logged. Rest well tonight — it's all written down, you don't have to hold it in your head.", "记下了。今晚好好休息，这里都帮你记着，你不用惦记。"))
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
                    Label(L("Log a lab value", "记一次化验值"), systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold)).foregroundColor(.brand)
                }
            }
            // A5：趋势折线图（Swift Charts，iOS16；免费功能——给自己看的）
            if store.readings.count >= 2 {
                Section(L("Trends", "趋势")) {
                    UricTrendChart()
                        .frame(height: 180)
                }
            }
            Section(L("History (tap to edit, swipe to delete)", "历史（点一条可改，左滑删除）")) {
                if store.readings.isEmpty {
                    Text(L("No lab records yet", "还没有化验记录")).font(.callout).foregroundColor(.secondary)
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
                                Text(r.atTarget ? L("At target ✓", "达标 ✓") : L("Above target", "未达标"))
                                    .font(.caption)
                                    .foregroundColor(r.atTarget ? .green : .amber)
                            }
                            HStack(spacing: 8) {
                                Text(r.date.formatted(date: .abbreviated, time: .omitted))
                                Text(r.source == "home" ? L("home test", "家测") : L("Hospital lab", "医院化验"))
                                if let cr = r.creatinineMgDl {
                                    Text(L("Creatinine \(String(format: "%.1f", cr)) mg/dL", "肌酐 \(String(format: "%.1f", cr)) mg/dL"))
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
        .navigationTitle(L("Uric acid lab values", "尿酸化验值"))
        .toolbar {
            NavigationLink(L("Adjust interval", "调间隔")) { ReviewIntervalEditor() }
        }
    }
}

// A5：趋势折线（双单位自适应；目标线 6.0/360）
struct UricTrendChart: View {
    @ObservedObject var store = Store.shared
    /// nil = 全部历史；传天数则只看最近 N 天（Pro 锁用）
    var limitDays: Int? = nil

    private var visibleReadings: [UricReading] {
        let all = store.readings.sorted { $0.date < $1.date }
        guard let days = limitDays else { return all }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return all.filter { $0.date >= cutoff }
    }

    var body: some View {
        let data = visibleReadings
        Chart {
            ForEach(data, id: \.id) { r in
                LineMark(x: .value(L("Date", "日期"), r.date),
                         y: .value(L("Uric acid", "尿酸"), store.meta.unitIsUmol ? r.urateUnit : r.valueMgDl))
                PointMark(x: .value(L("Date", "日期"), r.date),
                          y: .value(L("Uric acid", "尿酸"), store.meta.unitIsUmol ? r.urateUnit : r.valueMgDl))
            }
            RuleMark(y: .value(L("Target", "目标"), store.meta.unitIsUmol ? 360.0 : 6.0))
                .foregroundStyle(Color.green.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
        }
        .chartYAxis {
            AxisMarks(position: .trailing)
        }
        .accessibilityLabel(L("Uric acid trend chart", "尿酸趋势图"))
    }
}

// A5：复查间隔可调（4/6/8/12 周）
struct ReviewIntervalEditor: View {
    @ObservedObject var store = Store.shared
    @State private var customDate = Date()

    private let presets = [4, 6, 8, 12]

    /// 0 = 不记录；4/6/8/12 = 按周推算；-1 = 自定义日期
    private var mode: Int { store.review.intervalWeeks }

    var body: some View {
        Form {
            Section {
                choiceRow(L("Not tracked", "不记录"), 0)
                ForEach(presets, id: \.self) { w in
                    choiceRow(L("Every \(w) weeks", "每 \(w) 周"), w)
                }
                choiceRow(L("Custom date", "自定义日期"), -1)
            } header: {
                Text(L("Recheck rhythm", "复查节律"))
            } footer: {
                Text(L("This drives the countdown on your dashboard. Choose \"Not tracked\" to hide it.", "这个设置决定仪表盘的复查倒计时。选「不记录」则不显示。"))
            }

            if mode == -1 {
                Section {
                    DatePicker(L("Next recheck", "下次复查"),
                               selection: $customDate,
                               displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .onChange(of: customDate) { newValue in
                            // 2026-11-25：自定义日期保存到下一次复查（不回填 intervalWeeks）
                            store.review.nextReviewDate = Calendar.current.startOfDay(for: newValue)
                            store.save()
                        }
                } footer: {
                    Text(L("Pick any date — holidays, a doctor's schedule, whatever fits.", "可以选任意日期——避开节假日、跟着医生的排班，都行。"))
                }
            }
        }
        .navigationTitle(L("Recheck rhythm", "复查节律"))
        .onAppear {
            customDate = store.review.nextReviewDate
                ?? Calendar.current.date(byAdding: .weekOfYear, value: 8, to: Date())!
        }
    }

    private func choiceRow(_ title: String, _ value: Int) -> some View {
        Button {
            store.review.intervalWeeks = value
            switch value {
            case 0:
                store.review.nextReviewDate = nil
            case -1:
                store.review.nextReviewDate = Calendar.current.startOfDay(for: customDate)
            default:
                // 2026-11-25：不再要求「先有化验值」——选了间隔就立刻排出下次复查，
                // 否则仪表盘倒计时永远是「—」（健哥反馈的实际 bug）
                store.review.nextReviewDate = Calendar.current.date(byAdding: .weekOfYear, value: value, to: Date())
            }
            store.save()
        } label: {
            HStack {
                Text(title).foregroundColor(.primary)
                Spacer()
                if mode == value {
                    Image(systemName: "checkmark").foregroundColor(.brand)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 化验值编辑器（C12 肌酐 + A4 编辑 + 联动复查日）

struct UricReadingEditor: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss
    var editing: UricReading? = nil

    @State private var valueText = ""
    @State private var weightText = ""       // 健哥11-21令：数值与肌酐中间的体重行（顺手记，进weightLogs）
    @State private var creatinineText = ""   // C12：可选
    @State private var source = "lab"

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField(L("Value", "数值"), text: $valueText).keyboardType(.decimalPad)
                    Text(store.meta.unitIsUmol ? "µmol/L" : "mg/dL").foregroundColor(.secondary)
                }
                HStack {
                    TextField(L("Weight (optional)", "体重（可选）"), text: $weightText).keyboardType(.decimalPad)
                    Text("kg").foregroundColor(.secondary)
                }
                HStack {
                    TextField(L("Creatinine (optional)", "肌酐（可选）"), text: $creatinineText).keyboardType(.decimalPad)
                    Text("mg/dL").foregroundColor(.secondary)
                }
                Picker(L("Source", "来源"), selection: $source) {
                    Text(L("Hospital lab", "医院化验")).tag("lab")
                    Text(L("Home test", "家里自测")).tag("home")
                }
                .pickerStyle(.segmented)
            } header: {
                Text(editing == nil ? L("Most recent uric acid", "最近一次尿酸值") : L("Edit lab value", "修改化验值"))
            } footer: {
                Text(L("Creatinine guides urate-lowering drug choice — fill it in if it's on your lab report. Next recheck is auto-scheduled (default 8 weeks, adjustable).", "肌酐是降酸药选择依据（苯溴马隆肾功能禁忌/别嘌醇按肾功能调量）——报告单上有就顺手填。录完自动排复查日（默认 8 周，可调）。"))
            }
            Button(editing == nil ? L("Save", "保存") : L("Save changes", "保存修改")) {
                save()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle(editing == nil ? L("Log lab value", "记化验值") : L("Edit lab value", "改化验值"))
        .onAppear { if let e = editing { load(e) } }
    }

    private func load(_ e: UricReading) {
        valueText = store.meta.unitIsUmol ? String(format: "%.0f", e.urateUnit) : String(format: "%.1f", e.valueMgDl)
        creatinineText = e.creatinineMgDl.map { String(format: "%.1f", $0) } ?? ""
        weightText = store.weightLogs.last.map { String(format: "%.1f", $0.kg) } ?? ""
        source = e.source
    }

    private func save() {
        guard let v = Double(valueText), v > 0 else { return }
        let mgDl = store.meta.unitIsUmol ? v / 59.48 : v
        let cr = Double(creatinineText)
        // 健哥11-21令：体重行联动（填了顺手进weightLogs，趋势页体重线直接受益）
        // 🔴11-22健哥报障加固：同日已有记录先移除（防同日多条叠加看着"没互通/重复"）
        if let w = Double(weightText), w > 0 {
            // 同日只保留最新一条：删今天的再插（防多条叠加）
            store.weightLogs.removeAll { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
            store.weightLogs.append(WeightLog(date: Date(), kg: w))
            store.save()   // 显式落盘
        }
        if var e = editing, let idx = store.readings.firstIndex(where: { $0.id == e.id }) {
            e.valueMgDl = mgDl; e.creatinineMgDl = cr; e.source = source
            store.readings[idx] = e
            UricCelebrate.show(L("Saved", "改好了"))
        } else {
            let r = UricReading(date: Date(), valueMgDl: mgDl, creatinineMgDl: cr, source: source)
            store.readings.append(r)
            store.review.nextReviewDate = Calendar.current.date(byAdding: .weekOfYear, value: store.review.intervalWeeks, to: Date())
            if r.atTarget {
                UricCelebrate.show(L("At target. Crystals are quietly dissolving.", "达标了。结晶正在悄悄溶解。"))
            } else {
                UricCelebrate.show(L("Logged. Recheck scheduled.", "记好了。复查日已排上。"))
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
            // 健哥11-21令：沿用上周平均上移第一排（标题下方）
            Section {
                Toggle(L("Auto-fill weekly average (skip daily logging)", "沿用上周平均（不想每天记时用）"), isOn: Binding(
                    get: { store.meta.waterAutoFillActive },
                    set: { on in on ? store.enableWaterAutoFill() : store.disableWaterAutoFill() }
                ))
            } footer: {
                Text(L("Days you don't log are auto-filled from your 7-day average, marked as 'auto-filled'. Turn off anytime.", "开启后，没手记的日子自动按最近 7 天平均填，报告标「沿用」不算打卡。随时可关，关掉后恢复手记。"))
            }
            Section(L("Today", "今天")) {
                if let w = store.todayWater {
                    if w.provenance == .estimated {
                        // A3：沿用日诚实标记
                        HStack {
                            Image(systemName: "sparkles").foregroundColor(.brand)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("Today auto-filled from last week's average (\(w.totalMl)ml)", "今天按上周平均沿用（\(w.totalMl)ml）")).font(.callout.weight(.medium))
                                Text(L("Doesn't count as a logged day; turn auto-fill off in settings to log manually again", "不算连续打卡；想重新手记就在设置里关掉沿用")).font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(L("Re-log", "重记")) {
                                if let i = store.waterDays.firstIndex(where: { $0.id == w.id }) {
                                    store.waterDays[i].cups = []
                                    store.waterDays[i].provenance = .recorded
                                    store.save()   // 🔴显式落盘
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
                                Text(L("Today \(w.totalMl) ml", "今日 \(w.totalMl) ml")).font(.title3.bold()).foregroundColor(.water)
                                Text(L("\(w.cups.count) cups · goal \(w.goalMl) ml", "\(w.cups.count) 杯 · 目标 \(w.goalMl) ml")).font(.caption).foregroundColor(.secondary)
                                // v11.1 #11：每杯容量提前到记一杯下方（就近原则）
                                Stepper(L("\(w.cupSizeMl) ml per cup (adjustable)", "每杯 \(w.cupSizeMl) ml（容器不一可改）"), value: Binding(
                                    get: { store.todayWater?.cupSizeMl ?? 250 },
                                    set: { v in if let i = store.waterDays.firstIndex(where: { Calendar.current.isDate($0.day, inSameDayAs: Date()) }) { store.waterDays[i].cupSizeMl = v; store.save() } }
                                ), in: 100...800, step: 50)
                                .font(.caption)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        Button { addCup() } label: {
                            Label(L("Log a cup", "记一杯"), systemImage: "plus.circle.fill")
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
                                    Button(L("Delete", "删"), role: .destructive) { removeCup(c) }
                                }
                            }
                        }
                    }
                }
            }
            Section {
                urinePicker(L("AM", "早"), slot: 0)
                urinePicker(L("Noon", "午"), slot: 1)
                urinePicker(L("PM", "晚"), slot: 2)
            } header: {
                Text(L("Urine color (hydration signal, AM/noon/PM)", "尿色自评（脱水信号，早午晚）"))
            } footer: {
                Text(L("Unlogged slots stay empty — no guessing.", "没记的时段就空着——不猜。"))
            }
        }
        .navigationTitle(L("Water & urine color", "饮水与尿色"))
        .onAppear {
            // A2：满 7 天实测后问一次（只问一次）
            if store.meta.waterAutoFillAsked && !store.meta.waterAutoFillActive && !UserDefaults.standard.bool(forKey: "ur.waterAskShown") {
                showAutoFillAsk = true
                UserDefaults.standard.set(true, forKey: "ur.waterAskShown")
            }
        }
        .alert(L("7 days of manual logging", "已经手记 7 天了"), isPresented: $showAutoFillAsk) {
            Button(L("Auto-fill weekly average", "沿用上周平均")) { store.enableWaterAutoFill() }
            Button(L("Keep manual logging", "继续手记"), role: .cancel) {}
        } message: {
            Text(L("Switch to auto-fill from last week's average — one less thing. Turn off anytime.", "可以改成自动按上周平均填，不想记的时候少一件事。随时可关。"))
        }
    }

    @ViewBuilder
    private func urinePicker(_ label: String, slot slotIndex: Int) -> some View {
        Picker(label, selection: Binding(
            get: { urineValue(slotIndex) ?? 0 },
            set: { v in setUrine(slotIndex, v == 0 ? nil : v) }
        )) {
            Text(L("Not logged", "未记")).tag(0)
            Text(L("Pale yellow (good)", "浅黄（好）")).tag(2)
            Text(L("Normal", "正常")).tag(3)
            Text(L("Dark", "偏深")).tag(5)
            Text(L("Very dark (dehydrated)", "很深（脱水）")).tag(7)
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
            store.save()   // 🔴内层修改不触发didSet——显式落盘
            Haptic.tap()
            let total = store.waterDays[i].totalMl
            if wasBelowGoal && total >= store.waterDays[i].goalMl {
                // v11.1：达标庆祝只弹一次（防重复键）
                let df = DateFormatter(); df.dateFormat = "yyyyMMdd"
                let key = "ur.waterGoalToasted_" + df.string(from: Date())
                if !UserDefaults.standard.bool(forKey: key) {
                    UserDefaults.standard.set(true, forKey: key)
                    Haptic.success()
                    UricCelebrate.show(L("Water goal met today 🎉 Water is the cheapest medicine", "今日喝水达标 🎉 水是最便宜的药"))
                }
            } else {
                UricCelebrate.show(L("Cup #\(store.waterDays[i].cups.count) · \(total) ml today", "第 \(store.waterDays[i].cups.count) 杯 · 今日 \(total) ml"))
            }
        }
    }

    private func removeCup(_ c: WaterCup) {
        if let i = store.waterDays.firstIndex(where: { Calendar.current.isDate($0.day, inSameDayAs: Date()) }) {
            store.waterDays[i].cups.removeAll { $0.id == c.id }
            store.save()   // 🔴显式落盘
        }
    }

    private func setUrine(_ slotIndex: Int, _ v: Int?) {
        let today = Calendar.current.startOfDay(for: Date())
        if let i = store.waterDays.firstIndex(where: { Calendar.current.isDate($0.day, inSameDayAs: today) }) {
            switch slotIndex {
            case 0: store.waterDays[i].urine.morning = v; store.save()   // 🔴显式落盘
            case 1: store.waterDays[i].urine.noon = v; store.save()
            default: store.waterDays[i].urine.evening = v; store.save()   // 🔴显式落盘
            }
        }
    }
}

// MARK: - 饮食本体页（B3 重做：红区多选+场景+负面记录+自定义；不分早午晚）

struct FoodPage: View {
    @ObservedObject var store = Store.shared
    @State private var custom = ""
    @State private var showDailyFoodPicker = false   // 健哥11-21令：添加日常食物（进库选择）
    @State private var showSceneEditor = false       // 健哥11-21令：自定义场景管理

    var body: some View {
        List {
            if let f = store.todayFood {
                Section(L("Today", "今天")) {
                    if f.noTriggerToday {
                        Label(L("Logged: no high-purine today ✓", "已记：今天没碰高嘌呤 ✓"), systemImage: "checkmark.seal.fill").foregroundColor(.success)
                    } else if !f.items.isEmpty || !f.scenes.isEmpty {
                        Text(L("Logged: ", "已记：") + (f.scenes + f.items).map(foodDisplayName).joined(separator: "、"))
                            .font(.callout)
                    }
                }
            }
            // 健哥11-21令5：做大做显眼+字居中
            Section {
                Button {
                    markNoTrigger()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 34))
                        Text(L("No high-purine food today", "今天没吃高嘌呤"))
                            .font(.title3.bold())
                        Text(L("Log it ✓", "记一笔 ✓"))
                            .font(.callout)
                    }
                    .foregroundColor(.success)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            } header: {
                Text(L("No high-purine food today? (Logging 'none' matters too)", "今天没碰高嘌呤？（负面记录很重要）"))
            } footer: {
                Text(L("Logging only 'ate' skews the ranking — clean days are data too.", "只记「吃了」会让排行虚高——没吃的日子也是数据。"))
            }
            // 健哥11-21令6：自定义日常饮食表（用户自己建的——看到的都是平常真吃的）
            Section {
                if store.meta.dailyFoods.isEmpty {
                    Text(L("Your daily food list is empty", "还没建立你的日常饮食表"))
                        .font(.callout).foregroundColor(.secondary)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                        ForEach(store.meta.dailyFoods, id: \.self) { name in
                            FoodChip(
                                name: foodDisplayName(name),
                                selected: store.todayFood?.items.contains(name) == true,
                                tint: .danger
                            ) { toggle(name) }
                        }
                    }
                    .padding(.vertical, 4)
                    // 健哥11-21晚令12：戒了的能删（左滑删同款——管理入口里删，日常区不放破坏性手势）
                    Text(L("To remove an item: open 'Add daily foods' below and uncheck it (keep only what you actually eat)", "要删除某项：点下方「添加日常食物」进管理页删除（戒了的就删掉，表只留真在吃的）"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                // 健哥11-21令5：添加日常食物入口（下方）
                Button {
                    showDailyFoodPicker = true
                } label: {
                    Label(L("Add daily foods", "添加日常食物"), systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } header: {
                Text(L("My daily food list (tap what you had today)", "我的日常饮食表（点选今天碰过的）"))
            } footer: {
                Text(L("Everyone eats differently — pick your everyday foods from the library to build your own list; swipe to remove later.", "每个人的饮食差别很大——从嘌呤食物库选择你平常吃到的，建成自己的表；日后可左滑删除。"))
            }
            // 健哥11-21令7：场景自定义（用户自建+其他兜底）
            Section {
                ForEach(store.meta.customScenes, id: \.self) { name in
                    Button {
                        addScene(name, auto: FoodLibrary.scenes.first(where: { $0.name == name })?.autoItems ?? [])
                    } label: {
                        HStack {
                            Text(foodDisplayName(name)).foregroundColor(.primary)
                            Spacer()
                            if store.todayFood?.scenes.contains(name) == true {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.danger)
                            }
                        }
                    }
                }
                .onDelete { store.meta.customScenes.remove(atOffsets: $0) }
                // 其他（自定义）兜底
                HStack {
                    TextField(L("Other (custom scene/food)", "其他（自定义场景/食物）"), text: $custom)
                    Button(L("Log", "记")) { if !custom.isEmpty { Haptic.tap(); toggle(custom); custom = "" } }
                }
                Button {
                    showSceneEditor = true
                } label: {
                    Label(L("Manage scenes (from library)", "管理场景（从食物库选择）"), systemImage: "square.grid.2x2")
                        .font(.callout)
                }
            } header: {
                Text(L("Was today a whole occasion?", "今天吃的是一整场？"))
            } footer: {
                Text(L("Build scenes from the food library to match your own life.", "场景从嘌呤食物库选择建立，贴合你自己的生活方式。"))
            }
        }
        .navigationTitle(L("Food", "饮食"))
        .sheet(isPresented: $showDailyFoodPicker) {
            DailyFoodPickerSheet()
        }
        .sheet(isPresented: $showSceneEditor) {
            ScenePickerSheet()
        }
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
        store.save()   // 🔴内层修改不触发didSet——显式落盘
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
            UricCelebrate.show(L("Logged. One slip is fine — knowing your pattern is what matters.", "记了。偶尔一次没关系，知道规律才重要。"))
        }
        store.save()   // 🔴显式落盘
    }

    private func markNoTrigger() {
        let i = ensureToday()
        store.foodDays[i].noTriggerToday = true
        store.foodDays[i].items = []
        store.foodDays[i].scenes = []
        store.save()   // 🔴显式落盘
        UricCelebrate.show(L("Logged — this day is data too", "记了——这一天也是数据"))
    }
}

// MARK: - 入睡历史页（B2）

struct SleepPage: View {
    @ObservedObject var store = Store.shared

    private var avgBucket: String {
        let recent = store.sleepLogs.sorted { $0.night < $1.night }.suffix(14)
        guard !recent.isEmpty else { return "—" }
        let avg = Double(recent.map { $0.bucket }.reduce(0, +)) / Double(recent.count)
        let idx = Int(avg.rounded())
        return [L("before 11 PM", "23点前"), L("11 PM–12 AM", "23-24点"), L("12–1 AM", "0-1点"), L("after 1 AM", "1点后")][min(idx, 3)]
    }

    var body: some View {
        List {
            Section {
                NavigationLink { SleepQuickPicker() } label: {
                    Label(L("Log last night's bedtime (quick pick)", "记昨晚入睡（快捷四档）"), systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold)).foregroundColor(.brand)
                }
            }
            Section {
                Text(L("14-day average: \(avgBucket)", "近 14 天平均：\(avgBucket)")).font(.callout)
            }
            Section(L("History (swipe to delete)", "历史（左滑删除）")) {
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
        .navigationTitle(L("Sleep time", "入睡时间"))
    }
}

// MARK: - 体重本体页（A4 可改可删）

struct WeightPage: View {
    @ObservedObject var store = Store.shared

    var body: some View {
        List {
            Section {
                NavigationLink { WeightEditor() } label: {
                    Label(L("Log weight", "记一次体重"), systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold)).foregroundColor(.brand)
                }
            }
            Section(L("History (tap to edit, swipe to delete)", "历史（点一条可改，左滑删除）")) {
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
        .navigationTitle(L("Weight", "体重"))
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
                    TextField(L("e.g. 88.5", "例如 88.5"), text: $kgText).keyboardType(.decimalPad)
                    Text("kg").foregroundColor(.secondary)
                }
                Button(editing == nil ? L("Save", "保存") : L("Save changes", "保存修改")) {
                    if let v = Double(kgText), v > 0 {
                        if var e = editing, let idx = store.weightLogs.firstIndex(where: { $0.id == e.id }) {
                            e.kg = v
                            store.weightLogs[idx] = e
                            UricCelebrate.show(L("Saved", "改好了"))
                        } else {
                            store.weightLogs.append(WeightLog(date: Date(), kg: v))
                            UricCelebrate.show(L("Logged. Weight loss is the most effective lifestyle change for uric acid.", "记好了。减重是降尿酸最有效的生活方式干预。"))
                        }
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            } header: {
                Text(editing == nil ? L("Weight this time (kg)", "这次体重（kg）") : L("Edit weight", "改体重"))
            } footer: {
                Text(L("Weight loss is the most effective lifestyle change for uric acid (about 1 point lower per 5kg lost). Once a week is enough.", "减重是降尿酸最有效的生活方式干预（每减 5kg，尿酸平均降约 1）。每周一次就够。"))
            }
        }
        .navigationTitle(editing == nil ? L("Weight", "体重") : L("Edit weight", "改体重"))
        .onAppear { if let e = editing { kgText = String(format: "%.1f", e.kg) } }
    }
}


// MARK: - 日常食物管理页（健哥11-21晚令12重做：适量+注意两列·带分类·内容与嘌呤食物库一致·可删）
// 数据源=PurineDatabase（与了解页嘌呤食物库同一份——永久一致）

struct DailyFoodPickerSheet: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss
    @State private var query = ""
    @State private var category = "全部"
    @State private var tab = 1   // 0=适量 1=注意（默认注意——健哥令仅这两列）

    static let categories = ["全部", "蔬菜", "水果", "肉类", "海鲜", "酒类", "饮料", "奶茶", "茶叶", "咖啡", "坚果", "零食", "面包", "汤类", "饮食场景", "其他"]   // 🔴中文常量做key（inferredCategory返回中文）——显示层用catName()包L

    /// 候选=嘌呤食物库的适量+注意（yellow+red）——与库完全一致
    private var candidates: [PurineItem] {
        if store.purineItems.isEmpty { store.purineItems = PurineDatabase.seed }
        let levelKey = ["yellow", "red"][tab]
        let byQuery = store.purineItems.filter { query.isEmpty || (($0.name + " " + ($0.nameEn ?? "")).localizedCaseInsensitiveContains(query)) }
        let byCategory = category == "全部" ? byQuery : byQuery.filter { $0.inferredCategory == category }
        return byCategory.filter { $0.level == levelKey }.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("", selection: $tab) {
                        Text(L("Moderate", "适量")).tag(0)
                        Text(L("Caution", "注意")).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                        ForEach(Self.categories, id: \.self) { c in
                            Button {
                                category = c
                            } label: {
                                Text(catName(c))
                                    .font(.caption.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(category == c ? Color.brand : Color.gray.opacity(0.12))
                                    .foregroundColor(category == c ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.borderless)   // 🔴List行内多Button必须borderless（同库页根因）
                        }
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text(L("Manage daily foods (checked = in your list)", "管理日常食物（勾选=在表里）"))
                } footer: {
                    Text(L("Same content as the purine food library. Uncheck to remove from your daily list (delete what you've quit).", "与嘌呤食物库内容一致。取消勾选=从日常饮食表删除（戒了的就删掉）。"))
                }

                ForEach(candidates) { item in
                    Button {
                        if store.meta.dailyFoods.contains(item.name) {
                            store.meta.dailyFoods.removeAll { $0 == item.name }
                        } else {
                            store.meta.dailyFoods.append(item.name)
                        }
                        store.save()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.displayName).foregroundColor(.primary)
                                // 健哥11-22令2：小字三色——注意=红 适量=黄
                                Text(L("Purine ~\(Int(item.uricPer100g)) mg/100g · \(item.level == "red" ? "Caution" : "Moderate") · \(item.displaySource)", "嘌呤约 \(Int(item.uricPer100g)) mg/100g · \(item.level == "red" ? "注意" : "适量") · \(item.displaySource)"))
                                    .font(.caption2)
                                    .foregroundColor(item.level == "red" ? .danger : .warn)
                            }
                            Spacer()
                            if store.meta.dailyFoods.contains(item.name) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.brand)
                            }
                        }
                        // 健哥11-25令：整行可点。原来只有左侧文字能点中——
                        // Spacer 是透明的，不参与命中测试，右侧大片空白等于死区
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            // 2026-11-26：搜索框常驻显示（原默认行为要下拉才露出，等于看不见）
            .searchable(text: $query,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: L("Search foods", "搜食物"))
            .navigationTitle(L("Manage daily foods", "管理日常食物"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Done", "完成")) { dismiss() }
                }
            }
        }
    }
}

// MARK: - 场景管理页（健哥11-21晚令12重做：=嘌呤食物库的饮食场景类·与库一致·可删）
// 场景源=种子库中 inferredCategory=="饮食场景" 的全部条目（含新扩的寿司/日料/韩料/酒会/晚宴/夜宵/聚会/婚宴）

struct ScenePickerSheet: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss

    /// 嘌呤食物库里的全部饮食场景条目（适量+注意两列下的场景类）
    private var sceneItems: [PurineItem] {
        if store.purineItems.isEmpty { store.purineItems = PurineDatabase.seed }
        return store.purineItems
            .filter { $0.inferredCategory == "饮食场景" }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(sceneItems) { item in
                        Button {
                            if store.meta.customScenes.contains(item.name) {
                                store.meta.customScenes.removeAll { $0 == item.name }
                            } else {
                                store.meta.customScenes.append(item.name)
                            }
                            store.save()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.displayName).foregroundColor(.primary)
                                    // 健哥11-22令4：能吃=绿 适量=黄 注意=红
                                    Text(L("Purine ~\(Int(item.uricPer100g)) mg/100g · \(levelName(item.level))", "嘌呤约 \(Int(item.uricPer100g)) mg/100g · \(levelName(item.level))"))
                                        .font(.caption2)
                                        .foregroundColor(item.level == "red" ? .danger : item.level == "yellow" ? .warn : .success)
                                }
                                Spacer()
                                if store.meta.customScenes.contains(item.name) {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.brand)
                                }
                            }
                        }
                    }
                } header: {
                    Text(L("Manage scenes (checked = shows on food page)", "管理场景（勾选=出现在饮食页）"))
                } footer: {
                    Text(L("Synced with the food library's dining scenes. Uncheck to remove from the food page.", "与嘌呤食物库的饮食场景同步。取消勾选=从饮食页删除。"))
                }
            }
            .navigationTitle(L("Manage scenes", "管理场景"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Done", "完成")) { dismiss() }
                }
            }
        }
    }

    private func levelName(_ l: String) -> String {
        l == "red" ? L("Caution", "注意") : l == "yellow" ? L("Moderate", "适量") : L("Safe to eat", "能吃")
    }
}


// MARK: - 身体节律页（健哥11-23令⑨：房事/自慰频率记录——痛风诱因之一）
// 隐私设计：只存日期+类型两字段；页名"身体节律"；无统计图（避免成为炫耀/焦虑工具，只有医疗关联价值）

struct RhythmPage: View {
    @ObservedObject var store = Store.shared

    private var recent: [SexualActivityLog] {
        store.sexualLogs.sorted { $0.date > $1.date }
    }
    private var last30: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return store.sexualLogs.filter { $0.date >= cutoff }.count
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Button {
                        store.sexualLogs.append(SexualActivityLog(date: Date(), kind: "sex"))
                        store.save()
                        UricCelebrate.show(L("Logged", "记下了"))
                    } label: {
                        Label(L("Log — partnered", "记一次（有伴侣）"), systemImage: "heart.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    Button {
                        store.sexualLogs.append(SexualActivityLog(date: Date(), kind: "masturbation"))
                        store.save()
                        UricCelebrate.show(L("Logged", "记下了"))
                    } label: {
                        Label(L("Log — solo", "记一次（独自）"), systemImage: "person.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.pink)
                }
            } footer: {
                Text(L("Frequency is a known gout trigger factor. Only date + type is stored — nothing else. Never synced anywhere.", "频率是痛风的已知诱因之一。只存日期和类型，别无所存；永不上传。"))
            }
            Section(L("Last 30 days", "近 30 天")) {
                HStack {
                    Text(L("Total", "合计"))
                    Spacer()
                    Text("\(last30) " + L("times", "次")).foregroundColor(.secondary)
                }
            }
            Section(L("History (swipe to delete)", "历史（左滑删除）")) {
                if recent.isEmpty {
                    Text(L("Nothing logged yet", "还没有记录")).font(.caption).foregroundColor(.secondary)
                }
                ForEach(recent) { r in
                    HStack {
                        Text(r.date.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        Text(r.kind == "sex" ? L("partnered", "有伴侣") : L("solo", "独自"))
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                .onDelete { idx in
                    let sorted = store.sexualLogs.sorted { $0.date > $1.date }
                    for i in idx { if let r = sorted[safe: i] { store.sexualLogs.removeAll { $0.id == r.id } } }
                    store.save()
                }
            }
        }
        .navigationTitle(L("Body rhythm", "身体节律"))
    }
}
