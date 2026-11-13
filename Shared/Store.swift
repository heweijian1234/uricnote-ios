import Foundation
import SwiftUI

// MARK: - Provenance 三态（v10 施工单第二节：缺失数据铁律）
// recorded  = 实时记录 → 计入投票/依从率/趋势
// confirmed = 断记确认补记 → 报告浅色标"补记"，不投票
// unrecorded = 未记录 → 报告灰标"未记录"，绝不默认值填充
enum Provenance: String, Codable {
    case recorded
    case confirmed
}

// MARK: - 动机锚（Onboarding 三选一，v8）
enum MotivationChoice: String, Codable, CaseIterable {
    case painFree = "不再被疼醒"
    case work = "能正常工作赚钱"
    case family = "陪家人更久"
}

// MARK: - 化验值
struct UricReading: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var valueMgDl: Double          // 存 mg/dL，显示按单位设置换算
    var source: String             // lab / home
    var provenance: Provenance = .recorded
    var urateUnit: Double { valueMgDl * 59.48 }  // µmol/L 换算
    var atTarget: Bool { valueMgDl < 6.0 }
}

// MARK: - 发作
struct Flare: Identifiable, Codable {
    var id: UUID = UUID()
    var startDate: Date
    var endDate: Date?
    var joints: [String]           // 脚趾/脚踝/脚跟/膝/手指/手腕/肘/足背/其他
    var painPeak: Int              // 1-10
    var canWalk: Bool
    var workImpact: Int            // 0-3（0=没影响，3=无法工作；可选）
    var medsTaken: Bool
    var triggerNotes: String?
    var provenance: Provenance = .recorded
    var durationDays: Int? {
        guard let end = endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: startDate, to: end).day
    }
}

// MARK: - 服药
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

// MARK: - 喝水
struct WaterLog: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date                 // 当天（年月日）
    var cups: Int                  // 每杯 250ml
    var goalMl: Int                // 按体重自动：体重kg×35ml，下限2000
    var urineColor: Int?           // 1-8（1浅-8深）
    var provenance: Provenance = .recorded
}

// MARK: - 体重（周记粒度，入口在"改变"页）
struct WeightLog: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var kg: Double
    var provenance: Provenance = .recorded
}

// MARK: - 饮食简记（红黄绿触碰，不逐餐称重）
struct FoodLog: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var itemName: String
    var level: String              // red / yellow / green
    var isAlcohol: Bool = false
    var provenance: Provenance = .recorded
}

// MARK: - 习惯种子（v9：Fogg 配方）
struct Seed: Identifiable, Codable {
    var id: UUID = UUID()
    var type: String               // water / med / weigh
    var anchorMoment: String       // "早上刷牙后" 等
    var startDate: Date
    var unlockedSecond: Bool = false   // 14 天后解锁第二颗
    var realStreak: Int = 0            // 只数 recorded
}

// MARK: - 嘌呤食物库条目
struct PurineItem: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var uricPer100g: Double        // 每100g嘌呤mg
    var level: String              // red(>150) / yellow(50-150) / green(<50)
    var sourceTag: String          // "ACR 2020" / "卫健委2024"
}

// MARK: - 复查节律
struct ReviewSchedule: Codable {
    var nextReviewDate: Date?
    var intervalWeeks: Int = 8     // 默认8周，可4-12
    var rhythmCardShown: Bool = false
}

// MARK: - 断记确认记录
struct ConfirmedGap: Codable {
    var startDate: Date
    var endDate: Date
    var answer: String             // normal / missed / unknown
    var confirmedAt: Date
}

// MARK: - 元配置
struct AppMeta: Codable {
    var onboardingDone: Bool = false
    var motivation: MotivationChoice?
    var lastOpenedAt: Date?
    var unitIsUmol: Bool = true    // 中文区默认 µmol/L，英文区默认 mg/dL（上架时反转）
    var proUnlocked: Bool = false
    var seedVotesTotal: Int = 0    // 只累计 recorded
}

// MARK: - Store（UserDefaults 持久化，模式照 notarytrack）
final class Store: ObservableObject {
    static let shared = Store()
    private let defaults = UserDefaults.standard

    @Published var readings: [UricReading] = []
    @Published var flares: [Flare] = []
    @Published var medPlans: [MedPlan] = []
    @Published var medLogs: [MedLog] = []
    @Published var waterLogs: [WaterLog] = []
    @Published var weightLogs: [WeightLog] = []
    @Published var foodLogs: [FoodLog] = []
    @Published var seed: Seed?
    @Published var purineItems: [PurineItem] = []
    @Published var review = ReviewSchedule()
    @Published var meta = AppMeta()

    private init() { load() }

    // ---- 持久化 ----
    func save() {
        if let d = try? JSONEncoder().encode(readings) { defaults.set(d, forKey: "ur.readings") }
        if let d = try? JSONEncoder().encode(flares) { defaults.set(d, forKey: "ur.flares") }
        if let d = try? JSONEncoder().encode(medPlans) { defaults.set(d, forKey: "ur.medPlans") }
        if let d = try? JSONEncoder().encode(medLogs) { defaults.set(d, forKey: "ur.medLogs") }
        if let d = try? JSONEncoder().encode(waterLogs) { defaults.set(d, forKey: "ur.waterLogs") }
        if let d = try? JSONEncoder().encode(weightLogs) { defaults.set(d, forKey: "ur.weightLogs") }
        if let d = try? JSONEncoder().encode(foodLogs) { defaults.set(d, forKey: "ur.foodLogs") }
        if let d = try? JSONEncoder().encode(seed) { defaults.set(d, forKey: "ur.seed") }
        if let d = try? JSONEncoder().encode(purineItems) { defaults.set(d, forKey: "ur.purineItems") }
        if let d = try? JSONEncoder().encode(review) { defaults.set(d, forKey: "ur.review") }
        if let d = try? JSONEncoder().encode(meta) { defaults.set(d, forKey: "ur.meta") }
    }

    private func load() {
        if let d = defaults.data(forKey: "ur.readings"), let x = try? JSONDecoder().decode([UricReading].self, from: d) { readings = x }
        if let d = defaults.data(forKey: "ur.flares"), let x = try? JSONDecoder().decode([Flare].self, from: d) { flares = x }
        if let d = defaults.data(forKey: "ur.medPlans"), let x = try? JSONDecoder().decode([MedPlan].self, from: d) { medPlans = x }
        if let d = defaults.data(forKey: "ur.medLogs"), let x = try? JSONDecoder().decode([MedLog].self, from: d) { medLogs = x }
        if let d = defaults.data(forKey: "ur.waterLogs"), let x = try? JSONDecoder().decode([WaterLog].self, from: d) { waterLogs = x }
        if let d = defaults.data(forKey: "ur.weightLogs"), let x = try? JSONDecoder().decode([WeightLog].self, from: d) { weightLogs = x }
        if let d = defaults.data(forKey: "ur.foodLogs"), let x = try? JSONDecoder().decode([FoodLog].self, from: d) { foodLogs = x }
        if let d = defaults.data(forKey: "ur.seed"), let x = try? JSONDecoder().decode(Seed.self, from: d) { seed = x }
        if let d = defaults.data(forKey: "ur.purineItems"), let x = try? JSONDecoder().decode([PurineItem].self, from: d) { purineItems = x }
        if let d = defaults.data(forKey: "ur.review"), let x = try? JSONDecoder().decode(ReviewSchedule.self, from: d) { review = x }
        if let d = defaults.data(forKey: "ur.meta"), let x = try? JSONDecoder().decode(AppMeta.self, from: d) { meta = x }
    }

    // ---- 核心派生（仪表盘三数字） ----
    /// 无痛天数（最近一次发作结束或开始至今）
    var flareFreeDays: Int {
        let last = flares
            .compactMap { $0.endDate ?? $0.startDate }
            .max() ?? Date.distantPast
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
    }

    /// 最近化验值距目标差（mg/dL，正=未达标）
    var deltaToTarget: Double? {
        guard let last = readings.max(by: { $0.date < $1.date }) else { return nil }
        return last.valueMgDl - 6.0
    }

    /// 复查倒计时天数
    var daysToReview: Int? {
        guard let d = review.nextReviewDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: d).day
    }

    /// "已控制"徽章双条件：无痛≥90天 + 尿酸达标
    var wellControlled: Bool {
        flareFreeDays >= 90 && (deltaToTarget.map { $0 < 0 } ?? false)
    }

    /// 服药依从率（最近30天，只数 recorded+confirmed 语义上 confirmed 不投票——依从率用两类都有意义，报告区分标注）
    var adherenceRate: Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let logs = medLogs.filter { $0.date >= cutoff }
        guard !logs.isEmpty else { return nil }
        let taken = logs.filter { $0.taken }.count
        return Double(taken) / Double(logs.count)
    }

    // ---- 断记确认（超48h未开） ----
    var needsGapConfirm: Bool {
        guard let last = meta.lastOpenedAt else { return false }
        let hours = Calendar.current.dateComponents([.hour], from: last, to: Date()).hour ?? 0
        return hours >= 48
    }

    func confirmGap(start: Date, end: Date, answer: String) {
        // confirmed 补记：为每个缺失天生成 MedLog(confirmed)——若用户答"正常"
        guard answer == "normal", let plan = medPlans.first(where: { $0.active }) else { return }
        var day = start
        while day <= end {
            let log = MedLog(date: day, planRef: plan.id, taken: true, provenance: .confirmed)
            medLogs.append(log)
            day = Calendar.current.date(byAdding: .day, value: 1, to: day)!
        }
        save()
    }
}
