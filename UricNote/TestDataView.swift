import SwiftUI

// MARK: - 测试开关（一处控制全部测试能力）

enum TestFlags {
    /// 控制：记录页「测试」入口 + Pro 强制解锁 是否可用。
    /// 🔴 上架前改成 false —— 入口消失，且强制解锁立即失效（即使 UserDefaults 里还留着开关值）。
    static let enabled = false

    /// Pro 强制解锁的 UserDefaults key（仅 TestFlags.enabled 为 true 时被读取）
    static let proForceUnlockKey = "ur.proForceUnlocked"
}

// MARK: - 测试数据生成（健哥 2026-11-26 令：手工攒 90 天数据太慢，要一键铺）
//
// 设计要点：
// - 每次点击填「已有数据中最早一天的前一天」，所以连点会自然往前推，不需要维护状态
// - 生成的是「像真的」的数据：喝水有高有低、入睡有早有晚、化验每几天一条、发作偶尔一次
// - 上架前把 RecordListView.showsTestTools 改成 false，入口即消失，本文件可留着不动

struct TestDataView: View {
    @ObservedObject var store = Store.shared
    @EnvironmentObject private var pro: ProStore
    @State private var toast: String?

    private let cal = Calendar.current

    /// 已有数据里最早的一天
    private var earliestDay: Date? {
        var dates: [Date] = []
        dates += store.readings.map(\.date)
        dates += store.flares.map(\.startDate)
        dates += store.waterDays.map(\.day)
        dates += store.sleepLogs.map(\.night)
        dates += store.foodDays.map(\.day)
        dates += store.weightLogs.map(\.date)
        return dates.map { cal.startOfDay(for: $0) }.min()
    }

    private var nextDay: Date {
        guard let e = earliestDay else { return cal.startOfDay(for: Date()) }
        return cal.date(byAdding: .day, value: -1, to: e) ?? e
    }

    private var totalEntries: Int {
        store.readings.count + store.flares.count + store.waterDays.count
            + store.sleepLogs.count + store.foodDays.count + store.weightLogs.count
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text(L("Entries so far", "已有记录"))
                    Spacer()
                    Text("\(totalEntries)").foregroundColor(.secondary)
                }
                HStack {
                    Text(L("Next day to fill", "下一次生成"))
                    Spacer()
                    Text(nextDay.formatted(.dateTime.month().day()))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(L("Test data", "测试数据"))
            } footer: {
                Text(L("Each tap fills one whole day with plausible data and moves the date back one day. These are sample records, not real ones — turn this off before release.",
                       "每点一次生成一整天的合理数据，日期往前推一天。这些是示例记录，不是真实数据——上架前关掉这个入口。"))
            }

            // 2026-11-27：分类型计数——健哥反馈"只看到喝水入睡尿酸变了"，
            // 因为饮食页只看今天、药物使用要打卡、发作概率低。
            // 把每一类的实际条数摊开，生成了什么一眼可见。
            Section {
                statRow(L("Lab values", "化验值"), store.readings.count)
                statRow(L("Flares", "发作记录"), store.flares.count)
                statRow(L("Food logs", "饮食记录"), store.foodDays.count)
                statRow(L("Water days", "喝水记录"), store.waterDays.count)
                statRow(L("Sleep nights", "入睡记录"), store.sleepLogs.count)
                statRow(L("Weight entries", "体重记录"), store.weightLogs.count)
                statRow(L("Medication check-ins", "用药打卡"), store.medLogs.count)
            } header: {
                Text(L("What is actually in the store", "已存入的数据"))
            } footer: {
                Text(L("Food / water / sleep show on the Trends heat grid; flares show under the pain-free counter; labs feed the uric acid chart.",
                       "饮食/喝水/入睡会进趋势页的坚持热力格；发作会改变「无痛天数」；化验值进尿酸曲线。"))
            }

            Section {
                Toggle(isOn: Binding(
                    get: { UserDefaults.standard.bool(forKey: TestFlags.proForceUnlockKey) },
                    set: { on in
                        UserDefaults.standard.set(on, forKey: TestFlags.proForceUnlockKey)
                        Task { await pro.refresh() }   // 立即生效，不用杀 App
                    }
                )) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L("Unlock Pro (testing)", "解锁 Pro（测试用）"))
                        Text(L("Skips StoreKit so you can test export, full history and trigger ranking without paying. Does not create a real purchase.",
                               "跳过购买直接解锁，用来测导出、全部历史、诱因排行。不会产生真实购买记录。"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Pro")
            }

            Section {
                Button {
                    generate(days: 1)
                } label: {
                    Label(L("Add one day", "加 1 天"), systemImage: "plus.circle")
                }
                Button {
                    generate(days: 7)
                } label: {
                    Label(L("Add seven days", "加 7 天"), systemImage: "plus.circle.fill")
                }
            }

            Section {
                Text(L("Want to start over? Records → Reset all data clears everything.",
                       "想重来？在「记录」页用「重置所有数据」清空。"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(L("Test data", "测试数据"))
        .alert(toast ?? "", isPresented: Binding(
            get: { toast != nil },
            set: { if !$0 { toast = nil } }
        )) {
            Button(L("OK", "知道了")) { toast = nil }
        }
    }

    // MARK: 生成

    private func generate(days: Int) {
        let flaresBefore = store.flares.count
        let weightBefore = store.weightLogs.count
        var cursor = nextDay
        for _ in 0..<days {
            fillOneDay(cursor)
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        // 2026-11-27：保底——7 天里一次发作都没有的话，趋势页看不出任何变化。
        // 补一次「中等程度」的发作到本批中间那天，保证可观测。
        if days >= 7 && store.flares.count == flaresBefore {
            let mid = cal.date(byAdding: .day, value: -(days / 2), to: nextDay) ?? nextDay
            store.flares.append(
                Flare(startDate: cal.date(byAdding: .hour, value: 3, to: mid) ?? mid,
                      endDate: nil, joints: ["脚趾"], painPeak: 6,
                      canWalk: false, workImpact: 1, workImpactNote: nil,
                      tookMedsToday: nil, tookPainkiller: true,
                      painkillerName: nil, triggerNotes: nil)
            )
        }
        if days >= 7 && store.weightLogs.count == weightBefore {
            let mid = cal.date(byAdding: .day, value: -(days / 2), to: nextDay) ?? nextDay
            store.weightLogs.append(WeightLog(date: mid, kg: (Double.random(in: 74...79) * 10).rounded() / 10))
        }
        toast = L("Added \(days) day(s) — labs \(store.readings.count) · flares \(store.flares.count) · food \(store.foodDays.count)",
                  "已生成 \(days) 天 —— 化验 \(store.readings.count) · 发作 \(store.flares.count) · 饮食 \(store.foodDays.count)")
    }

    private func statRow(_ title: String, _ value: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)")
                .font(.body.weight(.semibold))
                .foregroundColor(value == 0 ? .secondary : .brand)
        }
    }

    private func fillOneDay(_ day: Date) {
        // ① 入睡（0=23点前 1=23-24 2=0-1 3=1点后）——偏向前半夜
        let buckets = [0, 0, 1, 1, 1, 2, 2, 3]
        store.sleepLogs.append(
            SleepLog(night: day, bucket: buckets.randomElement() ?? 1)
        )

        // ② 喝水：5-10 杯 × 250ml = 1250-2500ml，有时达标有时不达标
        let cups = Int.random(in: 5...10)
        let cupList = (0..<cups).map { i in
            WaterCup(time: cal.date(byAdding: .hour, value: 8 + i, to: day) ?? day, ml: 250)
        }
        store.waterDays.append(
            WaterDay(day: day,
                     cups: cupList,
                     cupSizeMl: 250,
                     urine: UrineSlot(morning: nil, noon: nil, evening: nil),
                     goalMl: 2000)
        )

        // ③ 饮食：三天里一天「没碰高嘌呤」，其余随机 0-2 项
        if Int.random(in: 0..<3) == 0 {
            store.foodDays.append(
                FoodDayLog(day: day, items: [], scenes: [], noTriggerToday: true)
            )
        } else {
            let pool = ["啤酒", "火锅汤底", "动物内脏", "海鲜", "浓肉汤"]
            let picked = Array(pool.shuffled().prefix(Int.random(in: 0...2)))
            let scenes = picked.contains("火锅汤底") ? ["火锅"] : []
            store.foodDays.append(
                FoodDayLog(day: day,
                           items: picked,
                           scenes: scenes,
                           noTriggerToday: picked.isEmpty)
            )
        }

        // ④ 化验值：每 4 天一条，5.0-7.6 mg/dL（跨过 6.0 目标线，图才有起伏）
        if Int.random(in: 0..<4) == 0 {
            let v = (Double.random(in: 5.0...7.6) * 10).rounded() / 10
            store.readings.append(
                UricReading(date: cal.date(byAdding: .hour, value: 9, to: day) ?? day,
                            valueMgDl: v,
                            creatinineMgDl: nil,
                            source: "lab")
            )
        }

        // ⑤ 发作：12% 概率（原 8% 太低，加 7 天常常一次都没触发）
        if Int.random(in: 0..<100) < 12 {
            let joints = ["脚趾", "脚踝", "膝盖", "手指"]
            store.flares.append(
                Flare(startDate: cal.date(byAdding: .hour, value: 3, to: day) ?? day,
                      endDate: nil,
                      joints: [joints.randomElement() ?? "脚趾"],
                      painPeak: Int.random(in: 4...9),
                      canWalk: Bool.random(),
                      workImpact: Int.random(in: 0...2),
                      workImpactNote: nil,
                      tookMedsToday: nil,
                      tookPainkiller: Bool.random(),
                      painkillerName: nil,
                      triggerNotes: nil)
            )
        }

        // ⑥ 体重：每 5 天一条（原 1/7，加 7 天常常一条都没有）
        if Int.random(in: 0..<5) == 0 {
            let kg = (Double.random(in: 74...79) * 10).rounded() / 10
            store.weightLogs.append(WeightLog(date: day, kg: kg))
        }

        // ⑦ 用药打卡：有在用方案就按次生成（80% 吃了）
        //    2026-11-27：原来完全没生成，导致趋势页「药物使用（近 30 天）」一直空白、
        //    「记录坚持」热力格也少一类颜色。
        for plan in store.medPlans where plan.active {
            for slot in 1...max(plan.timesPerDay, 1) {
                let taken = Int.random(in: 0..<10) < 8
                store.medLogs.append(
                    MedLog(date: cal.date(byAdding: .hour, value: 7 + slot * 5, to: day) ?? day,
                           planRef: plan.id,
                           taken: taken,
                           slot: slot)
                )
            }
        }
    }
}
