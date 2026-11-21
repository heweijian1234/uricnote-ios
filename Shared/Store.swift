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
    case other = "其他"   // 健哥11-21令：第四选项，用户自填（存 motivationCustomText）

    /// 显示名（rawValue是中文存储值——英文版转英文）
    var displayName: String {
        switch self {
        case .painFree: return L("No more waking up in pain", "不再被疼醒")
        case .work: return L("Keep working and earning", "能正常工作赚钱")
        case .family: return L("Be there for family longer", "陪家人更久")
        case .other: return L("Other", "其他")
        }
    }
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
    var slot: Int? = nil   // 一天第几次（1=早 2=晚 3=午）；Optional=老数据无 key 不炸解码；nil 按 1 处理
    var provenance: Provenance = .recorded

    init(date: Date, planRef: UUID, taken: Bool, slot: Int? = nil, provenance: Provenance = .recorded) {
        self.id = UUID()
        self.date = date
        self.planRef = planRef
        self.taken = taken
        self.slot = slot
        self.provenance = provenance
    }
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
        switch bucket { case 0: return L("before 11 PM", "23点前"); case 1: return L("11 PM-12 AM", "23-24点"); case 2: return L("12-1 AM", "0-1点"); default: return L("after 1 AM", "1点后") }
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

// MARK: - 嘌呤食物库条目（v11 保留：LearnView 嘌呤库页仍用——174 条种子数据有效）
struct PurineItem: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var uricPer100g: Double        // 每100g嘌呤mg
    var level: String              // red(>150) / yellow(50-150) / green(<50)
    var sourceTag: String          // "ACR 2020" / L("NHHC 2024 (China)", "卫健委2024")
    var category: String? = nil    // 健哥11-21令：食物分类导航（Optional默认——旧数据零破坏；运行时推断补齐）
    var nameEn: String? = nil      // 健哥11-22令：英文名（英文版显示；中文名仍是存储key——数据兼容）
    var sourceTagEn: String? = nil // 健哥11-22令：英文来源标注

    /// 显示名：英文版优先 nameEn（没有则原样），中文版原名
    var displayName: String {
        AppLang.current == .en ? (nameEn ?? name) : name
    }
    /// 显示来源
    var displaySource: String {
        AppLang.current == .en ? (sourceTagEn ?? sourceTag) : sourceTag
    }

    /// 英文关键词分类规则（英文版按 nameEn 推断）
    static let enRules: [(String, String)] = [
        ("hot pot", "饮食场景"), ("bbq", "饮食场景"), ("buffet", "饮食场景"), ("banquet", "饮食场景"), ("wedding", "饮食场景"),
        ("sushi", "饮食场景"), ("japanese", "饮食场景"), ("korean", "饮食场景"), ("izakaya", "饮食场景"), ("party", "饮食场景"),
        ("dinner", "饮食场景"), ("late night", "饮食场景"), ("cake", "饮食场景"), ("brunch", "饮食场景"),
        ("water", "饮料"), ("sparkling", "饮料"), ("soda", "饮料"), ("coconut water", "饮料"), ("lemonade", "饮料"),
        ("beer", "酒类"), ("wine", "酒类"), ("vodka", "酒类"), ("whisky", "酒类"), ("whiskey", "酒类"), ("sake", "酒类"), ("liqueur", "酒类"), ("alcohol", "酒类"),
        ("tea", "茶叶"), ("matcha", "茶叶"), ("coffee", "咖啡"), ("espresso", "咖啡"), ("latte", "咖啡"),
        ("milk tea", "奶茶"), ("boba", "奶茶"),
        ("soup", "汤类"), ("broth", "汤类"), ("stock", "汤类"),
        ("chips", "零食"), ("crisps", "零食"), ("cookie", "零食"), ("candy", "零食"), ("chocolate", "零食"), ("ice cream", "零食"), ("popcorn", "零食"), ("jelly", "零食"), ("pudding", "零食"), ("snack", "零食"), ("gummy", "零食"), ("jerky", "零食"), ("dried meat", "零食"), ("nut", "坚果"), ("almond", "坚果"), ("walnut", "坚果"), ("cashew", "坚果"), ("peanut", "零食"), ("seed", "零食"),
        ("bread", "面包"), ("baguette", "面包"), ("croissant", "面包"), ("bun", "面包"), ("toast", "面包"), ("sandwich", "面包"), ("burger", "面包"), ("pizza", "面包"), ("rice", "面包"), ("noodle", "面包"), ("pasta", "面包"), ("oat", "面包"), ("wheat", "面包"), ("dumpling", "面包"), ("pancake", "面包"),
        ("cola", "饮料"), ("juice", "饮料"), ("sugary", "饮料"), ("soft drink", "饮料"), ("milk", "饮料"), ("yogurt", "饮料"), ("soy milk", "饮料"), ("kefir", "饮料"), ("honey", "饮料"), ("juice", "饮料"),
        ("fish", "海鲜"), ("sashimi", "海鲜"), ("tuna", "海鲜"), ("salmon", "海鲜"), ("anchovy", "海鲜"), ("sardine", "海鲜"), ("oyster", "海鲜"), ("clam", "海鲜"), ("mussel", "海鲜"), ("scallop", "海鲜"), ("crab", "海鲜"), ("shrimp", "海鲜"), ("prawn", "海鲜"), ("lobster", "海鲜"), ("squid", "海鲜"), ("octopus", "海鲜"), ("sea urchin", "海鲜"), ("caviar", "海鲜"), ("roe", "海鲜"), ("seaweed", "海鲜"), ("kelp", "海鲜"), ("jellyfish", "海鲜"), ("abalone", "海鲜"), ("cod", "海鲜"), ("mackerel", "海鲜"), ("eel", "海鲜"),
        ("liver", "肉类"), ("kidney", "肉类"), ("brain", "肉类"), ("meat", "肉类"), ("beef", "肉类"), ("pork", "肉类"), ("lamb", "肉类"), ("mutton", "肉类"), ("chicken", "肉类"), ("duck", "肉类"), ("goose", "肉类"), ("sausage", "肉类"), ("ham", "肉类"), ("bacon", "肉类"), ("hot dog", "肉类"), ("egg", "肉类"), ("steak", "肉类"), ("rib", "肉类"), ("brisket", "肉类"), ("jerky", "零食"),
        ("vegetable", "蔬菜"), ("broccoli", "蔬菜"), ("cabbage", "蔬菜"), ("spinach", "蔬菜"), ("lettuce", "蔬菜"), ("celery", "蔬菜"), ("asparagus", "蔬菜"), ("mushroom", "蔬菜"), ("fungus", "蔬菜"), ("tofu", "蔬菜"), ("bean", "蔬菜"), ("pea", "蔬菜"), ("corn", "蔬菜"), ("potato", "蔬菜"), ("yam", "蔬菜"), ("taro", "蔬菜"), ("lotus root", "蔬菜"), ("tomato", "蔬菜"), ("cucumber", "蔬菜"), ("carrot", "蔬菜"), ("radish", "蔬菜"), ("eggplant", "蔬菜"), ("pepper", "蔬菜"), ("onion", "蔬菜"), ("garlic", "蔬菜"), ("pumpkin", "蔬菜"), ("melon", "蔬菜"), ("okra", "蔬菜"), ("kale", "蔬菜"), ("sprout", "蔬菜"), ("watercress", "蔬菜"), ("chard", "蔬菜"), ("artichoke", "蔬菜"), ("cauliflower", "蔬菜"), ("zucchini", "蔬菜"),
        ("apple", "水果"), ("orange", "水果"), ("banana", "水果"), ("grape", "水果"), ("pear", "水果"), ("peach", "水果"), ("berry", "水果"), ("berries", "水果"), ("cherry", "水果"), ("mango", "水果"), ("pineapple", "水果"), ("kiwi", "水果"), ("durian", "水果"), ("watermelon", "水果"), ("melon", "水果"), ("lemon", "水果"), ("lime", "水果"), ("grapefruit", "水果"), ("pomegranate", "水果"), ("fig", "水果"), ("avocado", "水果"), ("jackfruit", "水果"), ("mangosteen", "水果"), ("guava", "水果"), ("longan", "水果"), ("rambutan", "水果"), ("lychee", "水果"), ("persimmon", "水果"), ("sugarcane", "水果"), ("date", "水果"), ("plum", "水果"), ("apricot", "水果"), ("coconut", "水果"), ("papaya", "水果"), ("strawberr", "水果"), ("blueberr", "水果"), ("cranberr", "水果"),
    ]

    /// 分类推断（关键词映射——种子没写category按名字推断；推断不出归"其他"）
    var inferredCategory: String {
        if let c = category, !c.isEmpty { return c }
        if AppLang.current == .en, let en = nameEn?.lowercased() {
            for (kw, cat) in Self.enRules where en.contains(kw) { return cat }
            return "其他"
        }
        let rules: [(String, String)] = [
            // 饮食场景优先（含复合词的食物先判场景）——健哥11-21晚令：场景扩充
            ("火锅", "饮食场景"), ("烧烤", "饮食场景"), ("自助", "饮食场景"), ("快餐", "饮食场景"), ("宴", "饮食场景"), ("聚餐", "饮食场景"),
            ("寿司", "饮食场景"), ("日式", "饮食场景"), ("日料", "饮食场景"), ("韩式", "饮食场景"), ("韩餐", "饮食场景"),
            ("酒会", "饮食场景"), ("晚宴", "饮食场景"), ("夜宵", "饮食场景"), ("聚会", "饮食场景"), ("婚宴", "饮食场景"), ("下午茶", "饮食场景"),
            // 酒类（健哥令5：伏特加/威士忌/黑啤酒——含"酒"已覆盖；白开水不能进酒类！先判水）
            ("白开水", "饮料"), ("气泡水", "饮料"), ("苏打水", "饮料"), ("椰子水", "饮料"), ("柠檬水", "饮料"), ("矿泉水", "饮料"), ("水", "饮料"),
            ("酒", "酒类"), ("啤酒", "酒类"), ("白酒", "酒类"), ("黄酒", "酒类"), ("红酒", "酒类"), ("伏特加", "酒类"), ("威士忌", "酒类"), ("清酒", "酒类"), ("梅酒", "酒类"),
            ("茶", "茶叶"), ("咖啡", "咖啡"),
            ("奶茶", "奶茶"),
            ("汤", "汤类"),
            // 零食（健哥令6+10：凉皮/布丁/酸辣粉+薯片饼干糖果族）——先于面包判
            ("凉皮", "零食"), ("酸辣粉", "零食"), ("布丁", "零食"), ("薯片", "零食"), ("薯条", "零食"), ("饼干", "零食"), ("糖果", "零食"), ("巧克力", "零食"), ("冰淇淋", "零食"), ("雪糕", "零食"), ("爆米花", "零食"), ("话梅", "零食"), ("蜜饯", "零食"), ("辣条", "零食"), ("锅巴", "零食"), ("瓜子", "零食"), ("花生", "零食"), ("坚果", "零食"), ("核桃", "零食"), ("杏仁", "坚果"), ("腰果", "坚果"), ("栗子", "零食"), ("果冻", "零食"), ("肉干", "零食"), ("肉脯", "零食"),
            ("面包", "面包"), ("蛋糕", "饮食场景"), ("糕", "面包"),
            ("可乐", "饮料"), ("汽水", "饮料"), ("果汁", "饮料"), ("含糖", "饮料"), ("饮料", "饮料"), ("奶", "饮料"), ("酸奶", "饮料"), ("豆浆", "饮料"), ("椰奶", "饮料"), ("汁", "饮料"),
            ("鱼", "海鲜"), ("虾", "海鲜"), ("蟹", "海鲜"), ("贝", "海鲜"), ("牡蛎", "海鲜"), ("蛤", "海鲜"), ("海参", "海鲜"), ("海带", "海鲜"), ("紫菜", "海鲜"), ("鱿鱼", "海鲜"), ("章鱼", "海鲜"), ("海蜇", "海鲜"), ("鲍鱼", "海鲜"), ("扇贝", "海鲜"), ("蛏", "海鲜"), ("蚬", "海鲜"), ("生蚝", "海鲜"), ("刺身", "海鲜"), ("三文鱼", "海鲜"), ("金枪鱼", "海鲜"), ("鳕鱼", "海鲜"), ("鲈鱼", "海鲜"), ("带鱼", "海鲜"), ("沙丁鱼", "海鲜"), ("凤尾鱼", "海鲜"), ("秋刀鱼", "海鲜"),
            ("肝", "肉类"), ("腰", "肉类"), ("脑", "肉类"), ("肉", "肉类"), ("牛", "肉类"), ("猪", "肉类"), ("羊", "肉类"), ("鸡", "肉类"), ("鸭", "肉类"), ("鹅", "肉类"), ("肠", "肉类"), ("火腿", "肉类"), ("培根", "肉类"), ("腊肉", "肉类"), ("香肠", "肉类"), ("热狗", "肉类"), ("蛋", "肉类"), ("培根", "肉类"),
            ("菜", "蔬菜"), ("芹", "蔬菜"), ("菠", "蔬菜"), ("笋", "蔬菜"), ("菇", "蔬菜"), ("菌", "蔬菜"), ("瓜", "蔬菜"), ("萝卜", "蔬菜"), ("番茄", "蔬菜"), ("西红柿", "蔬菜"), ("白菜", "蔬菜"), ("豆芽", "蔬菜"), ("豆", "蔬菜"), ("玉米", "蔬菜"), ("薯", "蔬菜"), ("山药", "蔬菜"), ("茄", "蔬菜"), ("椒", "蔬菜"), ("葱", "蔬菜"), ("蒜", "蔬菜"), ("西兰花", "蔬菜"), ("花椰菜", "蔬菜"), ("藕", "蔬菜"), ("芋头", "蔬菜"), ("莴笋", "蔬菜"), ("茼蒿", "蔬菜"), ("空心菜", "蔬菜"), ("生菜", "蔬菜"), ("油菜", "蔬菜"), ("韭菜", "蔬菜"), ("芦笋", "蔬菜"), ("秋葵", "蔬菜"), ("冬瓜", "蔬菜"), ("丝瓜", "蔬菜"), ("苦瓜", "蔬菜"), ("南瓜", "蔬菜"), ("黄瓜", "蔬菜"), ("胡萝卜", "蔬菜"), ("白萝卜", "蔬菜"), ("四季豆", "蔬菜"), ("豇豆", "蔬菜"),
            ("苹果", "水果"), ("橙", "水果"), ("橘", "水果"), ("香蕉", "水果"), ("梨", "水果"), ("葡萄", "水果"), ("西瓜", "水果"), ("桃", "水果"), ("莓", "水果"), ("樱桃", "水果"), ("车厘子", "水果"), ("荔", "水果"), ("芒果", "水果"), ("菠萝", "水果"), ("柚", "水果"), ("猕猴桃", "水果"), ("榴莲", "水果"), ("山楂", "水果"), ("枣", "水果"), ("果", "水果"), ("哈密瓜", "水果"), ("木瓜", "水果"), ("椰子", "水果"), ("柠檬", "水果"), ("火龙果", "水果"), ("百香果", "水果"), ("杨梅", "水果"), ("枇杷", "水果"), ("石榴", "水果"), ("柿子", "水果"), ("甘蔗", "水果"),
            ("米", "面包"), ("面", "面包"), ("燕麦", "面包"), ("麦", "面包"), ("馒头", "面包"), ("包子", "面包"), ("饺子", "面包"), ("馄饨", "面包"),
        ]
        for (kw, cat) in rules where name.contains(kw) { return cat }
        return L("Other", "其他")
    }
}

// 食物库本体（FoodItem/FoodLibrary/FoodSourceCatalog）已剥离至 Shared/FoodLibraryData.swift（v11.1 扩容）

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
    var motivationCustomText: String? = nil   // 健哥11-21令：动机选L("Other", "其他")时的自填文本（仪表盘铭牌回显）
    var lastOpenedAt: Date?
    var unitIsUmol: Bool = true
    var proUnlocked: Bool = false
    var seedVotesTotal: Int = 0
    var waterAutoFillActive: Bool = false   // A2：7天后问是否沿用上周平均；可随时关
    var dailyFoods: [String] = []           // 健哥11-21令：自定义日常饮食表（从嘌呤库选加，日后可删）
    var customScenes: [String] = []         // 健哥11-21令：自定义场景（今天吃的是一整场——用户自建，其他兜底）
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
    @Published var purineItems: [PurineItem] = [] { didSet { save() } }
    @Published var confirmedPainFreeDays: Set<Date> = [] { didSet { save() } }   // v11.1：记无痛确认日（C 方案）
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
        if let d = try? JSONEncoder().encode(purineItems) { defaults.set(d, forKey: "ur.purineItems") }
        if let d = try? JSONEncoder().encode(confirmedPainFreeDays) { defaults.set(d, forKey: "ur.confirmedPainFreeDays") }
        if let d = try? JSONEncoder().encode(profile) { defaults.set(d, forKey: "ur.profile") }
        if let d = try? JSONEncoder().encode(seed) { defaults.set(d, forKey: "ur.seed") }
        if let d = try? JSONEncoder().encode(review) { defaults.set(d, forKey: "ur.review") }
        if let d = try? JSONEncoder().encode(recall) { defaults.set(d, forKey: "ur.recall") }
        if let d = try? JSONEncoder().encode(meta) { defaults.set(d, forKey: "ur.meta") }
        // 健哥11-21令：日常食物表+自定义场景（跟meta一起走meta key？不——独立key防单块坏连坐）
        if let d = try? JSONEncoder().encode(meta.dailyFoods) { defaults.set(d, forKey: "ur.dailyFoods") }
        if let d = try? JSONEncoder().encode(meta.customScenes) { defaults.set(d, forKey: "ur.customScenes") }
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
        if let d = defaults.data(forKey: "ur.purineItems"), let x = try? JSONDecoder().decode([PurineItem].self, from: d) { purineItems = x }
        if let d = defaults.data(forKey: "ur.confirmedPainFreeDays"), let x = try? JSONDecoder().decode(Set<Date>.self, from: d) { confirmedPainFreeDays = x }
        if let d = defaults.data(forKey: "ur.profile"), let x = try? JSONDecoder().decode(HealthProfile.self, from: d) { profile = x }
        if let d = defaults.data(forKey: "ur.seed"), let x = try? JSONDecoder().decode(Seed.self, from: d) { seed = x }
        if let d = defaults.data(forKey: "ur.review"), let x = try? JSONDecoder().decode(ReviewSchedule.self, from: d) { review = x }
        if let d = defaults.data(forKey: "ur.recall"), let x = try? JSONDecoder().decode(RecallAlarm.self, from: d) { recall = x }
        if let d = defaults.data(forKey: "ur.meta"), let x = try? JSONDecoder().decode(AppMeta.self, from: d) { meta = x }
        // 健哥11-21令：日常食物表+自定义场景独立key读取（旧数据缺key=空表，零破坏）
        if let d = defaults.data(forKey: "ur.dailyFoods"), let x = try? JSONDecoder().decode([String].self, from: d) { meta.dailyFoods = x }
        if let d = defaults.data(forKey: "ur.customScenes"), let x = try? JSONDecoder().decode([String].self, from: d) { meta.customScenes = x }
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

    // ---- v11.1：重置所有数据（测试专用；#if DEBUG 包 UI 入口，本函数保留以备远程调试） ----
    func resetAllData() {
        let keys = UserDefaults.standard.dictionaryRepresentation().keys.filter { $0.hasPrefix("ur.") }
        for k in keys { defaults.removeObject(forKey: k) }
        readings = []
        flares = []
        medPlans = []
        medLogs = []
        waterDays = []
        sleepLogs = []
        foodDays = []
        weightLogs = []
        purineItems = []
        confirmedPainFreeDays = []
        profile = HealthProfile()
        seed = nil
        review = ReviewSchedule()
        recall = RecallAlarm()
        meta = AppMeta()   // onboardingDone=false → RootView 自动回 onboarding
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

    // ---- v11.1：今天吃药待办（一天 N 次出 N 次；slot 1=早 2=晚 3=午，>2 显示"第 N 次"） ----
    var todayMedTodos: [(plan: MedPlan, slot: Int, done: Bool)] {
        guard let plan = medPlans.first(where: { $0.active }) else { return [] }
        let n = max(1, plan.timesPerDay)
        let todayLogs = medLogs.filter { Calendar.current.isDateInToday($0.date) && $0.taken && $0.planRef == plan.id }
        return (1...n).map { slot in
            let done = todayLogs.contains { ($0.slot ?? 1) == slot }
            return (plan, slot, done)
        }
    }

    static func medSlotLabel(_ slot: Int) -> String {
        switch slot { case 1: return L("AM", "早"); case 2: return L("PM", "晚"); case 3: return L("noon", "午"); default: return L("#\(slot)", "第\(slot)次") }
    }

    // ---- v11.1：记无痛按钮可见条件（C 方案：有发作史+今天没记发作+今天未确认） ----
    var canConfirmPainFreeToday: Bool {
        guard !flares.isEmpty else { return false }
        if flares.contains(where: { Calendar.current.isDateInToday($0.startDate) }) { return false }
        let today = Calendar.current.startOfDay(for: Date())
        return !confirmedPainFreeDays.contains(today)
    }

    func confirmPainFreeToday() {
        confirmedPainFreeDays.insert(Calendar.current.startOfDay(for: Date()))
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
