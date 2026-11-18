import Foundation

// MARK: - 食物库 v11.1 · 2026-11-18 大扩容（数据与展示分组，Store.swift 剥离至此）
// 红区 8 分类（海鲜/腌制品/酒/饮料/肉类/浓汤/快餐零食/蔬菜干货）
// 红肉移黄区适量注意；绿区欧美扩容；每项带 source 供 ⓘ 跳数据来源页
// 证据链：ACR 2020 / 卫健委2024 / USDA-NIH / Drugs.com / NEJM 47000人研究 / Kaiser Permanente / KKH

struct FoodItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var level: String              // red(记录面板红区) / yellow(适量注意) / green(放心吃)
    var note: String?              // 一句证据注释
    var category: String           // 分类（红区8类/蛋奶/粮谷/蔬果/饮品/油脂/争议）
    var source: String = "ACR 2020"  // ⓘ 跳 FoodSourceCatalog 的锚
}

enum FoodLibrary {

    // MARK: 红区（扁平数组=饮食页多选用；groups=查阅页分类展示用，同一数据源生成）

    static let redZone: [FoodItem] = groups.flatMap { $0.items }

    // MARK: 红区 8 分类（健哥 v11.1 定版：浓汤独立+快餐零食新增）

    static let groups: [(header: String, items: [FoodItem])] = [
        ("海鲜类", [
            .init(name: "沙丁鱼", level: "red", note: "嘌呤最高档", category: "海鲜类", source: "ACR 2020"),
            .init(name: "凤尾鱼", level: "red", note: "嘌呤最高档", category: "海鲜类", source: "ACR 2020"),
            .init(name: "秋刀鱼", level: "red", note: "高嘌呤", category: "海鲜类", source: "ACR 2020"),
            .init(name: "贝类牡蛎", level: "red", note: "高嘌呤", category: "海鲜类", source: "ACR 2020"),
            .init(name: "蛤蜊扇贝", level: "red", note: "高嘌呤贝类", category: "海鲜类", source: "Drugs.com"),
            .init(name: "蟹", level: "red", note: "高嘌呤", category: "海鲜类", source: "ACR 2020"),
            .init(name: "鱼子虾籽", level: "red", note: "嘌呤浓缩", category: "海鲜类", source: "ACR 2020"),
            .init(name: "小鱼干", level: "red", note: "脱水浓缩嘌呤极高", category: "海鲜类", source: "ACR 2020"),
            .init(name: "金枪鱼刺身级", level: "red", note: "红肉部位高嘌呤", category: "海鲜类", source: "Drugs.com"),
            .init(name: "沙丁鱼罐头/鱼罐头（油浸）", level: "red", note: "浓缩+油浸双重", category: "海鲜类", source: "Drugs.com"),
        ]),
        ("腌制品类", [
            .init(name: "腊肠腊肉", level: "red", note: "腌制浓缩+高盐", category: "腌制品类", source: "Drugs.com"),
            .init(name: "咸鱼", level: "red", note: "腌制浓缩嘌呤", category: "腌制品类", source: "Drugs.com"),
            .init(name: "火腿", level: "red", note: "加工肉——NEJM 研究加工肉与痛风风险相关", category: "腌制品类", source: "NEJM 47000人研究"),
            .init(name: "培根", level: "red", note: "加工肉+高脂", category: "腌制品类", source: "NEJM 47000人研究"),
            .init(name: "香肠/热狗肠", level: "red", note: "加工肉（hot dog 同源）", category: "腌制品类", source: "NEJM 47000人研究"),
            .init(name: "午餐肉", level: "red", note: "加工肉", category: "腌制品类", source: "Drugs.com"),
        ]),
        ("酒类", [
            .init(name: "啤酒", level: "red", note: "嘌呤+酒精双杀，痛风第一诱因", category: "酒类", source: "ACR 2020"),
            .init(name: "精酿/IPA", level: "red", note: "啤酒同族", category: "酒类", source: "Drugs.com"),
            .init(name: "白酒", level: "red", note: "酒精抑制尿酸排泄", category: "酒类", source: "ACR 2020"),
            .init(name: "黄酒", level: "red", note: "酒精抑制尿酸排泄", category: "酒类", source: "ACR 2020"),
            .init(name: "威士忌/伏特加等烈酒", level: "red", note: "酒精抑制排泄", category: "酒类", source: "Drugs.com"),
        ]),
        ("饮料类", [
            .init(name: "可乐/含糖碳酸", level: "red", note: "果糖促生成抑排泄——男每周≥4杯风险+49%", category: "饮料类", source: "卫健委2024"),
            .init(name: "奶茶", level: "red", note: "果糖+奶精反式脂肪", category: "饮料类", source: "卫健委2024"),
            .init(name: "果汁（含纯果汁）", level: "red", note: "去纤维后果糖浓缩；卫健委2024明确避免", category: "饮料类", source: "卫健委2024"),
            .init(name: "功能饮料（含糖）", level: "red", note: "高果糖玉米糖浆载体", category: "饮料类", source: "NEJM 47000人研究"),
            .init(name: "蜂蜜", level: "red", note: "果糖占比约50%，尽量不吃", category: "饮料类", source: "卫健委2024"),
        ]),
        ("肉类", [
            .init(name: "动物内脏（肝/肾/脑/肠肚）", level: "red", note: "高嘌呤经典雷区", category: "肉类", source: "ACR 2020"),
        ]),
        ("浓汤类", [
            .init(name: "老火汤/浓肉汤", level: "red", note: "嘌呤溶于水，汤=浓缩液", category: "浓汤类", source: "ACR 2020"),
            .init(name: "火锅汤底", level: "red", note: "涮煮浓缩嘌呤", category: "浓汤类", source: "ACR 2020"),
            .init(name: "肉汁浓汤（gravy）", level: "red", note: "肉类提取物——欧美同雷", category: "浓汤类", source: "Drugs.com"),
            .init(name: "鸡精/浓汤宝类调料", level: "red", note: "肉类提取物浓缩", category: "浓汤类", source: "Drugs.com"),
        ]),
        ("快餐零食类", [
            .init(name: "汉堡", level: "red", note: "红肉饼+酱料果糖——NEJM 研究总肉量最高组风险+41%", category: "快餐零食类", source: "NEJM 47000人研究"),
            .init(name: "热狗", level: "red", note: "加工肉+白面包+含糖酱多重打击", category: "快餐零食类", source: "NEJM 47000人研究"),
            .init(name: "披萨", level: "red", note: "加工肉配料+精制碳水", category: "快餐零食类", source: "Gout Education"),
            .init(name: "炸鸡", level: "red", note: "禽皮+油炸高脂", category: "快餐零食类", source: "Gout Education"),
            .init(name: "薯条等油炸食品", level: "red", note: "油炸高脂影响排泄", category: "快餐零食类", source: "Gout Education"),
            .init(name: "辣条/薯片等包装零食", level: "red", note: "加工食品+添加剂", category: "快餐零食类", source: "Gout Education"),
            .init(name: "肉干肉脯", level: "red", note: "腌制浓缩嘌呤", category: "快餐零食类", source: "Drugs.com"),
        ]),
        ("蔬菜干货类", [
            .init(name: "脱水香菇/干菌菇", level: "red", note: "脱水浓缩嘌呤极高（鲜菌菇是低嘌呤）", category: "蔬菜干货类", source: "Drugs.com"),
            .init(name: "紫菜海带干", level: "red", note: "干制浓缩", category: "蔬菜干货类", source: "Drugs.com"),
            .init(name: "酵母提取物零食（营养酵母）", level: "red", note: "嘌呤很高——健身圈常用需注意", category: "蔬菜干货类", source: "Drugs.com"),
        ]),
    ]

    // MARK: 场景按钮（点了自动记红+关联项）

    static let scenes: [(name: String, autoItems: [String])] = [
        ("火锅", ["老火汤/浓肉汤"]),
        ("烧烤", ["猪牛羊红肉", "啤酒"]),
        ("海鲜自助", ["贝类牡蛎", "蟹"]),
        ("快餐（汉堡披萨等）", ["汉堡", "可乐/含糖碳酸"]),
    ]

    // MARK: 黄区 适量注意（健哥 v11.1 裁定：红肉移入+禽肉/坚果补入）

    static let yellowZone: [FoodItem] = [
        .init(name: "猪牛羊红肉", level: "yellow", note: "中嘌呤——适量注意，请勿大量（每餐一两内别当主菜）", category: "适量注意", source: "NEJM 47000人研究"),
        .init(name: "鸡胸肉等禽肉", level: "yellow", note: "白肉好于红肉，仍是中嘌呤——适量", category: "适量注意", source: "Drugs.com"),
        .init(name: "豆腐/豆浆", level: "yellow", note: "2024卫健委指南可适量——保守标注", category: "适量注意", source: "卫健委2024"),
        .init(name: "淡水鱼（草鱼/鲫鱼）", level: "yellow", note: "平稳期50-100g每周2-3次，急性期避开；吃肉不喝汤", category: "适量注意", source: "卫健委2024"),
        .init(name: "菠菜/芦笋/蘑菇/菜花（鲜）", level: "yellow", note: "老观念平反：植物嘌呤几乎不升痛风风险——保守适量", category: "适量注意", source: "ACR 2020"),
        .init(name: "坚果/花生酱", level: "yellow", note: "低嘌呤但高脂——适量", category: "适量注意", source: "Drugs.com"),
        .init(name: "燕麦（大量时）", level: "yellow", note: "常规量低嘌呤，当主食大量吃时注意", category: "适量注意", source: "Drugs.com"),
        .init(name: "香蕉/无花果/葡萄干", level: "yellow", note: "个别指南列中嘌呤——完整水果适量无碍", category: "适量注意", source: "Drugs.com"),
        .init(name: "全脂奶/黄油", level: "yellow", note: "选低脂脱脂版本更好", category: "适量注意", source: "Kaiser Permanente"),
    ]

    // MARK: 绿区 放心吃（中低嘌呤清单——欧美扩容版）

    static let greenZone: [FoodItem] = [
        // 蛋奶（低脂乳制品降尿酸证据）
        .init(name: "鸡蛋", level: "green", note: "低嘌呤优质蛋白", category: "蛋奶", source: "ACR 2020"),
        .init(name: "脱脂奶/低脂奶", level: "green", note: "降尿酸证据（保护性）", category: "蛋奶", source: "Kaiser Permanente"),
        .init(name: "低脂酸奶/希腊酸奶", level: "green", note: "低脂乳制品保护性", category: "蛋奶", source: "Kaiser Permanente"),
        .init(name: "低脂芝士/Cottage Cheese", level: "green", note: "低脂乳制品保护性", category: "蛋奶", source: "Drugs.com"),
        // 粮谷
        .init(name: "米饭/面条", level: "green", note: "低嘌呤主食放心吃", category: "粮谷", source: "ACR 2020"),
        .init(name: "面包/馒头", level: "green", note: "低嘌呤；发酵面食略高于米饭面条，正常量无碍", category: "粮谷", source: "Drugs.com"),
        .init(name: "意面", level: "green", note: "低嘌呤主食", category: "粮谷", source: "Drugs.com"),
        .init(name: "燕麦（常规量）", level: "green", note: "低嘌呤粗粮", category: "粮谷", source: "ACR 2020"),
        .init(name: "玉米片（低糖）", level: "green", note: "低嘌呤", category: "粮谷", source: "Drugs.com"),
        .init(name: "藜麦 Quinoa", level: "green", note: "低嘌呤全谷", category: "粮谷", source: "Drugs.com"),
        .init(name: "荞麦面", level: "green", note: "低嘌呤", category: "粮谷", source: "Drugs.com"),
        .init(name: "爆米花（原味）", level: "green", note: "低嘌呤零食（别加黄油大量）", category: "粮谷", source: "Drugs.com"),
        .init(name: "土豆/红薯", level: "green", note: "低嘌呤", category: "粮谷", source: "ACR 2020"),
        // 蔬果
        .init(name: "大部分新鲜蔬菜", level: "green", note: "植物嘌呤对痛风风险几乎无影响", category: "蔬果", source: "ACR 2020"),
        .init(name: "番茄", level: "green", note: "低嘌呤", category: "蔬果", source: "Kaiser Permanente"),
        .init(name: "黄瓜/白菜/胡萝卜", level: "green", note: "低嘌呤", category: "蔬果", source: "ACR 2020"),
        .init(name: "樱桃", level: "green", note: "降发作风险证据（保护性）", category: "蔬果", source: "ACR 2020"),
        .init(name: "苹果/橙子", level: "green", note: "完整水果膳食纤维缓冲果糖", category: "蔬果", source: "卫健委2024"),
        .init(name: "草莓/蓝莓", level: "green", note: "低果糖浆风险的水果", category: "蔬果", source: "Drugs.com"),
        .init(name: "西瓜/葡萄", level: "green", note: "低嘌呤水果", category: "蔬果", source: "ACR 2020"),
        // 饮品
        .init(name: "水", level: "green", note: "每日2000-3000ml——最便宜的药", category: "饮品", source: "卫健委2024"),
        .init(name: "咖啡", level: "green", note: "长期饮用降尿酸证据（不加糖奶精）", category: "饮品", source: "Kaiser Permanente"),
        .init(name: "淡茶", level: "green", note: "低嘌呤可饮，避免加糖加奶精", category: "饮品", source: "Drugs.com"),
        .init(name: "脱脂奶饮品", level: "green", note: "保护性饮品", category: "饮品", source: "Kaiser Permanente"),
        // 脂肪油脂（零嘌呤——做饭自由度）
        .init(name: "橄榄油/植物油", level: "green", note: "油脂类零嘌呤，做饭可用", category: "油脂", source: "Drugs.com"),
        .init(name: "牛油果油", level: "green", note: "零嘌呤油脂", category: "油脂", source: "Drugs.com"),
        // 蛋白补充
        .init(name: "乳清蛋白（低脂）", level: "green", note: "健身蛋白替代红肉的选择", category: "蛋奶", source: "Drugs.com"),
    ]
}

// MARK: - 数据来源目录（ⓘ 跳转目标——信任件）

enum FoodSourceCatalog {
    static let all: [(name: String, desc: String)] = [
        ("ACR 2020", "美国风湿病学会 2020 痛风管理指南——国际痛风诊疗权威标准，饮食建议基于系统证据综述。"),
        ("卫健委2024", "国家卫生健康委《成人高尿酸血症与痛风食养指南（2024年版）》——中国官方食养标准。"),
        ("USDA-NIH 嘌呤数据库", "美国农业部与国立卫生研究院联合发布的食物嘌呤含量数据库——成分数据的一手来源。"),
        ("Drugs.com Low Purine Diet", "Drugs.com 低嘌呤饮食临床指引——面向患者的循证饮食清单。"),
        ("NEJM 47000人研究", "新英格兰医学杂志对 4.7 万男性的长期队列研究——肉类（含汉堡热狗）摄入量最高组痛风风险 +41%。"),
        ("Kaiser Permanente", "美国凯撒医疗集团患者教育材料——低脂乳制品降尿酸的循证建议来源。"),
        ("KKH 新加坡", "新加坡竹脚妇幼医院嘌呤限制饮食指引——亚洲人群饮食参照。"),
        ("Gout Education", "国际痛风教育学会（Gout Education Society）——快餐加工食品与果葡糖浆的官方警示来源。"),
    ]
}
