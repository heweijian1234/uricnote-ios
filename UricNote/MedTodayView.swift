import SwiftUI
import UserNotifications

// MARK: - 用药 v11.1（"当前使用药物药量"+按次打卡——一天 N 次出 N 次待办）

struct MedTodayView: View {
    @ObservedObject var store = Store.shared
    @State private var showEditor = false

    private var activePlan: MedPlan? { store.medPlans.first(where: { $0.active }) }

    var body: some View {
        List {
            if let plan = activePlan {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(plan.name) \(plan.dose)")
                            .font(.body.weight(.semibold))
                        Text(L("\(plan.timesPerDay)× daily · started \(plan.startDate.formatted(date: .abbreviated, time: .omitted))", "每天 \(plan.timesPerDay) 次 · 开始于 \(plan.startDate.formatted(date: .abbreviated, time: .omitted))"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    // v11.1：按次打卡（一天 N 次就 N 个按钮；全打完变完成态）
                    if store.todayMedTodos.contains(where: { !$0.done }) {
                        // 健哥11-23令③：今天发作不吃降酸药（一键记整天未服）
                        Button {
                            for t in store.todayMedTodos where !t.done {
                                store.medLogs.append(MedLog(date: Date(), planRef: plan.id, taken: false, slot: t.slot, provenance: .recorded))
                            }
                            store.save()
                            UricCelebrate.show(L("Noted: flare day, urate-lowering meds held", "已记：今天发作，未服降酸药"))
                        } label: {
                            Label(L("Flare today — didn't take urate-lowering meds", "今天发作，不吃降尿酸药物"), systemImage: "exclamationmark.circle")
                                .font(.callout)
                                .foregroundColor(.orange)
                        }
                    }
                    if store.todayMedTodos.contains(where: { !$0.done }) {
                        HStack(spacing: 10) {
                            ForEach(store.todayMedTodos.filter { !$0.done }, id: \.slot) { t in
                                Button {
                                    markSlot(t.slot)
                                } label: {
                                    Label(L("Log \(Store.medSlotLabel(t.slot)) as taken", "记\(Store.medSlotLabel(t.slot))已吃"), systemImage: "pills")
                                        .font(.callout.weight(.semibold))
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    } else {
                        Label(L("All logged today ✓", "今天都记完了 ✓"), systemImage: "checkmark.seal.fill")
                            .foregroundColor(.success)
                    }
                } header: {
                    Text(L("Current medication & dose", "当前使用药物药量"))
                }
                Section {
                    Button(L("Stop this medication plan", "停用这个药计划"), role: .destructive) {
                        stopPlan(plan)
                    }
                } footer: {
                    Text(L("Before stopping meds, see Myth #2: pain-free ≠ cured — most people flare again within 6 months after stopping. (Follow your doctor.)", "停药前请看「误区」卡 #2：不疼了不等于好了——停药后多数人半年内复发。（本提示为患者共识科普，具体请遵医嘱）"))
                }
                // 健哥11-21令8：吃药闹钟提醒（用户自定义，每天响，最多3个；11-23令③加总开关不强制）
                Section {
                    // 健哥11-23令③：闹钟总开关（默认开，可关）
                    Toggle(L("Alarms enabled", "闹钟开"), isOn: Binding(
                        get: { store.medPlans.first(where: { $0.id == plan.id })?.alarmsEnabled ?? true },
                        set: { on in
                            if let i = store.medPlans.firstIndex(where: { $0.id == plan.id }) {
                                store.medPlans[i].alarmsEnabled = on
                                store.save()
                                if on { scheduleMedReminder() } else { cancelMedReminder() }
                            }
                        }
                    ))
                    ForEach(plan.reminderTimes.indices, id: \.self) { idx in
                        DatePicker(L("Alarm \(idx + 1)", "闹钟 \(idx + 1)"), selection: Binding(
                            get: { store.medPlans.first(where: { $0.id == plan.id })?.reminderTimes[idx] ?? plan.reminderTimes[idx] },
                            set: { nv in
                                if let i = store.medPlans.firstIndex(where: { $0.id == plan.id }) {
                                    store.medPlans[i].reminderTimes[idx] = nv
                                    store.save()
                                    scheduleMedReminder()
                                }
                            }
                        ), displayedComponents: .hourAndMinute)
                    }
                    if plan.reminderTimes.count < 3 {
                        Button {
                            if let i = store.medPlans.firstIndex(where: { $0.id == plan.id }) {
                                var base = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
                                if !store.medPlans[i].reminderTimes.isEmpty {
                                    base = store.medPlans[i].reminderTimes.last!.addingTimeInterval(3600)
                                }
                                store.medPlans[i].reminderTimes.append(base)
                                store.save()
                                scheduleMedReminder()
                            }
                        } label: {
                            Label(L("Add an alarm (max 3)", "加一个闹钟（最多3个）"), systemImage: "alarm.badge.plus")
                        }
                    }
                    if plan.reminderTimes.count > 1 {
                        Button(role: .destructive) {
                            if let i = store.medPlans.firstIndex(where: { $0.id == plan.id }) {
                                store.medPlans[i].reminderTimes.removeLast()
                                store.save()
                                scheduleMedReminder()
                            }
                        } label: {
                            Label(L("Delete last alarm", "删最后一个闹钟"), systemImage: "alarm.badge.minus")
                        }
                    }
                } header: {
                    Text(L("Medication reminders (daily)", "吃药闹钟提醒（每天）"))
                /* Brother Jiang's order 11-23 ③: alarm master switch inserted before section */
                } footer: {
                    Text(L("Medication reminders at your own times — up to 3.", "到点提醒吃药——时间自己定，最多 3 个。"))
                }
            } else {
                Section {
                    Button(L("Add current medication & dose", "添加当前使用药物药量")) { showEditor = true }
                } footer: {
                    Text(L("Set once, use long-term, change anytime. Reminders + adherence tracking work together (RCT evidence). The adherence curve is for your doctor — and for you.", "填一次默认长期用，可随时改。提醒+依从率组合才有效（RCT 实证：单提醒无效）——依从率曲线会给医生看，也是给你自己看的证据。"))
                }
            }

            Section(L("Last 7 days (tap a check to undo)", "近 7 天（点打卡记录可撤销）")) {
                ForEach(last7Days, id: \.self) { day in
                    let logs = store.medLogs.filter { Calendar.current.isDate($0.date, equalTo: day, toGranularity: .day) && $0.taken }
                    HStack {
                        Text(day.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        if logs.isEmpty {
                            Image(systemName: "circle").foregroundColor(.secondary.opacity(0.4))
                        } else {
                            // 按次显示（一天2次=两个勾）
                            HStack(spacing: 4) {
                                ForEach(logs) { l in
                                    Button {
                                        store.medLogs.removeAll { $0.id == l.id }   // D6/A4：记错可撤销
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(.success)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(L("Current medication & dose", "当前使用药物药量"))
        .sheet(isPresented: $showEditor) { MedPlanEditor() }
    }

    private var last7Days: [Date] {
        // 健哥11-21令8：最近日期在上面（原是旧→新，排序反了）
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) }
    }

    private func markSlot(_ slot: Int) {
        guard let plan = activePlan else { return }
        let log = MedLog(date: Date(), planRef: plan.id, taken: true, slot: slot, provenance: .recorded)
        store.medLogs.append(log)
        Haptic.success()
        if store.todayMedTodos.allSatisfy({ $0.done }) {
            UricCelebrate.show(L("All meds logged today ✓", "今天的药都记完了 ✓"))
        } else {
            UricCelebrate.show(L("Done — \(Store.medSlotLabel(slot)) dose logged", "记好了——\(Store.medSlotLabel(slot))这次打卡完成"))
        }
    }

    private func stopPlan(_ plan: MedPlan) {
        guard let idx = store.medPlans.firstIndex(where: { $0.id == plan.id }) else { return }
        store.medPlans[idx].active = false
        store.medPlans[idx].stopDate = Date()
        store.save()
        cancelMedReminder()
    }

    // 健哥11-21令8：多闹钟版（按 reminderTimes 逐个注册每天响；最多3个）
    func scheduleMedReminder() {
        // 健哥11-23令③：总开关关着就不排
        guard activePlan?.alarmsEnabled ?? true else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            // 清旧的（含单闹钟时代 id）再注册
            center.removePendingNotificationRequests(withIdentifiers: (0..<3).map { "ur.med.daily.\($0)" } + ["ur.med.daily"])
            let times = activePlan?.reminderTimes ?? []
            for (idx, t) in times.prefix(3).enumerated() {
                let content = UNMutableNotificationContent()
                content.title = "UricNote"
                let tf = DateFormatter(); tf.timeStyle = .short
                content.body = "\(activePlan?.name ?? L("meds", "药")) \(activePlan?.dose ?? "") — time to take it and check in. (\(tf.string(from: t)))"
                content.sound = .default
                var comps = DateComponents()
                comps.hour = Calendar.current.component(.hour, from: t)
                comps.minute = Calendar.current.component(.minute, from: t)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                center.add(UNNotificationRequest(identifier: "ur.med.daily.\(idx)", content: content, trigger: trigger))
            }
        }
    }

    func cancelMedReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: (0..<3).map { "ur.med.daily.\($0)" } + ["ur.med.daily"])
    }
}

struct MedPlanEditor: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss
    @State private var name = L("Febuxostat", "非布司他")
    @State private var dose = "40mg"
    @State private var times = 1

    private let commonMeds = [L("Febuxostat", "非布司他"), L("Allopurinol", "别嘌醇"), L("Colchicine", "秋水仙碱"), L("Benzbromarone", "苯溴马隆")]

    var body: some View {
        Form {
            Section {
                Picker(L("Common meds", "常见药"), selection: $name) {
                    ForEach(commonMeds, id: \.self) { Text($0).tag($0) }
                    Text(L("Custom", "自定义")).tag("自定义")
                }
                if name == L("Custom", "自定义") {
                    TextField(L("Medication name", "输入药名"), text: $name)
                }
            } header: {
                Text(L("Medication name", "药物名"))
            }
            Section {
                TextField(L("e.g. 40mg", "例如 40mg"), text: $dose)
                Stepper(L("\(times)× daily", "每天 \(times) 次"), value: $times, in: 1...3)
            } header: {
                Text(L("Dose", "剂量"))
            } footer: {
                Text(L("Log once per dose (pick 2 for morning & evening).", "一天几次就打几次卡（早晚各一次就选 2 次）。"))
            }
            Button(L("Save", "保存")) {
                let plan = MedPlan(
                    name: name, dose: dose, timesPerDay: times,
                    reminderTimes: [Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!],
                    startDate: Date()
                )
                store.medPlans.append(plan)
                store.save()
                MedTodayView().scheduleMedReminder()
                UricCelebrate.show(L("Current medication recorded.", "已记录当前用药。"))
                dismiss()
            }
        }
        .navigationTitle(L("Add current medication & dose", "添加当前使用药物药量"))
    }
}
