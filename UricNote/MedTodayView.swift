import SwiftUI
import UserNotifications

// MARK: - 用药（计划管理+每日打卡+本地通知提醒——P3 修复：健哥"经常忘吃药"核心痛点不能是占位）

struct MedTodayView: View {
    @ObservedObject var store = Store.shared
    @State private var showEditor = false

    private var activePlan: MedPlan? { store.medPlans.first(where: { $0.active }) }
    private var todayTaken: Bool {
        store.medLogs.contains { Calendar.current.isDateInToday($0.date) && $0.taken }
    }

    var body: some View {
        List {
            if let plan = activePlan {
                Section("当前用药") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(plan.name) \(plan.dose)")
                            .font(.body.weight(.semibold))
                        Text("每天 \(plan.timesPerDay) 次 · 开始于 \(plan.startDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Button(todayTaken ? "今天已记 ✓" : "记今天已吃") {
                        markToday()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(todayTaken)
                }
                Section {
                    Button("停用这个药计划", role: .destructive) {
                        stopPlan(plan)
                    }
                } footer: {
                    Text("停药前请看「误区」卡 #2：不疼了不等于好了——停药后多数人半年内复发。（本提示为患者共识科普，具体请遵医嘱）")
                }
            } else {
                Section {
                    Button("添加用药计划") { showEditor = true }
                } footer: {
                    Text("提醒+依从率组合才有效（RCT 实证：单提醒无效）。「觉得没必要吃」是停药首因——依从率曲线会给医生看，也是给你自己看的证据。")
                }
            }

            Section("近 7 天（点打卡记录可撤销）") {
                ForEach(last7Days, id: \.self) { day in
                    let log = store.medLogs.first { Calendar.current.isDate($0.date, equalTo: day, toGranularity: .day) && $0.taken }
                    HStack {
                        Text(day.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        if let l = log {
                            Button {
                                store.medLogs.removeAll { $0.id == l.id }   // D6/A4：记错可撤销
                            } label: {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            }
                        } else {
                            Image(systemName: "circle").foregroundColor(.secondary.opacity(0.4))
                        }
                    }
                }
            }
        }
        .navigationTitle("用药")
        .sheet(isPresented: $showEditor) { MedPlanEditor() }
    }

    private var last7Days: [Date] {
        (0..<7).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) }
    }

    private func markToday() {
        guard let plan = activePlan else { return }
        let log = MedLog(date: Date(), planRef: plan.id, taken: true, provenance: .recorded)
        store.medLogs.append(log)
        // 种子联动（毕业后的种子不再计）
        if var s = store.seed, s.type == "med", !s.graduated, s.realStreak < 14 {
            s.realStreak += 1
            store.seed = s
            store.meta.seedVotesTotal += 1
        }
        UricCelebrate.show("记好了——今天也没断")   // D2：中文
    }

    private func stopPlan(_ plan: MedPlan) {
        guard let idx = store.medPlans.firstIndex(where: { $0.id == plan.id }) else { return }
        store.medPlans[idx].active = false
        store.medPlans[idx].stopDate = Date()
        store.save()
        cancelMedReminder()
    }

    // P3 最小提醒实现：每天 9:00 本地通知（计划激活时注册/停用时取消）
    func scheduleMedReminder() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "UricNote"
            content.body = "今天的药吃了吗？吃完来打个卡。"   // D2：中文文案
            content.sound = .default
            var comps = DateComponents()
            comps.hour = 9; comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let req = UNNotificationRequest(identifier: "ur.med.daily", content: content, trigger: trigger)
            center.add(req)
        }
    }

    func cancelMedReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["ur.med.daily"])
    }
}

struct MedPlanEditor: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss
    @State private var name = "非布司他"
    @State private var dose = "40mg"
    @State private var times = 1

    private let commonMeds = ["非布司他", "别嘌醇", "秋水仙碱", "苯溴马隆"]

    var body: some View {
        Form {
            Section("药物名") {
                Picker("常见药", selection: $name) {
                    ForEach(commonMeds, id: \.self) { Text($0).tag($0) }
                    Text("自定义").tag("自定义")
                }
                if name == "自定义" {
                    TextField("输入药名", text: $name)
                }
            }
            Section("剂量") {
                TextField("例如 40mg", text: $dose)
                Stepper("每天 \(times) 次", value: $times, in: 1...3)
            }
            Button("保存") {
                let plan = MedPlan(
                    name: name, dose: dose, timesPerDay: times,
                    reminderTimes: [Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!],
                    startDate: Date()
                )
                store.medPlans.append(plan)
                store.save()
                MedTodayView().scheduleMedReminder()
                UricCelebrate.show("用药计划已建。")
                dismiss()
            }
        }
        .navigationTitle("添加用药")
    }
}
