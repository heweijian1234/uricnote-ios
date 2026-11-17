import Foundation
import SwiftUI

// MARK: - 数据层 v11 · 2026-11-17 健哥复测施工单全量落地
// 施工单：research\UricNote-复测反馈施工单-2026-11-17.md（A10项+B6项+C16项裁决+D9缺陷）
// 数据层改动：WaterLog 重做（杯明细/自填杯量/沿用标记）/SleepLog 新增/HealthProfile 档案
//            /肌酐字段/Provenance 增 estimated（沿用均值）/打卡可撤销

// MARK: - Provenance 四态（v11：新增 estimated=沿用均值，诚实纪律）
// recorded  = 实时记录 → 计入投票/依从率/趋势
// confirmed = 断记确认补记 → 报告浅色标"补记"，不投票
// estimated = 沿用上周均值自动填 → 报告标"沿用"，不算打卡不投票（健哥裁 A3）
// unrecorded = 未记录 → 报告灰标"未记录"，绝不默认值填充
enum Provenance: String, Codable {
    case recorded
    case confirmed
    case estimated
}

// MARK: - 动机锚（Onboarding 三选一）
enum MotivationChoice: String, Codable, CaseIterable {
    case painFree = "不再被疼醒"
    case work = "能正常工作赚钱"
    case family = "陪家人更久"
}

// MARK: - 化验值（v11：+肌酐可选字段 C12）
struct UricReading: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var valueMgDl: Double          // 存 mg/dL，显示按单位设置换算
    var creatinineMgDl: Double?    // 肌酐（可选）——降酸药选择依据（苯溴马隆肾禁忌/别嘌醇按肾功能调量）
    var source: String             // lab / home
    var provenance: Provenance = .recorded
    var urateUnit: Double { valueMgDl * 59.48 }  // µmol/L 换算
    var atTarget: Bool { valueMgDl < 6.0 }
}

// MARK: - 发作（v11：药问题修正 A8——removed 发作药语义，泛化 todayTookMeds + 止痛药默认收起）
struct Flare: Identifiable, Codable {
    var id: UUID = UUID()
    var startDate: Date
    var endDate: Date?
    var joints: [String]
    var painPeak: Int              // 1-10（界面加文字锚点 A7，报告仍显示数字）
    var canWalk: Bool
    var workImpact: Int            // 0-3（v11 D1 修复：真实存储，不再写死0）
    var workImpactNote: String?    // 轻微/明显/无法（与诱因备注分离——D1 数据污染修复）
    var tookMedsToday: Bool?       // 今天吃过药吗（泛指用户自己的药，不点名类型——A8）
    var tookPainkiller: Bool?      // 止痛药吃了吗（默认收起，很痛才用）
    var painkillerName: String?    // 止痛药名（用户自选固定）
    var triggerNotes: String?
    var provenance: Provenance = .recorded
    var durationDays: Int? {
        guard let end = endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: startDate, to: end).day
    }
}

// MARK: - 服药（v11：打卡可撤销 D6/A4——MedLog 加 id 已有，删除走 UI 层）
struct MedPlan: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var dose: String
    var timesPerDay: Int
    var reminderTimes: [Date]
    var active: Bool = true
    var startDate: Date
    var stopDate: Date?
}

struct MedLog: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var planRef: UUID
    var taken: Bool
    var provenance: Provenance = .recorded
}

// MARK: - 喝水 v11 重做（健哥 A2 设计：杯量自填/逐杯明细/早午晚尿色/凌晨自动入档/7天沿用）
struct WaterCup: Identifiable, Codable {
    var id: UUID = UUID()
    var time: Date                 // 第几杯几点喝的
    var ml: Int                    // 这杯的容量（用户自填，容器不一）
}

struct UrineSlot: Codable {        // 尿色分早午晚（A2：未记=未记不猜）
    var morning: Int?              // 1-8（1浅-8深）
    var noon: Int?
    var evening: Int?
}

struct WaterDay: Identifiable, Codable {
    var id: UUID = UUID()
    var day: Date                  // 归属日（手机本地时间 0 点）
    var cups: [WaterCup]           // 逐杯明细
    var cupSizeMl: Int             // 默认杯量（用户自填，250 起步）
    var urine: UrineSlot
    var provenance: Provenance = .recorded   // estimated=整日沿用均值
    var goalMl: Int = 2000
    var totalMl: Int { cups.reduce(0) { $0 + $1.ml } }
}

// MARK: - 入睡时间（v11 新增 B2/C2：只记入睡不记起床，按"哪一晚"归属）
struct SleepLog: Identifiable, Codable {
    var id: UUID = UUID()
    var night: Date                // 归属哪一晚（今天早上记=昨晚，存昨晚日期）
    var bucket: Int                // 0=23点前 1=23-24点 2=0-1点 3=1点后
    var provenance: Provenance = .recorded
    var bucketText: String {
        switch bucket { case 0: return "23点前"; case 1: return "23-24点"; case 2: return "0-1点"; default: return "1点后" }
    }
}

// MARK: - 饮食 v11 重做（B3/C4-C8：高嘌呤红区多选+负面记录+场景按钮+不分早午晚）
struct FoodDayLog: Identifiable, Codable {
    var id: UUID = UUID()
    var day: Date                  // 归属日
    var items: [String]            // 碰过的高嘌呤项（多选）
    var scenes: [String]           // 场景按钮（火锅/烧烤/海鲜自助）
    var noTriggerToday: Bool       // 负面记录：今天没吃高嘌呤（防诱因排行虚高）
    var customNote: String?        // 自定义输入
    var provenance: Provenance = .recorded
}

// MARK: - 食物库 v11（C13-C16 健哥质疑扩容后终版：证据判定注释齐全）
struct FoodItem: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var level: String              // red(记录面板红区) / yellow(适量注意) / green(放心吃)
    var note: String?              // 一句证据注释
    var category: String           // 海鲜浓味/内脏/浓汤/酒/含糖饮料/红肉/蛋奶/主食/蔬果/饮品/争议
}

enum FoodLibrary {
    // 记录面板（红区多选）——碰到才记 + "今天没吃"负面记录
    static let redZone: [FoodItem] = [
        .init(name: "沙丁鱼", level: "red", note: "嘌呤最高档", category: "海鲜浓味"),
        .init(name: "凤尾鱼", level: "red", note: "嘌呤最高档", category: "海鲜浓味"),
        .init(name: "秋刀鱼", level: "red", note: "高嘌呤", category: "海鲜浓味"),
        .init(name: "贝类牡蛎", level: "red", note: "高嘌呤", category: "海鲜浓味"),
        .init(name: "蟹", level: "red", note: "高嘌呤", category: "海鲜浓味"),
        .init(name: "鱼子虾籽", level: "red", note: "嘌呤浓缩", category: "海鲜浓味"),
        .init(name: "小鱼干", level: "red", note: "脱水浓缩嘌呤极高", category: "海鲜浓味"),
        .init(name: "动物内脏（肝/肾/脑/肠肚）", level: "red", note: "高嘌呤经典雷区", category: "内脏"),
        .init(name: "老火汤/浓肉汤", level: "red", note: "嘌呤溶于水，汤=浓缩液", category: "浓汤"),
        .init(name: "啤酒", level: "red", note: "嘌呤+酒精双杀，痛风第一诱因", category: "酒"),
        .init(name: "白酒", level: "red", note: "酒精抑制尿酸排泄", category: "酒"),
        .init(name: "黄酒", level: "red", note: "酒精抑制尿酸排泄", category: "酒"),
        .init(name: "可乐/含糖碳酸", level: "red", note: "果糖促生成抑排泄——男每周≥4杯风险+49%（2.5万人研究）", category: "含糖饮料"),
        .init(name: "奶茶", level: "red", note: "果糖+奶精反式脂肪双重负担", category: "含糖饮料"),
        .init(name: "果汁（含纯果汁）", level: "red", note: "去纤维后果糖浓缩吸收更快；卫健委2024指南明确避免", category: "含糖饮料"),
        .init(name: "蜂蜜", level: "red", note: "果糖占比约50%，尽量不吃", category: "含糖饮料"),
        .init(name: "猪牛羊红肉", level: "red", note: "中嘌呤但高频——请勿大量（健哥裁 C4 加提醒）", category: "红肉"),
    ]
    // 场景按钮（点了自动记红+关联项）
    static let scenes: [(name: String, autoItems: [String])] = [
        ("火锅", ["老火汤/浓肉汤"]),
        ("烧烤", ["猪牛羊红肉", "啤酒"]),
        ("海鲜自助", ["贝类牡蛎", "蟹"]),
    ]
    // 建议面板（仪表盘查阅卡，健哥裁 C3：必须放仪表盘）
    static let greenZone: [FoodItem] = [
        .init(name: "鸡蛋", level: "green", note: "低嘌呤优质蛋白", category: "蛋奶"),
        .init(name: "低脂奶/酸奶", level: "green", note: "降尿酸证据（保护性）", category: "蛋奶"),
        .init(name: "米饭/面条", level: "green", note: "低嘌呤主食放心吃", category: "主食"),
        .init(name: "燕麦/玉米", level: "green", note: "低嘌呤粗粮", category: "主食"),
        .init(name: "大部分蔬菜", level: "green", note: "植物嘌呤对痛风风险几乎无影响（2018后大队列）", category: "蔬果"),
        .init(name: "樱桃", level: "green", note: "降发作风险证据（保护性）", category: "蔬果"),
        .init(name: "苹果/香蕉", level: "green", note: "完整水果膳食纤维缓冲果糖，每天200-300g", category: "蔬果"),
        .init(name: "咖啡", level: "green", note: "长期饮用降尿酸证据（不加糖奶精）", category: "饮品"),
        .init(name: "淡茶", level: "green", note: "低嘌呤可饮，避免加糖加奶精", category: "饮品"),
        .init(name: "面包/馒头", level: "green", note: "低嘌呤；发酵面食略高于米饭面条，正常量无碍", category: "主食"),
    ]
    static let yellowZone: [FoodItem] = [
        .init(name: "豆腐/豆浆", level: "yellow", note: "2024卫健委指南可适量——健哥裁保守标黄", category: "争议"),
        .init(name: "淡水鱼（草鱼/鲫鱼）", level: "yellow", note: "平稳期50-100g每周2-3次，急性期避开；吃肉不喝汤", category: "争议"),
        .init(name: "菠菜/芦笋/蘑菇/菜花", level: "green", note: "老观念平反：植物嘌呤几乎不升痛风风险（2018后大队列）——跟证据走", category: "争议"),
    ]
}

// MARK: - 体重（保留时间序列）+ 健康档案 v11（A6/C11：静态"是谁"+动态"变化"分离）
struct WeightLog: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var kg: Double
    var provenance: Provenance = .recorded
}

struct HealthProfile: Codable {
    var heightCm: Double?
    var weightKg: Double?
    var age: Int?
    var gender: String?            // 男/女/其他
    var region: String?            // 地区
    var conditions: [String] = []  // 现有疾病（快捷多选：高血压/糖尿病/高血脂/肾结石/其他）
    var drugAllergies: String?     // 药物过敏（C11 拆栏）
    var foodAllergies: String?     // 食物过敏
    var familyGout: String?        // 直系亲属痛风：有/无/不确定
    var hlaTested: String?         // HLA-B*5801 检测史：查过-阴性/查过-阳性/没查过
    var isComplete: Bool = false   // 填完档案卡从仪表盘消失（A6）
}

// MARK: - 习惯种子（v11 B5：起步脚手架定位+毕业机制+中文情绪奖励）
struct Seed: Identifiable, Codable {
    var id: UUID = UUID()
    var type: String               // water / med / weigh
    var anchorMoment: String
    var startDate: Date
    var unlockedSecond: Bool = false
    var realStreak: Int = 0
    var graduated: Bool = false    // B5/C9：连续14天毕业庆祝后自动隐退（脚手架使命完成）
}

// MARK: - 复查节律（v11 A5：间隔可调+推算过程显示）
struct ReviewSchedule: Codable {
    var nextReviewDate: Date?
    var intervalWeeks: Int = 8     // 4/6/8/12 可调（界面落地）
    var rhythmCardShown: Bool = false
}

// MARK: - 断记确认
struct ConfirmedGap: Codable {
    var startDate: Date
    var endDate: Date
    var answer: String
    var confirmedAt: Date
}

// MARK: - 回忆记录闹钟（v11 B6/C10：每晚固定时间本地通知+开关）
struct RecallAlarm: Codable {
    var enabled: Bool = false      // C10 健哥裁：要有开关，默认无所谓（默认关）
    var hour: Int = 21
    var minute: Int = 30
}

// MARK: - 元配置
struct AppMeta: Codable {
    var onboardingDone: Bool = false
    var motivation: MotivationChoice?
    var lastOpenedAt: Date?
    var unitIsUmol: Bool = true
    var proUnlocked: Bool = false
    var seedVotesTotal: Int = 0
    var waterAutoFillActive: Bool = false   // A2：7天后问是否沿用上周平均；可随时关
    var waterAutoFillAsked: Bool = false    // 问过没有（只问一次）
}

// MARK: - Store
final class Store: ObservableObject {
    static let shared = Store()
    private let defaults = UserDefaults.standard

    @Published var readings: [UricReading] = [] { didSet { save() } }
    @Published var flares: [Flare] = [] { didSet { save() } }
    @Published var medPlans: [MedPlan] = [] { didSet { save() } }
    @Published var medLogs: [MedLog] = [] { didSet { save() } }
    @Published var waterDays: [WaterDay] = [] { didSet { save() } }
    @Published var sleepLogs: [SleepLog] = [] { didSet { save() } }
    @Published var foodDays: [FoodDayLog] = [] { didSet { save() } }
    @Published var weightLogs: [WeightLog] = [] { didSet { save() } }
    @Published var profile = HealthProfile() { didSet { save() } }
    @Published var seed: Seed? { didSet { save() } }
    @Published var review = ReviewSchedule() { didSet { save() } }
    @Published var recall = RecallAlarm() { didSet { save() } }
    @Published var meta = AppMeta() { didSet { save() } }

    private init() {
        load()
        migrateV10IfNeeded()
        rollWaterDayIfNeeded()   // A2：过凌晨自动归档重置（打开时惰性执行）
        askWaterAutoFillIfNeeded()
    }

    // ---- 持久化（didSet 自动存；外部手动调用兼容——meta 子字段改动不走 didSet） ----
    func save() {
        if let d = try? JSONEncoder().encode(readings) { defaults.set(d, forKey: "ur.readings") }
        if let d = try? JSONEncoder().encode(flares) { defaults.set(d, forKey: "ur.flares") }
        if let d = try? JSONEncoder().encode(medPlans) { defaults.set(d, forKey: "ur.medPlans") }
        if let d = try? JSONEncoder().encode(medLogs) { defaults.set(d, forKey: "ur.medLogs") }
        if let d = try? JSONEncoder().encode(waterDays) { defaults.set(d, forKey: "ur.waterDays") }
        if let d = try? JSONEncoder().encode(sleepLogs) { defaults.set(d, forKey: "ur.sleepLogs") }
        if let d = try? JSONEncoder().encode(foodDays) { defaults.set(d, forKey: "ur.foodDays") }
        if let d = try? JSONEncoder().encode(weightLogs) { defaults.set(d, forKey: "ur.weightLogs") }
        if let d = try? JSONEncoder().encode(profile) { defaults.set(d, forKey: "ur.profile") }
        if let d = try? JSONEncoder().encode(seed) { defaults.set(d, forKey: "ur.seed") }
        if let d = try? JSONEncoder().encode(review) { defaults.set(d, forKey: "ur.review") }
        if let d = try? JSONEncoder().encode(recall) { defaults.set(d, forKey: "ur.recall") }
        if let d = try? JSONEncoder().encode(meta) { defaults.set(d, forKey: "ur.meta") }
    }

    private func load() {
        if let d = defaults.data(forKey: "ur.readings"), let x = try? JSONDecoder().decode([UricReading].self, from: d) { readings = x }
        if let d = defaults.data(forKey: "ur.flares"), let x = try? JSONDecoder().decode([Flare].self, from: d) { flares = x }
        if let d = defaults.data(forKey: "ur.medPlans"), let x = try? JSONDecoder().decode([MedPlan].self, from: d) { medPlans = x }
        if let d = defaults.data(forKey: "ur.medLogs"), let x = try? JSONDecoder().decode([MedLog].self, from: d) { medLogs = x }
        if let d = defaults.data(forKey: "ur.waterDays"), let x = try? JSONDecoder().decode([WaterDay].self, from: d) { waterDays = x }
        if let d = defaults.data(forKey: "ur.sleepLogs"), let x = try? JSONDecoder().decode([SleepLog].self, from: d) { sleepLogs = x }
        if let d = defaults.data(forKey: "ur.foodDays"), let x = try? JSONDecoder().decode([FoodDayLog].self, from: d) { foodDays = x }
        if let d = defaults.data(forKey: "ur.weightLogs"), let x = try? JSONDecoder().decode([WeightLog].self, from: d) { weightLogs = x }
        if let d = defaults.data(forKey: "ur.profile"), let x = try? JSONDecoder().decode(HealthProfile.self, from: d) { profile = x }
        if let d = defaults.data(forKey: "ur.seed"), let x = try? JSONDecoder().decode(Seed.self, from: d) { seed = x }
        if let d = defaults.data(forKey: "ur.review"), let x = try? JSONDecoder().decode(ReviewSchedule.self, from: d) { review = x }
        if let d = defaults.data(forKey: "ur.recall"), let x = try? JSONDecoder().decode(RecallAlarm.self, from: d) { recall = x }
        if let d = defaults.data(forKey: "ur.meta"), let x = try? JSONDecoder().decode(AppMeta.self, from: d) { meta = x }
    }

    // ---- v10→v11 迁移：旧 waterLogs（按日杯数）→ 新 waterDays（杯明细） ----
    private func migrateV10IfNeeded() {
        guard let d = defaults.data(forKey: "ur.waterLogs"),
              let old = try? JSONDecoder().decode([LegacyWaterLog].self, from: d),
              waterDays.isEmpty else { return }
        waterDays = old.map { w in
            WaterDay(day: w.date,
                     cups: (0..<w.cups).map { _ in WaterCup(time: w.date, ml: 250) },
                     cupSizeMl: 250,
                     urine: UrineSlot(morning: w.urineColor, noon: nil, evening: nil),
                     provenance: w.provenance,
                     goalMl: w.goalMl)
        }
        defaults.removeObject(forKey: "ur.waterLogs")
    }
    private struct LegacyWaterLog: Codable {
        var id: UUID
        var date: Date
        var cups: Int
        var goalMl: Int
        var urineColor: Int?
        var provenance: Provenance
    }

    // ---- A2：过凌晨自动开新一天（惰性：打开 App 时补齐到今天） ----
    private func rollWaterDayIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        if !waterDays.contains(where: { Calendar.current.isDate($0.day, inSameDayAs: today) }) {
            let last7 = last7RecordedWaterDays(excludingToday: true)
            if meta.waterAutoFillActive, last7.count >= 5 {
                // 沿用上周平均（estimated 标记：不算打卡不进投票——A3 健哥裁）
                let avg = Double(last7.map { $0.totalMl }.reduce(0, +)) / Double(last7.count)
                let cups = max(1, Int((avg / Double(last7.first?.cupSizeMl ?? 250)).rounded()))
                var nd = WaterDay(day: today, cups: [], cupSizeMl: last7.first?.cupSizeMl ?? 250, urine: UrineSlot(morning: nil, noon: nil, evening: nil), provenance: .estimated, goalMl: Int(avg))
                nd.cups = (0..<cups).map { _ in WaterCup(time: today, ml: last7.first?.cupSizeMl ?? 250) }
                waterDays.append(nd)
            } else {
                waterDays.append(WaterDay(day: today, cups: [], cupSizeMl: meta.waterAutoFillAsked ? 250 : 250, urine: UrineSlot(morning: nil, noon: nil, evening: nil), goalMl: 2000))
            }
        }
    }

    // ---- A2：满 7 天实测后问是否沿用上周平均 ----
    private func askWaterAutoFillIfNeeded() {
        guard !meta.waterAutoFillAsked else { return }
        let recorded = waterDays.filter { $0.provenance == .recorded && !$0.cups.isEmpty }
        if recorded.count >= 7 {
            meta.waterAutoFillAsked = true
            // UI 层弹询问（WaterPage 观察 meta.waterAutoFillAsked 弹 alert）
        }
    }

    func enableWaterAutoFill() {
        meta.waterAutoFillActive = true
        meta.waterAutoFillAsked = true
    }
    func disableWaterAutoFill() {
        meta.waterAutoFillActive = false   // 关掉→明天起恢复手记（已沿用日保留 estimated 标记）
    }

    private func last7RecordedWaterDays(excludingToday: Bool) -> [WaterDay] {
        let today = Calendar.current.startOfDay(for: Date())
        return waterDays
            .filter { $0.provenance == .recorded && !$0.cups.isEmpty }
            .filter { excludingToday ? !Calendar.current.isDate($0.day, inSameDayAs: today) : true }
            .sorted { $0.day > $1.day }
            .prefix(7)
            .map { $0 }
    }

    var todayWater: WaterDay? {
        waterDays.first { Calendar.current.isDate($0.day, inSameDayAs: Date()) }
    }

    // ---- 核心派生（仪表盘三数字） ----
    var flareFreeDays: Int? {
        guard let last = flares.compactMap({ $0.endDate ?? $0.startDate }).max() else { return nil }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day
    }

    /// v11 D9/A5 修复：距目标按用户单位口径（不再 µmol/L 录入显示 mg/dL 差值）
    var lastReading: UricReading? { readings.max { $0.date < $1.date } }

    /// 达标判定统一入口（"已控制"徽章也走这里——D9 连带修复）
    var isAtTarget: Bool? { lastReading?.atTarget }

    var daysToReview: Int? {
        guard let d = review.nextReviewDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: d).day
    }

    var wellControlled: Bool {
        guard let d = flareFreeDays, !flares.isEmpty, let at = isAtTarget, at else { return false }
        return d >= 90
    }

    var adherenceRate: Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let logs = medLogs.filter { $0.date >= cutoff }
        guard !logs.isEmpty else { return nil }
        return Double(logs.filter { $0.taken }.count) / Double(logs.count)
    }

    // ---- B2：昨晚入睡（今天打开问"昨晚几点睡的"，存昨晚日期） ----
    var lastNightSleep: SleepLog? {
        let lastNight = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
        return sleepLogs.first { Calendar.current.isDate($0.night, inSameDayAs: lastNight) }
    }

    // ---- B3：今天饮食（红区多选+负面记录） ----
    var todayFood: FoodDayLog? {
        foodDays.first { Calendar.current.isDate($0.day, inSameDayAs: Date()) }
    }

    // ---- 断记确认（v11 D4 修复：逐日查重，已实测日不补） ----
    var needsGapConfirm: Bool {
        guard let last = meta.lastOpenedAt else { return false }
        let hours = Calendar.current.dateComponents([.hour], from: last, to: Date()).hour ?? 0
        return hours >= 48
    }

    func confirmGap(start: Date, end: Date, answer: String) {
        guard answer == "normal", let plan = medPlans.first(where: { $0.active }) else { return }
        var day = Calendar.current.startOfDay(for: start)
        let endDay = Calendar.current.startOfDay(for: end)
        while day <= endDay {
            // D4：已有实测打卡的日子不补（防补记撞实测）
            let hasReal = medLogs.contains { Calendar.current.isDate($0.date, inSameDayAs: day) && $0.provenance == .recorded }
            if !hasReal {
                medLogs.append(MedLog(date: day, planRef: plan.id, taken: true, provenance: .confirmed))
            }
            day = Calendar.current.date(byAdding: .day, value: 1, to: day)!
        }
    }
}
