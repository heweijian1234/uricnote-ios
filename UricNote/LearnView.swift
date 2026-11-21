import SwiftUI
import StoreKit   // CI run 44311079867：SKStoreReviewController 需要（v11.1 评分弹窗）

// MARK: - Tab4 了解（愿景页入口+误区8卡+嘌呤库+反馈+更新日志）

struct LearnView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink {
                        VisionPageView()
                    } label: {
                        HStack {
                            Image(systemName: "book.fill").foregroundColor(.brand)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("为什么是它").font(.body.weight(.medium))
                                Text("核心功能、理念、期望——一页看懂").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // 健哥11-21令：高尿酸危害介绍
                Section {
                    NavigationLink {
                        HarmIntroView()
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.warn)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("高尿酸的危害").font(.body.weight(.medium))
                                Text("不只是痛风——了解它对身体的影响").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section("先破除几个误区") {
                    NavigationLink("8 个最常见的误区") { MythListView() }
                    NavigationLink("嘌呤食物库") { PurineListView() }
                }

                Section("和你一起变好") {
                    // v11.1 #6：反馈独立一级页（健哥令：需要足够的用户反馈）
                    NavigationLink {
                        FeedbackPage()
                    } label: {
                        HStack {
                            Image(systemName: "envelope.circle.fill").foregroundColor(.brand)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("反馈与更新日志").font(.body.weight(.medium))
                                Text("批评最有价值——每一条都会被认真读").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    Button("给我们评分") {
                        // 健哥11-21令修：评分弹窗有365天3次配额，满了就静默——加跳App Store评论页兜底（永远有效）
                        FeedbackHelper.requestReview()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            FeedbackHelper.openStoreReviewPage()
                        }
                    }
                    .foregroundColor(.brand)
                }

                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("UricNote v0.1.0").font(.caption.weight(.medium))
                            Text("© 2026 WEI JIAN HE · 记录工具，不构成诊疗建议").font(.caption2).foregroundColor(.secondary)
                            Text("数据来源：ACR 2020 / G-CAN 2024 / 公开临床试验").font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("了解")
        }
    }

    private func SKStoreStoreReview() {}
}

// MARK: - 愿景页（Onboarding 第3步同款+独立入口）

struct VisionPageView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("这不只是一份记录。")
                    .font(.title.bold())
                Text("这是一次尊重身体，自我救赎的蜕变。愿你能更幸福的生活。")
                    .font(.body)
                    .foregroundColor(.secondary)

                Divider()

                Text("我们相信").font(.headline)
                Text("尿酸降不下来，从来不是因为你不努力——七成由身体代谢决定，剩下三成才轮到生活方式。这里不评判你，只帮你把能控制的三成管好，只需要养成习惯。").font(.callout)

                Text("现在就能用").font(.headline)
                visionRow("fork.knife", "食物嘌呤清单，带临床指南背书")
                visionRow("brain", "每天回忆记录，寻找疼痛的嘌呤因子进行改善")
                visionRow("pills", "提醒吃药，记录喝水量习惯")
                visionRow("doc.text", "一页报告带给医生，让他快速且详细的了解你的近况，获得更准确的建议")

                Text("会随时间长大").font(.headline)
                visionRow("chart.line.uptrend.xyaxis", "会随时间记录，画出你的蜕变之路")
                visionRow("calendar", "7 天后，看到你的习惯趋势线")
                visionRow("sparkles", "一个月后，发现疼痛前共同吃了什么")
                visionRow("figure.walk", "更远处：我是一直陪你走过来的朋友")

                Text("选择我的理由").font(.headline)
                visionRow("person.crop.circle.badge.checkmark", "开发者本人就是高尿酸痛风患者，正在改善的路上，此 App 是自用也是想帮助更多患友")
                visionRow("checkmark.seal", "免费使用，持续更新，日后不排除买断制与订阅制，但与你无关——开发初期，下载的患友都是终身免费使用")
                visionRow("stethoscope", "设计依据是公开的临床试验节律，不是营销噱头")
                visionRow("wand.and.stars", "设计细节会加入开发者的个人心得")

                Text("本 App 是记录工具，不提供诊断或治疗建议。\n数据来源：ACR 2020 指南 / G-CAN 2024 缓解标准 / 公开临床试验。")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("为什么是它")
    }

    private func visionRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundColor(.brand).frame(width: 22)
            Text(text).font(.callout)
        }
    }
}

// MARK: - 误区 8 卡（v7/v8 定稿内容：误区原话+一句事实+出处）

struct Myth: Identifiable {
    let id: Int
    let myth: String
    let fact: String
    let source: String
}

let myths: [Myth] = [
    Myth(id: 1, myth: "「管住嘴就不用每天吃药」",
         fact: "饮食控制很重要，但 70-80% 的尿酸由身体代谢（基因）决定。单靠饮食平均只能降 1-1.5 mg/dL——多数人达不到目标。饮食和药物是搭档，不是二选一。",
         source: "Arthritis Australia"),
    Myth(id: 2, myth: "「不疼了就是好了，可以停药」",
         fact: "不疼只是结晶暂时没发作；尿酸不达标时结晶仍在积累。停药后多数人半年内复发。「不疼」恰恰说明药物在起作用。",
         source: "NICE 指南 / RheumNow"),
    Myth(id: 3, myth: "「痛风只长在脚趾」",
         fact: "55% 的人这么以为，但脚踝、膝盖、手指、手腕、手肘都可能发作。这正是本 App 支持多关节记录的原因。",
         source: "美国痛风教育学会全国调查 2026"),
    Myth(id: 4, myth: "「啤酒最伤，其他酒没事」",
         fact: "啤酒诱发最强没错，但所有酒精（白酒、红酒、洋酒）都会升尿酸。减少总酒精量比只戒啤酒更有效。",
         source: "Arthritis Australia"),
    Myth(id: 5, myth: "「樱桃/芹菜籽能治痛风」",
         fact: "有些初步研究，但证据很弱，远不能替代药物。可以吃，别指望它。",
         source: "FSSAI 误区手册 2019 / OTCFood"),
    Myth(id: 6, myth: "「豆制品和嘌呤蔬菜不能吃」",
         fact: "这是老观念——现代指南已撤回此禁忌。植物嘌呤与痛风发作的关联很弱，豆腐豆浆可以正常吃。",
         source: "现代指南共识（OTCFood 盘点）"),
    Myth(id: 7, myth: "「吃药伤肝，不能长期吃」",
         fact: "定期复查肝肾功能正是复查日的用途——在监测下的长期用药是标准方案。怕伤肝的正确做法是按时复查，不是自行停药。",
         source: "ACR 2020 指南"),
    Myth(id: 8, myth: "「我还年轻，不会得痛风」",
         fact: "全球年轻人（15-39 岁）痛风发病率 30 年来没有一个地区在下降；韩国 20-30 岁男性尿酸异常率超 43%。年轻不是免死牌。",
         source: "GBD 青年负担研究 2023 / 韩国体检数据 2024"),
    Myth(id: 9, myth: "「痛风发作就该静养，千万不能运动」",
         fact: "发作期确实要休息，但缓解期规律运动（快走/游泳）是降尿酸的生活处方之一——运动减重对尿酸的改善有明确证据。怕的是「从不运动」，不是「适度运动」。",
         source: "ACR 2020 指南 / 临床共识"),
    Myth(id: 10, myth: "「鸡蛋是发物，痛风不能吃」",
         fact: "鸡蛋嘌呤极低（约 2mg/100g），是痛风患者最安全的蛋白质来源之一。每天一个鸡蛋不需要顾虑。",
         source: "ACR 2020 指南食物表"),
    Myth(id: 11, myth: "「咖啡对痛风不好，要戒掉」",
         fact: "多项队列研究显示长期喝咖啡与更低的尿酸水平相关（中性偏正面）。无糖黑咖啡可以继续喝——别加糖和奶精就好。",
         source: "队列研究综述（中性偏正面证据）"),
    Myth(id: 12, myth: "「我要下决心，从今天起滴酒不沾」",
         fact: "决心值得肯定，但断崖式戒酒容易反弹。更稳的路径是逐步减量+记录——用 App 的饮酒标记看着自己的趋势往下走，比意志力硬扛成功率高。",
         source: "行为设计研究（Tiny Habits，Fogg 2019）/ 临床共识"),
]

struct MythListView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(myths) { m in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(m.myth)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.red.opacity(0.85))
                        Text(m.fact)
                            .font(.callout)
                        Text("来源：\(m.source)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.cardBG)
                    .cornerRadius(14)
                }
                Text("以上为患者共识科普，不构成诊疗建议。具体用药请遵医嘱。")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("误区 vs 事实")
    }
}

// MARK: - 嘌呤库（红黄绿+sourceTag；内置首批种子数据，搜索过滤）

struct PurineListView: View {
    @ObservedObject var store = Store.shared
    @State private var query = ""
    // 🔴健哥令 2026-11-15：默认先看"能吃什么"（绿灯优先）——患者打开 food 库全是禁忌会心情糟糕/抗拒（v8 情绪设计：先给希望再给边界）
    @State private var tab = 0   // 0=绿灯能吃 1=黄灯适量 2=红灯注意
    // 健哥11-21令：分类导航（健哥11-21晚令+零食）
    @State private var category = "全部"
    static let categories = ["全部", "蔬菜", "水果", "肉类", "海鲜", "酒类", "饮料", "奶茶", "茶叶", "咖啡", "坚果", "零食", "面包", "汤类", "饮食场景", "其他"]

    var body: some View {
        List {
            Section {
                Picker("", selection: $tab) {
                    Text("✓ 能吃").tag(0)
                    Text("适量").tag(1)
                    Text("注意").tag(2)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                // 健哥11-21晚令3：分类全展示（网格 chips，不横拉——横拉用户看不见）
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                    ForEach(Self.categories, id: \.self) { c in
                        Button {
                            category = c
                        } label: {
                            Text(c)
                                .font(.caption.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(category == c ? Color.brand : Color.gray.opacity(0.12))
                                .foregroundColor(category == c ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.vertical, 2)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            } header: {
                Text("嘌呤食物库")
            } footer: {
                // 健哥11-21晚令1：添加按钮说明
                Text(tab == 0 ? "" : "点「添加」把食物加进仪表盘 → 饮食页的「我的日常饮食表」，天天点选不用翻库。")
            }

            let items = filtered.sorted { $0.name < $1.name }
            if items.isEmpty {
                Text(tab == 0 ? "这个搜索词下没有低嘌呤推荐——换个词试试，或看看「注意」页（可能它确实要少吃）。" : "这个搜索词下没有记录。")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            }
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        circle(for: item.level)
                        Text(item.name).font(.body.weight(.medium))
                        Spacer()
                        // 健哥11-21晚令1：右侧"添加"按钮（仅适量/注意列——能吃列不需要记）
                        if tab != 0 {
                            if store.meta.dailyFoods.contains(item.name) {
                                Button("已添加") {
                                    store.meta.dailyFoods.removeAll { $0 == item.name }
                                    store.save()
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.bordered)
                                .tint(.brand)
                            } else {
                                Button("添加") {
                                    store.meta.dailyFoods.append(item.name)
                                    store.save()
                                    UricCelebrate.show("已加到日常饮食表")
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.borderedProminent)
                                .tint(.brand)
                            }
                        }
                        Text(levelName(item.level))
                            .font(.caption)
                            .foregroundColor(color(for: item.level))
                    }
                    Text("嘌呤约 \(Int(item.uricPer100g)) mg/100g · \(item.sourceTag)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .searchable(text: $query, prompt: "搜食物，比如：鸡蛋 / 牛奶 / 啤酒")
        .navigationTitle("嘌呤食物库")
        .onAppear {
            if store.purineItems.isEmpty {
                store.purineItems = PurineDatabase.seed
                store.save()
            }
        }
    }

    private var filtered: [PurineItem] {
        let byQuery = store.purineItems.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
        // 按选中的Tab过滤：绿灯/黄灯/红灯
        let levelKey = ["green", "yellow", "red"][tab]
        // 健哥11-21令：分类过滤（"全部"不过滤；推断不出归"其他"）
        let byCategory = category == "全部" ? byQuery : byQuery.filter { $0.inferredCategory == category }
        return byCategory.filter { $0.level == levelKey }
    }

    private func circle(for level: String) -> some View {
        Circle().fill(color(for: level)).frame(width: 10, height: 10)
    }
    private func color(for level: String) -> Color {
        level == "red" ? .red : (level == "yellow" ? .orange : .green)
    }
    private func levelName(_ level: String) -> String {
        level == "red" ? "红灯 · 高嘌呤" : (level == "yellow" ? "黄灯 · 中嘌呤" : "绿灯 · 低嘌呤")
    }
}

// 首批种子库（≈60 条高频；完整库上架前扩充——来源标注 ACR 2020 指南口径）
enum PurineDatabase {
    static let seed: [PurineItem] = [
        .init(name: "啤酒", uricPer100g: 30, level: "red", sourceTag: "ACR 2020"),
        .init(name: "白酒", uricPer100g: 0, level: "red", sourceTag: "ACR 2020"),
        .init(name: "动物内脏（肝/腰/脑）", uricPer100g: 300, level: "red", sourceTag: "ACR 2020"),
        .init(name: "浓肉汤", uricPer100g: 400, level: "red", sourceTag: "ACR 2020"),
        .init(name: "沙丁鱼", uricPer100g: 345, level: "red", sourceTag: "ACR 2020"),
        .init(name: "凤尾鱼", uricPer100g: 240, level: "red", sourceTag: "ACR 2020"),
        .init(name: "带鱼", uricPer100g: 192, level: "red", sourceTag: "ACR 2020"),
        .init(name: "牡蛎", uricPer100g: 240, level: "red", sourceTag: "ACR 2020"),
        .init(name: "蛤蜊", uricPer100g: 160, level: "red", sourceTag: "ACR 2020"),
        .init(name: "鹅肉", uricPer100g: 165, level: "red", sourceTag: "ACR 2020"),
        .init(name: "猪肝", uricPer100g: 290, level: "red", sourceTag: "ACR 2020"),
        .init(name: "猪腰", uricPer100g: 220, level: "red", sourceTag: "ACR 2020"),
        .init(name: "脑花", uricPer100g: 260, level: "red", sourceTag: "ACR 2020"),
        .init(name: "猪肉（五花）", uricPer100g: 160, level: "red", sourceTag: "ACR 2020"),
        .init(name: "牛肉", uricPer100g: 120, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "羊肉", uricPer100g: 120, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "鸡肉", uricPer100g: 110, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "鸭肉", uricPer100g: 115, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "三文鱼", uricPer100g: 110, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "金枪鱼", uricPer100g: 140, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "鲤鱼", uricPer100g: 130, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "基围虾", uricPer100g: 145, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "螃蟹", uricPer100g: 82, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "豆腐", uricPer100g: 55, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "豆浆", uricPer100g: 28, level: "green", sourceTag: "ACR 2020"),
        .init(name: "扁豆（干）", uricPer100g: 75, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "四季豆", uricPer100g: 20, level: "green", sourceTag: "ACR 2020"),
        .init(name: "芦笋", uricPer100g: 23, level: "green", sourceTag: "ACR 2020"),
        .init(name: "菠菜", uricPer100g: 23, level: "green", sourceTag: "ACR 2020"),
        .init(name: "蘑菇", uricPer100g: 25, level: "green", sourceTag: "ACR 2020"),
        .init(name: "西兰花", uricPer100g: 20, level: "green", sourceTag: "ACR 2020"),
        .init(name: "鸡蛋", uricPer100g: 2, level: "green", sourceTag: "ACR 2020"),
        .init(name: "低脂牛奶", uricPer100g: 1, level: "green", sourceTag: "ACR 2020"),
        .init(name: "酸奶（低脂）", uricPer100g: 8, level: "green", sourceTag: "ACR 2020"),
        .init(name: "樱桃", uricPer100g: 5, level: "green", sourceTag: "ACR 2020"),
        .init(name: "苹果", uricPer100g: 3, level: "green", sourceTag: "ACR 2020"),
        .init(name: "香蕉", uricPer100g: 4, level: "green", sourceTag: "ACR 2020"),
        .init(name: "西瓜", uricPer100g: 2, level: "green", sourceTag: "ACR 2020"),
        .init(name: "米饭", uricPer100g: 8, level: "green", sourceTag: "ACR 2020"),
        .init(name: "面条", uricPer100g: 10, level: "green", sourceTag: "ACR 2020"),
        .init(name: "全麦面包", uricPer100g: 15, level: "green", sourceTag: "ACR 2020"),
        .init(name: "土豆", uricPer100g: 6, level: "green", sourceTag: "ACR 2020"),
        .init(name: "红薯", uricPer100g: 8, level: "green", sourceTag: "ACR 2020"),
        .init(name: "黄瓜", uricPer100g: 3, level: "green", sourceTag: "ACR 2020"),
        .init(name: "番茄", uricPer100g: 4, level: "green", sourceTag: "ACR 2020"),
        .init(name: "胡萝卜", uricPer100g: 5, level: "green", sourceTag: "ACR 2020"),
        .init(name: "白菜", uricPer100g: 3, level: "green", sourceTag: "ACR 2020"),
        .init(name: "橙汁（含糖）", uricPer100g: 10, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "可乐（含糖）", uricPer100g: 2, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "蜂蜜", uricPer100g: 5, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "花生", uricPer100g: 79, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "豆腐（北）", uricPer100g: 68, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "豆干", uricPer100g: 75, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "扁豆", uricPer100g: 75, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "豌豆", uricPer100g: 76, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "猪肚", uricPer100g: 132, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "火腿", uricPer100g: 120, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "腰果", uricPer100g: 60, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "核桃", uricPer100g: 25, level: "green", sourceTag: "ACR 2020"),
        // ===== 绿灯扩展（健哥令 11-15：能吃的要丰富——先看希望再看边界）=====
        .init(name: "葡萄", uricPer100g: 4, level: "green", sourceTag: "ACR 2020"),
        .init(name: "梨", uricPer100g: 3, level: "green", sourceTag: "ACR 2020"),
        .init(name: "桃子", uricPer100g: 4, level: "green", sourceTag: "ACR 2020"),
        .init(name: "橙子", uricPer100g: 3, level: "green", sourceTag: "ACR 2020"),
        .init(name: "柚子", uricPer100g: 4, level: "green", sourceTag: "ACR 2020"),
        .init(name: "草莓", uricPer100g: 5, level: "green", sourceTag: "ACR 2020"),
        .init(name: "蓝莓", uricPer100g: 5, level: "green", sourceTag: "ACR 2020"),
        .init(name: "哈密瓜", uricPer100g: 4, level: "green", sourceTag: "ACR 2020"),
        .init(name: "菠萝", uricPer100g: 5, level: "green", sourceTag: "ACR 2020"),
        .init(name: "芒果", uricPer100g: 4, level: "green", sourceTag: "ACR 2020"),
        .init(name: "红枣（鲜）", uricPer100g: 6, level: "green", sourceTag: "ACR 2020"),
        .init(name: "生菜", uricPer100g: 4, level: "green", sourceTag: "ACR 2020"),
        .init(name: "油麦菜", uricPer100g: 5, level: "green", sourceTag: "ACR 2020"),
        .init(name: "空心菜", uricPer100g: 6, level: "green", sourceTag: "ACR 2020"),
        .init(name: "芹菜", uricPer100g: 5, level: "green", sourceTag: "ACR 2020"),
        .init(name: "冬瓜", uricPer100g: 3, level: "green", sourceTag: "ACR 2020"),
        .init(name: "南瓜", uricPer100g: 4, level: "green", sourceTag: "ACR 2020"),
        .init(name: "丝瓜", uricPer100g: 4, level: "green", sourceTag: "ACR 2020"),
        .init(name: "茄子", uricPer100g: 5, level: "green", sourceTag: "ACR 2020"),
        .init(name: "青椒", uricPer100g: 5, level: "green", sourceTag: "ACR 2020"),
        .init(name: "白萝卜", uricPer100g: 5, level: "green", sourceTag: "ACR 2020"),
        .init(name: "西红柿", uricPer100g: 4, level: "green", sourceTag: "ACR 2020"),
        .init(name: "花菜", uricPer100g: 22, level: "green", sourceTag: "ACR 2020"),
        .init(name: "玉米", uricPer100g: 9, level: "green", sourceTag: "ACR 2020"),
        .init(name: "山药", uricPer100g: 8, level: "green", sourceTag: "ACR 2020"),
        .init(name: "芋头", uricPer100g: 10, level: "green", sourceTag: "ACR 2020"),
        .init(name: "藕", uricPer100g: 12, level: "green", sourceTag: "ACR 2020"),
        .init(name: "小米粥", uricPer100g: 6, level: "green", sourceTag: "ACR 2020"),
        .init(name: "燕麦", uricPer100g: 12, level: "green", sourceTag: "ACR 2020"),
        .init(name: "馒头", uricPer100g: 9, level: "green", sourceTag: "ACR 2020"),
        .init(name: "脱脂酸奶", uricPer100g: 8, level: "green", sourceTag: "ACR 2020"),
        .init(name: "酸奶", uricPer100g: 10, level: "green", sourceTag: "ACR 2020"),
        .init(name: "蛋白（蛋清）", uricPer100g: 1, level: "green", sourceTag: "ACR 2020"),
        .init(name: "车厘子", uricPer100g: 5, level: "green", sourceTag: "ACR 2020"),
        .init(name: "柠檬水（无糖）", uricPer100g: 1, level: "green", sourceTag: "ACR 2020"),
        .init(name: "白开水", uricPer100g: 0, level: "green", sourceTag: "ACR 2020"),
        .init(name: "淡茶水", uricPer100g: 1, level: "green", sourceTag: "ACR 2020"),
        .init(name: "咖啡（黑，无糖）", uricPer100g: 2, level: "green", sourceTag: "ACR 2020"),
        .init(name: "橄榄油", uricPer100g: 0, level: "green", sourceTag: "ACR 2020"),
        .init(name: "海蜇皮", uricPer100g: 18, level: "green", sourceTag: "ACR 2020"),
        .init(name: "海参（水发）", uricPer100g: 12, level: "green", sourceTag: "ACR 2020"),
        // ===== 地区性扩展（首发六区：中/美/日/德/英/澳——健哥令 11-15）=====
        .init(name: "豆浆（无糖）", uricPer100g: 3, level: "green", sourceTag: "ACR 2020"),
        .init(name: "薏米水", uricPer100g: 2, level: "green", sourceTag: "ACR 2020"),
        .init(name: "绿豆汤（无糖）", uricPer100g: 4, level: "green", sourceTag: "ACR 2020"),
        .init(name: "苏打水（无糖）", uricPer100g: 0, level: "green", sourceTag: "ACR 2020"),
        .init(name: "黑咖啡", uricPer100g: 2, level: "green", sourceTag: "ACR 2020"),
        .init(name: "拿铁（低脂奶）", uricPer100g: 3, level: "green", sourceTag: "ACR 2020"),
        .init(name: "麦片", uricPer100g: 12, level: "green", sourceTag: "ACR 2020"),
        .init(name: "全麦意面", uricPer100g: 14, level: "green", sourceTag: "ACR 2020"),
        .init(name: "白面包", uricPer100g: 10, level: "green", sourceTag: "ACR 2020"),
        .init(name: "贝果", uricPer100g: 12, level: "green", sourceTag: "ACR 2020"),
        .init(name: "玉米片（低糖）", uricPer100g: 8, level: "green", sourceTag: "ACR 2020"),
        .init(name: "藜麦", uricPer100g: 18, level: "green", sourceTag: "ACR 2020"),
        .init(name: "荞麦面", uricPer100g: 12, level: "green", sourceTag: "ACR 2020"),
        .init(name: "年糕", uricPer100g: 9, level: "green", sourceTag: "ACR 2020"),
        .init(name: "黑麦面包（德式）", uricPer100g: 13, level: "green", sourceTag: "ACR 2020"),
        .init(name: "椒盐卷饼（德式）", uricPer100g: 11, level: "green", sourceTag: "ACR 2020"),
        .init(name: "酸菜（德式泡菜）", uricPer100g: 6, level: "green", sourceTag: "ACR 2020"),
        .init(name: "土豆泥（无奶油）", uricPer100g: 7, level: "green", sourceTag: "ACR 2020"),
        .init(name: "燕麦粥", uricPer100g: 11, level: "green", sourceTag: "ACR 2020"),
        .init(name: "英式早餐茶", uricPer100g: 1, level: "green", sourceTag: "ACR 2020"),
        .init(name: "约克郡布丁", uricPer100g: 12, level: "green", sourceTag: "ACR 2020"),
        .init(name: "鱼罐头（水浸）", uricPer100g: 145, level: "red", sourceTag: "ACR 2020"),
        .init(name: "啤酒（普通）", uricPer100g: 30, level: "red", sourceTag: "ACR 2020"),
        .init(name: "精酿啤酒/IPA", uricPer100g: 35, level: "red", sourceTag: "ACR 2020"),
        .init(name: "黑啤/世涛", uricPer100g: 36, level: "red", sourceTag: "ACR 2020"),
        .init(name: "白酒（中国烈酒）", uricPer100g: 0, level: "red", sourceTag: "ACR 2020"),
        .init(name: "威士忌", uricPer100g: 0, level: "red", sourceTag: "ACR 2020"),
        .init(name: "伏特加", uricPer100g: 0, level: "red", sourceTag: "ACR 2020"),
        .init(name: "红酒", uricPer100g: 3, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "清酒", uricPer100g: 8, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "黄酒/绍兴", uricPer100g: 25, level: "red", sourceTag: "ACR 2020"),
        .init(name: "气泡水", uricPer100g: 0, level: "green", sourceTag: "ACR 2020"),
        .init(name: "运动饮料（无糖）", uricPer100g: 1, level: "green", sourceTag: "ACR 2020"),
        .init(name: "椰子水", uricPer100g: 3, level: "green", sourceTag: "ACR 2020"),
        .init(name: "番茄汁（低钠）", uricPer100g: 5, level: "green", sourceTag: "ACR 2020"),
        .init(name: "培根", uricPer100g: 110, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "香肠", uricPer100g: 125, level: "red", sourceTag: "ACR 2020"),
        .init(name: "热狗", uricPer100g: 128, level: "red", sourceTag: "ACR 2020"),
        .init(name: "汉堡肉饼", uricPer100g: 130, level: "red", sourceTag: "ACR 2020"),
        .init(name: "炸鸡", uricPer100g: 135, level: "red", sourceTag: "ACR 2020"),
        .init(name: "牛排", uricPer100g: 120, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "羊排", uricPer100g: 122, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "龙虾", uricPer100g: 152, level: "red", sourceTag: "ACR 2020"),
        .init(name: "蟹肉棒", uricPer100g: 90, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "鳕鱼", uricPer100g: 105, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "三文鱼刺身", uricPer100g: 112, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "金枪鱼刺身", uricPer100g: 140, level: "red", sourceTag: "ACR 2020"),
        .init(name: "章鱼", uricPer100g: 88, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "鱿鱼", uricPer100g: 89, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "纳豆", uricPer100g: 110, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "味噌汤", uricPer100g: 30, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "日式酱油", uricPer100g: 12, level: "green", sourceTag: "ACR 2020"),
        .init(name: "豆腐乳", uricPer100g: 55, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "皮蛋", uricPer100g: 25, level: "green", sourceTag: "ACR 2020"),
        .init(name: "咸鸭蛋", uricPer100g: 20, level: "green", sourceTag: "ACR 2020"),
        .init(name: "午餐肉", uricPer100g: 118, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "方便面（非肉汤）", uricPer100g: 25, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "火锅清汤底", uricPer100g: 60, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "麻辣火锅底", uricPer100g: 180, level: "red", sourceTag: "ACR 2020"),
        .init(name: "牛肉面（牛肉少）", uricPer100g: 45, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "螺蛳粉（汤）", uricPer100g: 95, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "酸辣粉", uricPer100g: 20, level: "green", sourceTag: "ACR 2020"),
        .init(name: "凉皮", uricPer100g: 15, level: "green", sourceTag: "ACR 2020"),
        .init(name: "米线（清汤）", uricPer100g: 14, level: "green", sourceTag: "ACR 2020"),        .init(name: "伏特加", uricPer100g: 0, level: "red", sourceTag: "ACR 2020"),
        .init(name: "黑啤酒（世涛/黑啤）", uricPer100g: 35, level: "red", sourceTag: "日本食品嘌呤表"),
        .init(name: "梅酒", uricPer100g: 10, level: "yellow", sourceTag: "日本食品嘌呤表"),
        .init(name: "黄酒", uricPer100g: 30, level: "red", sourceTag: "ACR 2020"),
        .init(name: "红酒（干红）", uricPer100g: 5, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "苏打水", uricPer100g: 0, level: "green", sourceTag: "USDA"),
        .init(name: "矿泉水", uricPer100g: 0, level: "green", sourceTag: "—"),
        .init(name: "布丁", uricPer100g: 5, level: "green", sourceTag: "USDA"),
        .init(name: "热狗肠", uricPer100g: 145, level: "red", sourceTag: "Drugs.com"),
        .init(name: "寿司（综合）", uricPer100g: 65, level: "yellow", sourceTag: "日本食品嘌呤表"),
        .init(name: "鳗鱼饭", uricPer100g: 120, level: "yellow", sourceTag: "日本食品嘌呤表"),
        .init(name: "天妇罗", uricPer100g: 60, level: "yellow", sourceTag: "日本食品嘌呤表"),
        .init(name: "韩式烤肉（五花肉）", uricPer100g: 130, level: "red", sourceTag: "估算·卫健委基表"),
        .init(name: "韩式部队锅", uricPer100g: 110, level: "red", sourceTag: "估算·复合"),
        .init(name: "泡菜", uricPer100g: 12, level: "green", sourceTag: "韩国食品成分表"),
        .init(name: "石锅拌饭", uricPer100g: 45, level: "green", sourceTag: "估算·复合"),
        .init(name: "生蚝（牡蛎）", uricPer100g: 165, level: "red", sourceTag: "Drugs.com"),
        .init(name: "扇贝", uricPer100g: 150, level: "red", sourceTag: "Drugs.com"),
        .init(name: "鲍鱼", uricPer100g: 110, level: "yellow", sourceTag: "日本食品嘌呤表"),
        .init(name: "鲈鱼", uricPer100g: 100, level: "yellow", sourceTag: "日本食品嘌呤表"),
        .init(name: "鱼露", uricPer100g: 200, level: "red", sourceTag: "东南亚食品表"),
        .init(name: "虾酱", uricPer100g: 220, level: "red", sourceTag: "卫健委2024"),
        .init(name: "鸡精/浓汤宝", uricPer100g: 500, level: "red", sourceTag: "Drugs.com"),
        .init(name: "酵母粉（烘焙/啤酒酵母）", uricPer100g: 700, level: "red", sourceTag: "Drugs.com"),
        .init(name: "咖啡（美式/黑咖）", uricPer100g: 0, level: "green", sourceTag: "NEJM 咖啡与痛风研究"),
        .init(name: "燕麦奶", uricPer100g: 8, level: "green", sourceTag: "USDA"),
        .init(name: "杏仁奶", uricPer100g: 0, level: "green", sourceTag: "USDA"),
        .init(name: "意大利面", uricPer100g: 20, level: "green", sourceTag: "USDA"),
        .init(name: "披萨", uricPer100g: 40, level: "yellow", sourceTag: "估算·复合"),
        .init(name: "汉堡", uricPer100g: 55, level: "yellow", sourceTag: "估算·复合"),
        .init(name: "墨西哥卷饼", uricPer100g: 45, level: "yellow", sourceTag: "估算·复合"),
        .init(name: "希腊酸奶", uricPer100g: 8, level: "green", sourceTag: "USDA"),
        .init(name: "开菲尔发酵乳", uricPer100g: 8, level: "green", sourceTag: "USDA"),
        .init(name: "樱桃（欧洲酸樱桃）", uricPer100g: 2, level: "green", sourceTag: "USDA"),
        .init(name: "树莓", uricPer100g: 5, level: "green", sourceTag: "USDA"),
        .init(name: "黑莓", uricPer100g: 5, level: "green", sourceTag: "USDA"),
        .init(name: "无花果", uricPer100g: 15, level: "green", sourceTag: "USDA"),
        .init(name: "牛油果", uricPer100g: 10, level: "green", sourceTag: "USDA"),
        .init(name: "菠萝蜜", uricPer100g: 18, level: "green", sourceTag: "USDA"),
        .init(name: "山竹", uricPer100g: 8, level: "green", sourceTag: "USDA"),
        .init(name: "番石榴", uricPer100g: 8, level: "green", sourceTag: "USDA"),
        .init(name: "龙眼", uricPer100g: 15, level: "green", sourceTag: "卫健委2024"),
        .init(name: "红毛丹", uricPer100g: 15, level: "green", sourceTag: "USDA"),
        .init(name: "紫甘蓝", uricPer100g: 8, level: "green", sourceTag: "USDA"),
        .init(name: "羽衣甘蓝", uricPer100g: 10, level: "green", sourceTag: "USDA"),
        .init(name: "秋葵", uricPer100g: 10, level: "green", sourceTag: "卫健委2024"),
        .init(name: "豆苗", uricPer100g: 60, level: "yellow", sourceTag: "卫健委2024"),
        .init(name: "荷兰豆", uricPer100g: 40, level: "green", sourceTag: "USDA"),
        .init(name: "蘑菇（口蘑）", uricPer100g: 50, level: "yellow", sourceTag: "卫健委2024"),
        .init(name: "香菇（干）", uricPer100g: 350, level: "red", sourceTag: "卫健委2024（干品浓缩）"),
        .init(name: "木耳（水发）", uricPer100g: 15, level: "green", sourceTag: "卫健委2024"),
        .init(name: "银耳（水发）", uricPer100g: 15, level: "green", sourceTag: "卫健委2024"),
        .init(name: "鸡蛋（全蛋）", uricPer100g: 2, level: "green", sourceTag: "卫健委2024"),
        .init(name: "鹌鹑蛋", uricPer100g: 5, level: "green", sourceTag: "卫健委2024"),
        .init(name: "牛肉干", uricPer100g: 250, level: "red", sourceTag: "脱水浓缩·Drugs.com"),
        .init(name: "猪肉脯", uricPer100g: 240, level: "red", sourceTag: "脱水浓缩·Drugs.com"),
        .init(name: "鸡胸肉", uricPer100g: 130, level: "yellow", sourceTag: "卫健委2024"),
        .init(name: "鸡腿肉", uricPer100g: 140, level: "yellow", sourceTag: "卫健委2024"),
        .init(name: "鸭血", uricPer100g: 30, level: "green", sourceTag: "卫健委2024"),
        .init(name: "羊肉串", uricPer100g: 150, level: "red", sourceTag: "估算·烧烤浓缩"),
        .init(name: "烤鸭", uricPer100g: 145, level: "red", sourceTag: "估算·卫健委基表"),
        .init(name: "鹅肝", uricPer100g: 400, level: "red", sourceTag: "Drugs.com（内脏最高档）"),
        .init(name: "夜宵·炒粉/炒面", uricPer100g: 40, level: "yellow", sourceTag: "估算·复合"),
        .init(name: "夜宵·烤串（综合）", uricPer100g: 160, level: "red", sourceTag: "估算·复合"),
        .init(name: "夜宵·小龙虾", uricPer100g: 140, level: "red", sourceTag: "卫健委2024"),
        .init(name: "酒会·下酒拼盘", uricPer100g: 150, level: "red", sourceTag: "估算·复合"),
        .init(name: "婚宴·宴席（综合）", uricPer100g: 130, level: "red", sourceTag: "估算·复合"),
        .init(name: "晚宴·西式套餐", uricPer100g: 100, level: "yellow", sourceTag: "估算·复合"),
        .init(name: "聚会·火锅（已在场景）", uricPer100g: 200, level: "red", sourceTag: "估算·汤底浓缩"),
        .init(name: "蛋糕（奶油）", uricPer100g: 8, level: "green", sourceTag: "USDA"),
        .init(name: "提拉米苏", uricPer100g: 10, level: "green", sourceTag: "USDA"),
        .init(name: "马卡龙", uricPer100g: 5, level: "green", sourceTag: "USDA"),
        .init(name: "月饼", uricPer100g: 15, level: "green", sourceTag: "卫健委2024"),
        .init(name: "绿豆糕", uricPer100g: 20, level: "green", sourceTag: "卫健委2024"),
        .init(name: "蛋黄酥", uricPer100g: 15, level: "green", sourceTag: "卫健委2024"),
        .init(name: "薯片", uricPer100g: 15, level: "green", sourceTag: "USDA（嘌呤低但高脂高盐）"),
        .init(name: "巧克力（黑巧 70%）", uricPer100g: 20, level: "green", sourceTag: "USDA"),
        .init(name: "冰淇淋", uricPer100g: 5, level: "green", sourceTag: "USDA（高糖注意）"),
        .init(name: "果冻", uricPer100g: 2, level: "green", sourceTag: "USDA"),
        .init(name: "辣条", uricPer100g: 30, level: "yellow", sourceTag: "估算·调味浓缩"),
        .init(name: "锅巴", uricPer100g: 25, level: "green", sourceTag: "卫健委2024"),
        .init(name: "海苔", uricPer100g: 100, level: "yellow", sourceTag: "日本食品嘌呤表（干品）"),
        .init(name: "话梅", uricPer100g: 10, level: "green", sourceTag: "USDA"),
        .init(name: "坚果混合装", uricPer100g: 30, level: "green", sourceTag: "USDA（适量·热量高）"),

    ]
}

// MARK: - 更新日志（用户反馈回环标注——v6 反馈案例）

struct ChangelogView: View {
    private let entries: [(version: String, date: String, items: [(String, Bool)])] = [
        ("0.1.0", "首个版本", [("3 秒发作记录、嘌呤库、化验值、饮水打卡", false)]),
    ]

    var body: some View {
        List {
            ForEach(entries, id: \.version) { e in
                Section(header: Text("v\(e.version) · \(e.date)")) {
                    ForEach(e.items, id: \.0) { item, fromFeedback in
                        HStack(alignment: .top, spacing: 8) {
                            Text(item).font(.callout)
                            if fromFeedback {
                                Text("来自用户反馈")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.brand.opacity(0.12))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("更新日志")
    }
}

// MARK: - 反馈/评分（v7/v8 文案；评分只在主动点击时触发）

enum FeedbackHelper {
    static func open() {
        let subject = "UricNote 尿酸笔记 - 用户反馈"
        let body = """
        你好，开发者：

        （你的反馈我会认真看，可行的会做成功能更新。真实意见——包括批评——最有价值。）

        【喜欢什么】
        【哪里困惑】
        【希望有什么】

        —— 这封信由 UricNote 帮你起草，直接写就好。
        """
        if let url = URL(string: "mailto:zerone348@gmail.com?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }

    // 健哥11-21令：跳 App Store 评论页兜底（评分弹窗配额满时永远有效）
    static func openStoreReviewPage() {
        // UricNote App ID 6834462104（未上架前此链接无效——上架后生效）
        if let url = URL(string: "https://apps.apple.com/app/id6834462104?action=write-review") {
            UIApplication.shared.open(url)
        }
    }

    static func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}


// MARK: - 高尿酸危害介绍（健哥11-21令：了解页新增——不只是痛风）

struct HarmIntroView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("高尿酸，不只是痛风。")
                    .font(.title2.bold())
                Text("尿酸高在关节形成结晶时是痛风；但它的影响不止关节——长期高尿酸会悄悄波及多个器官。")
                    .font(.callout)
                    .foregroundColor(.secondary)

                Divider()

                harmRow("person.fill", "肾脏",
                        "尿酸盐可沉积在肾间质和尿路——高尿酸人群慢性肾病风险显著升高；尿酸性肾结石也常见。")
                harmRow("heart.fill", "心血管",
                        "流行病学研究提示高尿酸与高血压、动脉硬化相关——它是代谢异常的信号灯之一。")
                harmRow("square.stack.3d.up.fill", "代谢整体",
                        "高尿酸常与肥胖、高血脂、脂肪肝、高血糖结伴出现——代谢综合征的成员之一。")
                harmRow("brain.head.profile", "关联疾病",
                        "观察性研究报道高尿酸与糖尿病、非酒精性脂肪肝等存在关联——机制复杂，管理尿酸是整体代谢管理的一环。")

                Divider()

                Text("好消息").font(.headline)
                Text("达标管理（具体目标遵医嘱）后，结晶可以逐渐溶解，风险随之回落——这正是每天记录的意义：让趋势可见，让调整有据。")
                    .font(.callout)

                Text("以上为公开研究共识的科普整理，不构成诊断或治疗建议。数据来源：ACR 2020 指南 / 公开流行病学研究。")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("高尿酸的危害")
    }

    private func harmRow(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.warn)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body.weight(.semibold))
                Text(text).font(.callout).foregroundColor(.secondary)
            }
        }
    }
}
