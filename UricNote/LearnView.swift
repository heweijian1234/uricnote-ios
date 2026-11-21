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
                                Text(L("Why this app", "为什么是它")).font(.body.weight(.medium))
                                Text(L("Core features, philosophy & hopes — one page", "核心功能、理念、期望——一页看懂")).font(.caption).foregroundColor(.secondary)
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
                                Text(L("Risks of high uric acid", "高尿酸的危害")).font(.body.weight(.medium))
                                Text(L("More than gout — how it affects your body", "不只是痛风——了解它对身体的影响")).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section(L("Bust a few myths first", "先破除几个误区")) {
                    NavigationLink(L("8 most common myths", "8 个最常见的误区")) { MythListView() }
                    NavigationLink(L("Purine food library", "嘌呤食物库")) { PurineListView() }
                }

                Section(L("Getting better together", "和你一起变好")) {
                    // v11.1 #6：反馈独立一级页（健哥令：需要足够的用户反馈）
                    NavigationLink {
                        FeedbackPage()
                    } label: {
                        HStack {
                            Image(systemName: "envelope.circle.fill").foregroundColor(.brand)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("Feedback & changelog", "反馈与更新日志")).font(.body.weight(.medium))
                                Text(L("Criticism is most valuable — every message gets read", "批评最有价值——每一条都会被认真读")).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    Button(L("Rate us", "给我们评分")) {
                        // 健哥11-22令5自查修正：App 未上架——商店评论页是死链（404）。
                        // 未上架期只走系统弹窗（不依赖商店页）；上架后恢复商店跳转兜底
                        FeedbackHelper.requestReview()
                    }
                    .foregroundColor(.brand)
                }

                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("UricNote v0.1.0").font(.caption.weight(.medium))
                Text(L("This app is a logging tool, not medical advice. Sources: ACR 2020 guideline / G-CAN 2024 / published trials.", "本 App 是记录工具，不提供诊断或治疗建议。数据来源：ACR 2020 / G-CAN 2024 / 公开临床试验。"))
                            Text(L("Sources: ACR 2020 / G-CAN 2024 / published clinical trials", "数据来源：ACR 2020 / G-CAN 2024 / 公开临床试验")).font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle(L("Learn", "了解"))
        }
    }

    private func SKStoreStoreReview() {}
}

// MARK: - 愿景页（Onboarding 第3步同款+独立入口）

struct VisionPageView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(L("This is more than a record.", "这不只是一份记录。"))
                    .font(.title.bold())
                Text(L("It's a transformation that respects your body — a way back to yourself. May you live happier.", "这是一次尊重身体，自我救赎的蜕变。愿你能更幸福的生活。"))
                    .font(.body)
                    .foregroundColor(.secondary)

                Divider()

                Text(L("What we believe", "我们相信")).font(.headline)
                Text(L("If your uric acid won't come down, it's never because you're not trying — 70% is metabolism, the rest is lifestyle. No judgment here; we just help you manage what you can control. All it takes is a habit.", "尿酸降不下来，从来不是因为你不努力——七成由身体代谢决定，剩下三成才轮到生活方式。这里不评判你，只帮你把能控制的三成管好，只需要养成习惯。")).font(.callout)

                Text(L("What you can use right now", "现在就能用")).font(.headline)
                visionRow("fork.knife", L("A purine food list backed by clinical guidelines.", "食物嘌呤清单，带临床指南背书"))
                visionRow("brain", L("A daily recall log to find the purine triggers behind your pain", "每天回忆记录，寻找疼痛的嘌呤因子进行改善"))
                visionRow("pills", L("Medication reminders and water tracking", "提醒吃药，记录喝水量习惯"))
                visionRow("doc.text", L("A one-page report for your doctor — quick to read, detailed enough for better advice", "一页报告带给医生，让他快速且详细的了解你的近况，获得更准确的建议"))

                Text(L("It grows with you", "会随时间长大")).font(.headline)
                visionRow("chart.line.uptrend.xyaxis", L("Your entries add up into a picture of your progress", "会随时间记录，画出你的蜕变之路"))
                visionRow("calendar", L("In 7 days, see your habit trends", "7 天后，看到你的习惯趋势线"))
                visionRow("sparkles", L("In a month, discover what you ate before flares", "一个月后，发现疼痛前共同吃了什么"))
                visionRow("figure.walk", L("Further ahead: a friend who's been with you all along", "更远处：我是一直陪你走过来的朋友"))

                Text(L("Why this app", "选择我的理由")).font(.headline)
                visionRow("person.crop.circle.badge.checkmark", L("The developer has high uric acid and gout too — building this for himself and for fellow patients", "开发者本人就是高尿酸痛风患者，正在改善的路上，此 App 是自用也是想帮助更多患友"))
                visionRow("checkmark.seal", L("Free to use, constantly updated. Paid tiers may come someday, but early adopters keep full access forever", "免费使用，持续更新，日后不排除买断制与订阅制，但与你无关——开发初期，下载的患友都是终身免费使用"))
                visionRow("stethoscope", L("Built on published clinical research, not marketing", "设计依据是公开的临床试验节律，不是营销噱头"))
                visionRow("wand.and.stars", L("Design details come from the developer's own experience", "设计细节会加入开发者的个人心得"))

                Text(L("This app is a logging tool, not medical advice. Sources: ACR 2020 guideline / G-CAN 2024 / published trials.", "本 App 是记录工具，不提供诊断或治疗建议。数据来源：ACR 2020 / G-CAN 2024 / 公开临床试验。"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle(L("Why this app", "为什么是它"))
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
    Myth(id: 1, myth: L("'Diet control alone replaces daily meds'", "「管住嘴就不用每天吃药」"),
         fact: L("Diet matters, but 70-80% of uric acid is metabolic (genetic). Diet alone lowers it by ~1-1.5 mg/dL — most people can't reach target. Diet and meds are partners, not either-or.", "饮食控制很重要，但 70-80% 的尿酸由身体代谢（基因）决定。单靠饮食平均只能降 1-1.5 mg/dL——多数人达不到目标。饮食和药物是搭档，不是二选一。"),
         source: "Arthritis Australia"),
    Myth(id: 2, myth: L("'Pain-free means cured — I can stop meds'", "「不疼了就是好了，可以停药」"),
         fact: L("Pain-free only means crystals aren't flaring now; if uric acid is above target, they keep building. Most people flare again within 6 months of stopping. 'No pain' means the meds are working.", "不疼只是结晶暂时没发作；尿酸不达标时结晶仍在积累。停药后多数人半年内复发。「不疼」恰恰说明药物在起作用。"),
         source: L("NICE guideline / RheumNow", "NICE 指南 / RheumNow")),
    Myth(id: 3, myth: L("'Gout only hits the big toe'", "「痛风只长在脚趾」"),
         fact: L("55% believe this, but ankles, knees, fingers, wrists and elbows can all flare. That's why this app supports multi-joint logging.", "55% 的人这么以为，但脚踝、膝盖、手指、手腕、手肘都可能发作。这正是本 App 支持多关节记录的原因。"),
         source: L("Gout Education Society survey 2026", "美国痛风教育学会全国调查 2026")),
    Myth(id: 4, myth: L("'Only beer is bad, other drinks are fine'", "「啤酒最伤，其他酒没事」"),
         fact: L("Beer triggers most — but all alcohol raises uric acid. Cutting total intake beats quitting beer alone.", "啤酒诱发最强没错，但所有酒精（白酒、红酒、洋酒）都会升尿酸。减少总酒精量比只戒啤酒更有效。"),
         source: "Arthritis Australia"),
    Myth(id: 5, myth: L("'Cherries/celery seed cure gout'", "「樱桃/芹菜籽能治痛风」"),
         fact: L("Some early studies, but weak evidence — no replacement for medication. Enjoy them; don't rely on them.", "有些初步研究，但证据很弱，远不能替代药物。可以吃，别指望它。"),
         source: L("FSSAI myth handbook 2019 / OTCFood", "FSSAI 误区手册 2019 / OTCFood")),
    Myth(id: 6, myth: L("'Soy and purine vegetables are forbidden'", "「豆制品和嘌呤蔬菜不能吃」"),
         fact: L("Old thinking — modern guidelines have dropped this ban. Plant purines link weakly to flares; tofu and soy milk are fine.", "这是老观念——现代指南已撤回此禁忌。植物嘌呤与痛风发作的关联很弱，豆腐豆浆可以正常吃。"),
         source: L("Modern guideline consensus (OTCFood)", "现代指南共识（OTCFood 盘点）")),
    Myth(id: 7, myth: L("'Meds harm the liver — can't take them long-term'", "「吃药伤肝，不能长期吃」"),
         fact: L("That's exactly what recheck dates are for — long-term medication with monitoring is standard practice. The right move is timely rechecks, not quitting on your own.", "定期复查肝肾功能正是复查日的用途——在监测下的长期用药是标准方案。怕伤肝的正确做法是按时复查，不是自行停药。"),
         source: L("ACR 2020 guideline", "ACR 2020 指南")),
    Myth(id: 8, myth: L("'I'm young, gout won't hit me'", "「我还年轻，不会得痛风」"),
         fact: L("Youth gout rates haven't declined anywhere in 30 years; in Korea, over 43% of men in their 20s-30s have abnormal uric acid. Youth is no shield.", "全球年轻人（15-39 岁）痛风发病率 30 年来没有一个地区在下降；韩国 20-30 岁男性尿酸异常率超 43%。年轻不是免死牌。"),
         source: L("GBD youth burden study 2023 / Korea health data 2024", "GBD 青年负担研究 2023 / 韩国体检数据 2024")),
    Myth(id: 9, myth: L("'Total rest during flares — never exercise'", "「痛风发作就该静养，千万不能运动」"),
         fact: L("Rest during flares, yes — but regular exercise in remission (brisk walking/swimming) is a lifestyle prescription. The risk is 'never exercising', not 'moderate exercise'.", "发作期确实要休息，但缓解期规律运动（快走/游泳）是降尿酸的生活处方之一——运动减重对尿酸的改善有明确证据。怕的是「从不运动」，不是「适度运动」。"),
         source: L("ACR 2020 / clinical consensus", "ACR 2020 指南 / 临床共识")),
    Myth(id: 10, myth: L("'Eggs are 'fawu' — bad for gout'", "「鸡蛋是发物，痛风不能吃」"),
         fact: L("Eggs are extremely low in purines (~2mg/100g) — one of the safest protein sources for gout. One a day is fine.", "鸡蛋嘌呤极低（约 2mg/100g），是痛风患者最安全的蛋白质来源之一。每天一个鸡蛋不需要顾虑。"),
         source: L("ACR 2020 food table", "ACR 2020 指南食物表")),
    Myth(id: 11, myth: L("'Coffee is bad for gout — quit it'", "「咖啡对痛风不好，要戒掉」"),
         fact: L("Multiple cohort studies link long-term coffee with lower uric acid (neutral-to-positive). Black coffee is fine — just skip sugar and creamer.", "多项队列研究显示长期喝咖啡与更低的尿酸水平相关（中性偏正面）。无糖黑咖啡可以继续喝——别加糖和奶精就好。"),
         source: L("Cohort study reviews (neutral-to-positive)", "队列研究综述（中性偏正面证据）")),
    Myth(id: 12, myth: L("'I'll quit all alcohol starting today'", "「我要下决心，从今天起滴酒不沾」"),
         fact: L("Good intention — but cold-turkey quitting often rebounds. Gradual reduction + logging works better: watch your trend go down instead of white-knuckling it.", "决心值得肯定，但断崖式戒酒容易反弹。更稳的路径是逐步减量+记录——用 App 的饮酒标记看着自己的趋势往下走，比意志力硬扛成功率高。"),
         source: L("Behavioral design (Tiny Habits, Fogg 2019) / clinical consensus", "行为设计研究（Tiny Habits，Fogg 2019）/ 临床共识")),
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
                        Text(L("Source: \(m.source)", "来源：\(m.source)"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.cardBG)
                    .cornerRadius(14)
                }
                Text(L("Patient-community knowledge, not medical advice. Follow your doctor on medication.", "以上为患者共识科普，不构成诊疗建议。具体用药请遵医嘱。"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle(L("Myth vs fact", "误区 vs 事实"))
    }
}

// MARK: - 嘌呤库（红黄绿+sourceTag；内置首批种子数据，搜索过滤）

struct PurineListView: View {
    @ObservedObject var store = Store.shared
    @State private var query = ""
    // 🔴健哥令 2026-11-15：默认先看"能吃什么"（绿灯优先）——患者打开 food 库全是禁忌会心情糟糕/抗拒（v8 情绪设计：先给希望再给边界）
    @State private var tab = 0   // 0=绿灯能吃 1=黄灯适量 2=红灯注意
    // 健哥11-21令：分类导航（健哥11-21晚令+零食）
    @State private var category = L("All", "全部")
    static let categories = [L("All", "全部"), L("Vegetables", "蔬菜"), L("Fruits", "水果"), L("Meats", "肉类"), L("Seafood", "海鲜"), L("Alcohol", "酒类"), L("Drinks", "饮料"), L("Milk tea", "奶茶"), L("Tea", "茶叶"), L("Coffee", "咖啡"), L("Nuts", "坚果"), L("Snacks", "零食"), L("Breads", "面包"), L("Soups", "汤类"), L("Dining scenes", "饮食场景"), L("Other", "其他")]

    var body: some View {
        List {
            Section {
                Picker("", selection: $tab) {
                    Text(L("✓ Safe to eat", "✓ 能吃")).tag(0)
                    Text(L("Moderate", "适量")).tag(1)
                    Text(L("Caution", "注意")).tag(2)
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
                        .buttonStyle(.borderless)   // 🔴健哥11-22实锤修复：List行内多Button无borderless=整行tap只给一个按钮
                    }
                }
                .padding(.vertical, 2)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            } header: {
                Text(L("Purine food library", "嘌呤食物库"))
            } footer: {
                // 健哥11-21晚令1：添加按钮说明
                Text(tab == 0 ? "" : L("Tap 'Add' to put foods into Dashboard → Food page 'My daily list' — daily tapping, no library digging.", "点「添加」把食物加进仪表盘 → 饮食页的「我的日常饮食表」，天天点选不用翻库。"))
            }

            let items = filtered.sorted { $0.name < $1.name }
            if items.isEmpty {
                Text(tab == 0 ? L("No low-purine matches for this search — try another word, or check 'Caution' (it may truly need limiting).", "这个搜索词下没有低嘌呤推荐——换个词试试，或看看「注意」页（可能它确实要少吃）。") : L("No records for this search.", "这个搜索词下没有记录。"))
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            }
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        circle(for: item.level)
                        Text(item.displayName).font(.body.weight(.medium))
                        Spacer()
                        // 健哥11-21晚令1：右侧"添加"按钮（仅适量/注意列——能吃列不需要记）
                        if tab != 0 {
                            if store.meta.dailyFoods.contains(item.name) {
                                Button(L("Added", "已添加")) {
                                    store.meta.dailyFoods.removeAll { $0 == item.name }
                                    store.save()
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.bordered)
                                .tint(.brand)
                            } else {
                                Button(L("Add", "添加")) {
                                    store.meta.dailyFoods.append(item.name)
                                    store.save()
                                    UricCelebrate.show(L("Added to daily food list", "已加到日常饮食表"))
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
                    Text(L("Purine ~\(Int(item.uricPer100g)) mg/100g · \(item.displaySource)", "嘌呤约 \(Int(item.uricPer100g)) mg/100g · \(item.displaySource)"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .searchable(text: $query, prompt: L("Search foods, e.g. eggs / milk / beer", "搜食物，比如：鸡蛋 / 牛奶 / 啤酒"))
        .navigationTitle(L("Purine food library", "嘌呤食物库"))
        .onAppear {
            if store.purineItems.isEmpty {
                store.purineItems = PurineDatabase.seed
                store.save()
            }
        }
    }

    private var filtered: [PurineItem] {
        let byQuery = store.purineItems.filter { query.isEmpty || (($0.name + " " + ($0.nameEn ?? "")).localizedCaseInsensitiveContains(query)) }
        // 按选中的Tab过滤：绿灯/黄灯/红灯
        let levelKey = ["green", "yellow", "red"][tab]
        // 健哥11-21令：分类过滤（"全部"不过滤；推断不出归"其他"）
        let byCategory = category == L("All", "全部") ? byQuery : byQuery.filter { $0.inferredCategory == category }
        return byCategory.filter { $0.level == levelKey }
    }

    private func circle(for level: String) -> some View {
        Circle().fill(color(for: level)).frame(width: 10, height: 10)
    }
    private func color(for level: String) -> Color {
        level == "red" ? .red : (level == "yellow" ? .orange : .green)
    }
    private func levelName(_ level: String) -> String {
        level == "red" ? L("Red · high purine", "红灯 · 高嘌呤") : (level == "yellow" ? L("Yellow · moderate purine", "黄灯 · 中嘌呤") : L("Green · low purine", "绿灯 · 低嘌呤"))
    }
}

// 首批种子库（≈60 条高频；完整库上架前扩充——来源标注 ACR 2020 指南口径）
enum PurineDatabase {
    static let seed: [PurineItem] = [
        .init(name: "啤酒", uricPer100g: 30, level: "red", sourceTag: "嘌呤+酒精双通道·诱发最强（ACR 2020）", nameEn: "Beer", sourceTagEn: "Purines + alcohol double hit — strongest trigger (ACR 2020)"),
        .init(name: "白酒", uricPer100g: 0, level: "red", sourceTag: "蒸馏酒嘌呤≈0·酒精抑排泄升尿酸（ACR 2020）", nameEn: "Baijiu (Chinese liquor)", sourceTagEn: "Distilled: purines ≈0 · alcohol raises UA (ACR 2020)"),
        .init(name: "动物内脏（肝/腰/脑）", uricPer100g: 300, level: "red", sourceTag: "ACR 2020", nameEn: "Organ meats (liver/kidney/brain)", sourceTagEn: "ACR 2020"),
        .init(name: "浓肉汤", uricPer100g: 400, level: "red", sourceTag: "ACR 2020", nameEn: "Rich meat broth", sourceTagEn: "ACR 2020"),
        .init(name: "沙丁鱼", uricPer100g: 345, level: "red", sourceTag: "ACR 2020", nameEn: "Sardines", sourceTagEn: "ACR 2020"),
        .init(name: "凤尾鱼", uricPer100g: 240, level: "red", sourceTag: "ACR 2020", nameEn: "Anchovies", sourceTagEn: "ACR 2020"),
        .init(name: "带鱼", uricPer100g: 192, level: "red", sourceTag: "ACR 2020", nameEn: "Ribbon fish", sourceTagEn: "ACR 2020"),
        .init(name: "牡蛎", uricPer100g: 240, level: "red", sourceTag: "ACR 2020", nameEn: "Oysters", sourceTagEn: "ACR 2020"),
        .init(name: "蛤蜊", uricPer100g: 160, level: "red", sourceTag: "ACR 2020", nameEn: "Clams", sourceTagEn: "ACR 2020"),
        .init(name: "鹅肉", uricPer100g: 165, level: "red", sourceTag: "ACR 2020", nameEn: "Goose", sourceTagEn: "ACR 2020"),
        .init(name: "猪肝", uricPer100g: 290, level: "red", sourceTag: "ACR 2020", nameEn: "Pork liver", sourceTagEn: "ACR 2020"),
        .init(name: "猪腰", uricPer100g: 220, level: "red", sourceTag: "ACR 2020", nameEn: "Pork kidney", sourceTagEn: "ACR 2020"),
        .init(name: "脑花", uricPer100g: 260, level: "red", sourceTag: "ACR 2020", nameEn: "Brain", sourceTagEn: "ACR 2020"),
        .init(name: "猪肉（五花）", uricPer100g: 160, level: "red", sourceTag: "ACR 2020", nameEn: "Pork belly", sourceTagEn: "ACR 2020"),
        .init(name: "牛肉", uricPer100g: 120, level: "yellow", sourceTag: "ACR 2020", nameEn: "Beef", sourceTagEn: "ACR 2020"),
        .init(name: "羊肉", uricPer100g: 120, level: "yellow", sourceTag: "ACR 2020", nameEn: "Lamb", sourceTagEn: "ACR 2020"),
        .init(name: "鸡肉", uricPer100g: 110, level: "yellow", sourceTag: "ACR 2020", nameEn: "Chicken", sourceTagEn: "ACR 2020"),
        .init(name: "鸭肉", uricPer100g: 115, level: "yellow", sourceTag: "ACR 2020", nameEn: "Duck", sourceTagEn: "ACR 2020"),
        .init(name: "三文鱼", uricPer100g: 110, level: "yellow", sourceTag: "ACR 2020", nameEn: "Salmon", sourceTagEn: "ACR 2020"),
        .init(name: "金枪鱼", uricPer100g: 140, level: "yellow", sourceTag: "ACR 2020", nameEn: "Tuna", sourceTagEn: "ACR 2020"),
        .init(name: "鲤鱼", uricPer100g: 130, level: "yellow", sourceTag: "ACR 2020", nameEn: "Carp", sourceTagEn: "ACR 2020"),
        .init(name: "基围虾", uricPer100g: 145, level: "yellow", sourceTag: "ACR 2020", nameEn: "Shrimp", sourceTagEn: "ACR 2020"),
        .init(name: "螃蟹", uricPer100g: 82, level: "yellow", sourceTag: "ACR 2020", nameEn: "Crab", sourceTagEn: "ACR 2020"),
        .init(name: "豆腐", uricPer100g: 55, level: "yellow", sourceTag: "ACR 2020", nameEn: "Tofu", sourceTagEn: "ACR 2020"),
        .init(name: "四季豆", uricPer100g: 20, level: "green", sourceTag: "ACR 2020", nameEn: "Green beans", sourceTagEn: "ACR 2020"),
        .init(name: "芦笋", uricPer100g: 23, level: "green", sourceTag: "ACR 2020", nameEn: "Asparagus", sourceTagEn: "ACR 2020"),
        .init(name: "菠菜", uricPer100g: 23, level: "green", sourceTag: "ACR 2020", nameEn: "Spinach", sourceTagEn: "ACR 2020"),
        .init(name: "蘑菇", uricPer100g: 25, level: "green", sourceTag: "ACR 2020", nameEn: "Mushrooms", sourceTagEn: "ACR 2020"),
        .init(name: "西兰花", uricPer100g: 20, level: "green", sourceTag: "ACR 2020", nameEn: "Broccoli", sourceTagEn: "ACR 2020"),
        .init(name: "鸡蛋", uricPer100g: 2, level: "green", sourceTag: "ACR 2020", nameEn: "Egg", sourceTagEn: "ACR 2020"),
        .init(name: "低脂牛奶", uricPer100g: 1, level: "green", sourceTag: "ACR 2020", nameEn: "Low-fat milk", sourceTagEn: "ACR 2020"),
        .init(name: "酸奶（低脂）", uricPer100g: 8, level: "green", sourceTag: "ACR 2020", nameEn: "Yogurt (low-fat)", sourceTagEn: "ACR 2020"),
        .init(name: "樱桃", uricPer100g: 5, level: "green", sourceTag: "ACR 2020", nameEn: "Cherries", sourceTagEn: "ACR 2020"),
        .init(name: "苹果", uricPer100g: 3, level: "green", sourceTag: "ACR 2020", nameEn: "Apple", sourceTagEn: "ACR 2020"),
        .init(name: "香蕉", uricPer100g: 4, level: "green", sourceTag: "ACR 2020", nameEn: "Banana", sourceTagEn: "ACR 2020"),
        .init(name: "西瓜", uricPer100g: 2, level: "green", sourceTag: "ACR 2020", nameEn: "Watermelon", sourceTagEn: "ACR 2020"),
        .init(name: "米饭", uricPer100g: 8, level: "green", sourceTag: "ACR 2020", nameEn: "Rice", sourceTagEn: "ACR 2020"),
        .init(name: "面条", uricPer100g: 10, level: "green", sourceTag: "ACR 2020", nameEn: "Noodles", sourceTagEn: "ACR 2020"),
        .init(name: "全麦面包", uricPer100g: 15, level: "green", sourceTag: "ACR 2020", nameEn: "Whole wheat bread", sourceTagEn: "ACR 2020"),
        .init(name: "土豆", uricPer100g: 6, level: "green", sourceTag: "ACR 2020", nameEn: "Potato", sourceTagEn: "ACR 2020"),
        .init(name: "红薯", uricPer100g: 8, level: "green", sourceTag: "ACR 2020", nameEn: "Sweet potato", sourceTagEn: "ACR 2020"),
        .init(name: "黄瓜", uricPer100g: 3, level: "green", sourceTag: "ACR 2020", nameEn: "Cucumber", sourceTagEn: "ACR 2020"),
        .init(name: "番茄", uricPer100g: 4, level: "green", sourceTag: "ACR 2020", nameEn: "Tomato", sourceTagEn: "ACR 2020"),
        .init(name: "胡萝卜", uricPer100g: 5, level: "green", sourceTag: "ACR 2020", nameEn: "Carrot", sourceTagEn: "ACR 2020"),
        .init(name: "白菜", uricPer100g: 3, level: "green", sourceTag: "ACR 2020", nameEn: "Napa cabbage", sourceTagEn: "ACR 2020"),
        .init(name: "橙汁（含糖）", uricPer100g: 10, level: "yellow", sourceTag: "果糖代谢升尿酸·非嘌呤通道（ACR 2020）", nameEn: "Orange juice (sugary)", sourceTagEn: "Fructose raises UA, not purines (ACR 2020)"),
        .init(name: "可乐（含糖）", uricPer100g: 2, level: "yellow", sourceTag: "果糖代谢升尿酸·非嘌呤通道（ACR 2020）", nameEn: "Cola (sugary)", sourceTagEn: "Fructose raises UA, not purines (ACR 2020)"),
        .init(name: "蜂蜜", uricPer100g: 5, level: "yellow", sourceTag: "果糖代谢升尿酸·非嘌呤通道（ACR 2020）", nameEn: "Honey", sourceTagEn: "Fructose raises UA, not purines (ACR 2020)"),
        .init(name: "花生", uricPer100g: 79, level: "yellow", sourceTag: "ACR 2020", nameEn: "Peanuts", sourceTagEn: "ACR 2020"),
        .init(name: "豆干", uricPer100g: 75, level: "yellow", sourceTag: "ACR 2020", nameEn: "Dried tofu", sourceTagEn: "ACR 2020"),
        .init(name: "扁豆", uricPer100g: 75, level: "yellow", sourceTag: "ACR 2020", nameEn: "Lentils", sourceTagEn: "ACR 2020"),
        .init(name: "豌豆", uricPer100g: 76, level: "yellow", sourceTag: "ACR 2020", nameEn: "Green peas", sourceTagEn: "ACR 2020"),
        .init(name: "猪肚", uricPer100g: 132, level: "yellow", sourceTag: "ACR 2020", nameEn: "Pork stomach", sourceTagEn: "ACR 2020"),
        .init(name: "火腿", uricPer100g: 120, level: "yellow", sourceTag: "ACR 2020", nameEn: "Ham", sourceTagEn: "ACR 2020"),
        .init(name: "腰果", uricPer100g: 60, level: "yellow", sourceTag: "ACR 2020", nameEn: "Cashews", sourceTagEn: "ACR 2020"),
        .init(name: "核桃", uricPer100g: 25, level: "green", sourceTag: "ACR 2020", nameEn: "Walnuts", sourceTagEn: "ACR 2020"),
        // ===== 绿灯扩展（健哥令 11-15：能吃的要丰富——先看希望再看边界）=====
        .init(name: "葡萄", uricPer100g: 4, level: "green", sourceTag: "ACR 2020", nameEn: "Grapes", sourceTagEn: "ACR 2020"),
        .init(name: "梨", uricPer100g: 3, level: "green", sourceTag: "ACR 2020", nameEn: "Pear", sourceTagEn: "ACR 2020"),
        .init(name: "桃子", uricPer100g: 4, level: "green", sourceTag: "ACR 2020", nameEn: "Peach", sourceTagEn: "ACR 2020"),
        .init(name: "橙子", uricPer100g: 3, level: "green", sourceTag: "ACR 2020", nameEn: "Orange", sourceTagEn: "ACR 2020"),
        .init(name: "柚子", uricPer100g: 4, level: "green", sourceTag: "ACR 2020", nameEn: "Pomelo", sourceTagEn: "ACR 2020"),
        .init(name: "草莓", uricPer100g: 5, level: "green", sourceTag: "ACR 2020", nameEn: "Strawberry", sourceTagEn: "ACR 2020"),
        .init(name: "蓝莓", uricPer100g: 5, level: "green", sourceTag: "ACR 2020", nameEn: "Blueberry", sourceTagEn: "ACR 2020"),
        .init(name: "哈密瓜", uricPer100g: 4, level: "green", sourceTag: "ACR 2020", nameEn: "Hami melon", sourceTagEn: "ACR 2020"),
        .init(name: "菠萝", uricPer100g: 5, level: "green", sourceTag: "ACR 2020", nameEn: "Pineapple", sourceTagEn: "ACR 2020"),
        .init(name: "芒果", uricPer100g: 4, level: "green", sourceTag: "ACR 2020", nameEn: "Mango", sourceTagEn: "ACR 2020"),
        .init(name: "红枣（鲜）", uricPer100g: 6, level: "green", sourceTag: "ACR 2020", nameEn: "Fresh jujube", sourceTagEn: "ACR 2020"),
        .init(name: "生菜", uricPer100g: 4, level: "green", sourceTag: "ACR 2020", nameEn: "Lettuce", sourceTagEn: "ACR 2020"),
        .init(name: "油麦菜", uricPer100g: 5, level: "green", sourceTag: "ACR 2020", nameEn: "Leaf lettuce (youmaicai)", sourceTagEn: "ACR 2020"),
        .init(name: "空心菜", uricPer100g: 6, level: "green", sourceTag: "ACR 2020", nameEn: "Water spinach", sourceTagEn: "ACR 2020"),
        .init(name: "芹菜", uricPer100g: 5, level: "green", sourceTag: "ACR 2020", nameEn: "Celery", sourceTagEn: "ACR 2020"),
        .init(name: "冬瓜", uricPer100g: 3, level: "green", sourceTag: "ACR 2020", nameEn: "Winter melon", sourceTagEn: "ACR 2020"),
        .init(name: "南瓜", uricPer100g: 4, level: "green", sourceTag: "ACR 2020", nameEn: "Pumpkin", sourceTagEn: "ACR 2020"),
        .init(name: "丝瓜", uricPer100g: 4, level: "green", sourceTag: "ACR 2020", nameEn: "Loofah", sourceTagEn: "ACR 2020"),
        .init(name: "茄子", uricPer100g: 5, level: "green", sourceTag: "ACR 2020", nameEn: "Eggplant", sourceTagEn: "ACR 2020"),
        .init(name: "青椒", uricPer100g: 5, level: "green", sourceTag: "ACR 2020", nameEn: "Green pepper", sourceTagEn: "ACR 2020"),
        .init(name: "白萝卜", uricPer100g: 5, level: "green", sourceTag: "ACR 2020", nameEn: "Daikon", sourceTagEn: "ACR 2020"),
        .init(name: "西红柿", uricPer100g: 4, level: "green", sourceTag: "ACR 2020", nameEn: "Tomato", sourceTagEn: "ACR 2020"),
        .init(name: "花菜", uricPer100g: 22, level: "green", sourceTag: "ACR 2020", nameEn: "Cauliflower", sourceTagEn: "ACR 2020"),
        .init(name: "玉米", uricPer100g: 9, level: "green", sourceTag: "ACR 2020", nameEn: "Corn", sourceTagEn: "ACR 2020"),
        .init(name: "山药", uricPer100g: 8, level: "green", sourceTag: "ACR 2020", nameEn: "Chinese yam", sourceTagEn: "ACR 2020"),
        .init(name: "芋头", uricPer100g: 10, level: "green", sourceTag: "ACR 2020", nameEn: "Taro", sourceTagEn: "ACR 2020"),
        .init(name: "藕", uricPer100g: 12, level: "green", sourceTag: "ACR 2020", nameEn: "Lotus root", sourceTagEn: "ACR 2020"),
        .init(name: "小米粥", uricPer100g: 6, level: "green", sourceTag: "ACR 2020", nameEn: "Millet porridge", sourceTagEn: "ACR 2020"),
        .init(name: "燕麦", uricPer100g: 12, level: "green", sourceTag: "ACR 2020", nameEn: "Oats", sourceTagEn: "ACR 2020"),
        .init(name: "馒头", uricPer100g: 9, level: "green", sourceTag: "ACR 2020", nameEn: "Steamed bun", sourceTagEn: "ACR 2020"),
        .init(name: "酸奶", uricPer100g: 10, level: "green", sourceTag: "ACR 2020", nameEn: "Yogurt", sourceTagEn: "ACR 2020"),
        .init(name: "蛋白（蛋清）", uricPer100g: 1, level: "green", sourceTag: "ACR 2020", nameEn: "Egg white", sourceTagEn: "ACR 2020"),
        .init(name: "车厘子", uricPer100g: 5, level: "green", sourceTag: "ACR 2020", nameEn: "Cherries", sourceTagEn: "ACR 2020"),
        .init(name: "柠檬水（无糖）", uricPer100g: 1, level: "green", sourceTag: "ACR 2020", nameEn: "Lemonade (no sugar)", sourceTagEn: "ACR 2020"),
        .init(name: "白开水", uricPer100g: 0, level: "green", sourceTag: "ACR 2020", nameEn: "Plain water", sourceTagEn: "ACR 2020"),
        .init(name: "淡茶水", uricPer100g: 1, level: "green", sourceTag: "ACR 2020", nameEn: "Light tea", sourceTagEn: "ACR 2020"),
        .init(name: "咖啡（黑，无糖）", uricPer100g: 2, level: "green", sourceTag: "ACR 2020", nameEn: "Coffee (black, no sugar)", sourceTagEn: "ACR 2020"),
        .init(name: "橄榄油", uricPer100g: 0, level: "green", sourceTag: "ACR 2020", nameEn: "Olive oil", sourceTagEn: "ACR 2020"),
        .init(name: "海蜇皮", uricPer100g: 18, level: "green", sourceTag: "ACR 2020", nameEn: "Jellyfish", sourceTagEn: "ACR 2020"),
        .init(name: "海参（水发）", uricPer100g: 12, level: "green", sourceTag: "ACR 2020", nameEn: "Sea cucumber (rehydrated)", sourceTagEn: "ACR 2020"),
        // ===== 地区性扩展（首发六区：中/美/日/德/英/澳——健哥令 11-15）=====
        .init(name: "豆浆（无糖）", uricPer100g: 3, level: "green", sourceTag: "ACR 2020", nameEn: "Soy milk (unsweetened)", sourceTagEn: "ACR 2020"),
        .init(name: "薏米水", uricPer100g: 2, level: "green", sourceTag: "ACR 2020", nameEn: "Coix seed water", sourceTagEn: "ACR 2020"),
        .init(name: "黑咖啡", uricPer100g: 2, level: "green", sourceTag: "ACR 2020", nameEn: "Black coffee", sourceTagEn: "ACR 2020"),
        .init(name: "拿铁（低脂奶）", uricPer100g: 3, level: "green", sourceTag: "ACR 2020", nameEn: "Latte (low-fat milk)", sourceTagEn: "ACR 2020"),
        .init(name: "麦片", uricPer100g: 12, level: "green", sourceTag: "ACR 2020", nameEn: "Cereal flakes", sourceTagEn: "ACR 2020"),
        .init(name: "全麦意面", uricPer100g: 14, level: "green", sourceTag: "ACR 2020", nameEn: "Whole wheat pasta", sourceTagEn: "ACR 2020"),
        .init(name: "白面包", uricPer100g: 10, level: "green", sourceTag: "ACR 2020", nameEn: "White bread", sourceTagEn: "ACR 2020"),
        .init(name: "贝果", uricPer100g: 12, level: "green", sourceTag: "ACR 2020", nameEn: "Bagel", sourceTagEn: "ACR 2020"),
        .init(name: "藜麦", uricPer100g: 18, level: "green", sourceTag: "ACR 2020", nameEn: "Quinoa", sourceTagEn: "ACR 2020"),
        .init(name: "荞麦面", uricPer100g: 12, level: "green", sourceTag: "ACR 2020", nameEn: "Soba noodles", sourceTagEn: "ACR 2020"),
        .init(name: "年糕", uricPer100g: 9, level: "green", sourceTag: "ACR 2020", nameEn: "Rice cake", sourceTagEn: "ACR 2020"),
        .init(name: "椒盐卷饼（德式）", uricPer100g: 11, level: "green", sourceTag: "ACR 2020", nameEn: "Pretzel", sourceTagEn: "ACR 2020"),
        .init(name: "酸菜（德式泡菜）", uricPer100g: 6, level: "green", sourceTag: "ACR 2020", nameEn: "Sauerkraut", sourceTagEn: "ACR 2020"),
        .init(name: "英式早餐茶", uricPer100g: 1, level: "green", sourceTag: "ACR 2020", nameEn: "English breakfast tea", sourceTagEn: "ACR 2020"),
        .init(name: "约克郡布丁", uricPer100g: 12, level: "green", sourceTag: "ACR 2020", nameEn: "Yorkshire pudding", sourceTagEn: "ACR 2020"),
        .init(name: "鱼罐头（水浸）", uricPer100g: 145, level: "red", sourceTag: "ACR 2020", nameEn: "Canned fish (in water)", sourceTagEn: "ACR 2020"),
        .init(name: "黑啤/世涛", uricPer100g: 36, level: "red", sourceTag: "ACR 2020", nameEn: "Stout", sourceTagEn: "ACR 2020"),
        .init(name: "威士忌", uricPer100g: 0, level: "red", sourceTag: "蒸馏酒嘌呤≈0·酒精抑排泄升尿酸（ACR 2020）", nameEn: "Whisky", sourceTagEn: "Distilled: purines ≈0 · alcohol raises UA (ACR 2020)"),
        .init(name: "伏特加", uricPer100g: 0, level: "red", sourceTag: "蒸馏酒嘌呤≈0·酒精抑排泄升尿酸（ACR 2020）", nameEn: "Vodka", sourceTagEn: "Distilled: purines ≈0 · alcohol raises UA (ACR 2020)"),
        .init(name: "红酒", uricPer100g: 3, level: "yellow", sourceTag: "ACR 2020", nameEn: "Red wine", sourceTagEn: "ACR 2020"),
        .init(name: "清酒", uricPer100g: 8, level: "yellow", sourceTag: "ACR 2020", nameEn: "Sake", sourceTagEn: "ACR 2020"),
        .init(name: "黄酒/绍兴", uricPer100g: 25, level: "red", sourceTag: "ACR 2020", nameEn: "Huangjiu / Shaoxing wine", sourceTagEn: "ACR 2020"),
        .init(name: "气泡水", uricPer100g: 0, level: "green", sourceTag: "ACR 2020", nameEn: "Sparkling water", sourceTagEn: "ACR 2020"),
        .init(name: "运动饮料（无糖）", uricPer100g: 1, level: "green", sourceTag: "ACR 2020", nameEn: "Sports drink (no sugar)", sourceTagEn: "ACR 2020"),
        .init(name: "椰子水", uricPer100g: 3, level: "green", sourceTag: "ACR 2020", nameEn: "Coconut water", sourceTagEn: "ACR 2020"),
        .init(name: "培根", uricPer100g: 110, level: "yellow", sourceTag: "ACR 2020", nameEn: "Bacon", sourceTagEn: "ACR 2020"),
        .init(name: "香肠", uricPer100g: 125, level: "red", sourceTag: "ACR 2020", nameEn: "Sausage", sourceTagEn: "ACR 2020"),
        .init(name: "热狗", uricPer100g: 128, level: "red", sourceTag: "ACR 2020", nameEn: "Hot dog", sourceTagEn: "ACR 2020"),
        .init(name: "汉堡肉饼", uricPer100g: 130, level: "red", sourceTag: "ACR 2020", nameEn: "Hamburger patty", sourceTagEn: "ACR 2020"),
        .init(name: "炸鸡", uricPer100g: 135, level: "red", sourceTag: "ACR 2020", nameEn: "Fried chicken", sourceTagEn: "ACR 2020"),
        .init(name: "牛排", uricPer100g: 120, level: "yellow", sourceTag: "ACR 2020", nameEn: "Steak", sourceTagEn: "ACR 2020"),
        .init(name: "龙虾", uricPer100g: 152, level: "red", sourceTag: "ACR 2020", nameEn: "Lobster", sourceTagEn: "ACR 2020"),
        .init(name: "蟹肉棒", uricPer100g: 90, level: "yellow", sourceTag: "ACR 2020", nameEn: "Crab sticks", sourceTagEn: "ACR 2020"),
        .init(name: "鳕鱼", uricPer100g: 105, level: "yellow", sourceTag: "ACR 2020", nameEn: "Cod", sourceTagEn: "ACR 2020"),
        .init(name: "金枪鱼刺身", uricPer100g: 140, level: "red", sourceTag: "ACR 2020", nameEn: "Tuna sashimi", sourceTagEn: "ACR 2020"),
        .init(name: "章鱼", uricPer100g: 88, level: "yellow", sourceTag: "ACR 2020", nameEn: "Octopus", sourceTagEn: "ACR 2020"),
        .init(name: "鱿鱼", uricPer100g: 89, level: "yellow", sourceTag: "ACR 2020", nameEn: "Squid", sourceTagEn: "ACR 2020"),
        .init(name: "纳豆", uricPer100g: 110, level: "yellow", sourceTag: "ACR 2020", nameEn: "Natto", sourceTagEn: "ACR 2020"),
        .init(name: "味噌汤", uricPer100g: 30, level: "yellow", sourceTag: "ACR 2020", nameEn: "Miso soup", sourceTagEn: "ACR 2020"),
        .init(name: "日式酱油", uricPer100g: 12, level: "green", sourceTag: "ACR 2020", nameEn: "Soy sauce (Japanese)", sourceTagEn: "ACR 2020"),
        .init(name: "豆腐乳", uricPer100g: 55, level: "yellow", sourceTag: "ACR 2020", nameEn: "Fermented tofu", sourceTagEn: "ACR 2020"),
        .init(name: "皮蛋", uricPer100g: 25, level: "green", sourceTag: "ACR 2020", nameEn: "Century egg", sourceTagEn: "ACR 2020"),
        .init(name: "咸鸭蛋", uricPer100g: 20, level: "green", sourceTag: "ACR 2020", nameEn: "Salted duck egg", sourceTagEn: "ACR 2020"),
        .init(name: "午餐肉", uricPer100g: 118, level: "yellow", sourceTag: "ACR 2020", nameEn: "Spam/luncheon meat", sourceTagEn: "ACR 2020"),
        .init(name: "方便面（非肉汤）", uricPer100g: 25, level: "yellow", sourceTag: "ACR 2020", nameEn: "Instant noodles (non-meat)", sourceTagEn: "ACR 2020"),
        .init(name: "火锅清汤底", uricPer100g: 60, level: "yellow", sourceTag: "ACR 2020", nameEn: "Clear hot pot broth", sourceTagEn: "ACR 2020"),
        .init(name: "麻辣火锅底", uricPer100g: 180, level: "red", sourceTag: "ACR 2020", nameEn: "Spicy hot pot broth", sourceTagEn: "ACR 2020"),
        .init(name: "螺蛳粉（汤）", uricPer100g: 95, level: "yellow", sourceTag: "ACR 2020", nameEn: "Luosifen (snail noodles)", sourceTagEn: "ACR 2020"),
        .init(name: "酸辣粉", uricPer100g: 20, level: "green", sourceTag: "ACR 2020", nameEn: "Hot & sour noodles", sourceTagEn: "ACR 2020"),
        .init(name: "凉皮", uricPer100g: 15, level: "green", sourceTag: "ACR 2020", nameEn: "Liangpi (cold noodles)", sourceTagEn: "ACR 2020"),
        .init(name: "米线（清汤）", uricPer100g: 14, level: "green", sourceTag: "ACR 2020", nameEn: "Rice noodles (clear soup)", sourceTagEn: "ACR 2020"),
        .init(name: "黑啤酒（世涛/黑啤）", uricPer100g: 35, level: "red", sourceTag: "日本食品嘌呤表", nameEn: "Stout / dark beer", sourceTagEn: "Japanese purine table"),
        .init(name: "梅酒", uricPer100g: 10, level: "yellow", sourceTag: "日本食品嘌呤表", nameEn: "Plum wine", sourceTagEn: "Japanese purine table"),
        .init(name: "黄酒", uricPer100g: 30, level: "red", sourceTag: "ACR 2020", nameEn: "Huangjiu", sourceTagEn: "ACR 2020"),
        .init(name: "苏打水", uricPer100g: 0, level: "green", sourceTag: "USDA", nameEn: "Soda water", sourceTagEn: "USDA"),
        .init(name: "矿泉水", uricPer100g: 0, level: "green", sourceTag: "—", nameEn: "Mineral water", sourceTagEn: "—"),
        .init(name: "布丁", uricPer100g: 5, level: "green", sourceTag: "USDA", nameEn: "Pudding", sourceTagEn: "USDA"),
        .init(name: "热狗肠", uricPer100g: 145, level: "red", sourceTag: "Drugs.com", nameEn: "Hot dog sausage", sourceTagEn: "Drugs.com"),
        .init(name: "寿司（综合）", uricPer100g: 65, level: "yellow", sourceTag: "日本食品嘌呤表", nameEn: "Sushi (assorted)", sourceTagEn: "Japanese purine table"),
        .init(name: "鳗鱼饭", uricPer100g: 120, level: "yellow", sourceTag: "日本食品嘌呤表", nameEn: "Unagi rice", sourceTagEn: "Japanese purine table"),
        .init(name: "天妇罗", uricPer100g: 60, level: "yellow", sourceTag: "日本食品嘌呤表", nameEn: "Tempura", sourceTagEn: "Japanese purine table"),
        .init(name: "韩式烤肉（五花肉）", uricPer100g: 130, level: "red", sourceTag: "估算·卫健委基表", nameEn: "Korean BBQ (pork belly)", sourceTagEn: "Estimated (NHHC base)"),
        .init(name: "韩式部队锅", uricPer100g: 110, level: "red", sourceTag: "估算·复合", nameEn: "Budae-jjigae (army stew)", sourceTagEn: "Estimated (composite)"),
        .init(name: "泡菜", uricPer100g: 12, level: "green", sourceTag: "韩国食品成分表", nameEn: "Kimchi", sourceTagEn: "Korean food composition table"),
        .init(name: "石锅拌饭", uricPer100g: 45, level: "green", sourceTag: "估算·复合", nameEn: "Bibimbap", sourceTagEn: "Estimated (composite)"),
        .init(name: "生蚝（牡蛎）", uricPer100g: 165, level: "red", sourceTag: "Drugs.com", nameEn: "Oysters", sourceTagEn: "Drugs.com"),
        .init(name: "扇贝", uricPer100g: 150, level: "red", sourceTag: "Drugs.com", nameEn: "Scallops", sourceTagEn: "Drugs.com"),
        .init(name: "鲍鱼", uricPer100g: 110, level: "yellow", sourceTag: "日本食品嘌呤表", nameEn: "Abalone", sourceTagEn: "Japanese purine table"),
        .init(name: "鲈鱼", uricPer100g: 100, level: "yellow", sourceTag: "日本食品嘌呤表", nameEn: "Sea bass", sourceTagEn: "Japanese purine table"),
        .init(name: "鱼露", uricPer100g: 200, level: "red", sourceTag: "东南亚食品表", nameEn: "Fish sauce", sourceTagEn: "SE Asian food table"),
        .init(name: "虾酱", uricPer100g: 220, level: "red", sourceTag: "卫健委2024", nameEn: "Shrimp paste", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "鸡精/浓汤宝", uricPer100g: 500, level: "red", sourceTag: "Drugs.com", nameEn: "Chicken bouillon / stock cubes", sourceTagEn: "Drugs.com"),
        .init(name: "酵母粉（烘焙/啤酒酵母）", uricPer100g: 700, level: "red", sourceTag: "Drugs.com", nameEn: "Yeast extract (baking/brewer's)", sourceTagEn: "Drugs.com"),
        .init(name: "咖啡（美式/黑咖）", uricPer100g: 0, level: "green", sourceTag: "NEJM 咖啡与痛风研究", nameEn: "Coffee (black)", sourceTagEn: "NEJM coffee & gout study"),
        .init(name: "燕麦奶", uricPer100g: 8, level: "green", sourceTag: "USDA", nameEn: "Oat milk", sourceTagEn: "USDA"),
        .init(name: "杏仁奶", uricPer100g: 0, level: "green", sourceTag: "USDA", nameEn: "Almond milk", sourceTagEn: "USDA"),
        .init(name: "意大利面", uricPer100g: 20, level: "green", sourceTag: "USDA", nameEn: "Pasta", sourceTagEn: "USDA"),
        .init(name: "披萨", uricPer100g: 40, level: "yellow", sourceTag: "估算·复合", nameEn: "Pizza", sourceTagEn: "Estimated (composite)"),
        .init(name: "汉堡", uricPer100g: 55, level: "yellow", sourceTag: "估算·复合", nameEn: "Burger", sourceTagEn: "Estimated (composite)"),
        .init(name: "墨西哥卷饼", uricPer100g: 45, level: "yellow", sourceTag: "估算·复合", nameEn: "Burrito", sourceTagEn: "Estimated (composite)"),
        .init(name: "希腊酸奶", uricPer100g: 8, level: "green", sourceTag: "USDA", nameEn: "Greek yogurt", sourceTagEn: "USDA"),
        .init(name: "开菲尔发酵乳", uricPer100g: 8, level: "green", sourceTag: "USDA", nameEn: "Kefir", sourceTagEn: "USDA"),
        .init(name: "树莓", uricPer100g: 5, level: "green", sourceTag: "USDA", nameEn: "Raspberry", sourceTagEn: "USDA"),
        .init(name: "黑莓", uricPer100g: 5, level: "green", sourceTag: "USDA", nameEn: "Blackberry", sourceTagEn: "USDA"),
        .init(name: "无花果", uricPer100g: 15, level: "green", sourceTag: "USDA", nameEn: "Fig", sourceTagEn: "USDA"),
        .init(name: "牛油果", uricPer100g: 10, level: "green", sourceTag: "USDA", nameEn: "Avocado", sourceTagEn: "USDA"),
        .init(name: "菠萝蜜", uricPer100g: 18, level: "green", sourceTag: "USDA", nameEn: "Jackfruit", sourceTagEn: "USDA"),
        .init(name: "山竹", uricPer100g: 8, level: "green", sourceTag: "USDA", nameEn: "Mangosteen", sourceTagEn: "USDA"),
        .init(name: "番石榴", uricPer100g: 8, level: "green", sourceTag: "USDA", nameEn: "Guava", sourceTagEn: "USDA"),
        .init(name: "龙眼", uricPer100g: 15, level: "green", sourceTag: "卫健委2024", nameEn: "Longan", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "红毛丹", uricPer100g: 15, level: "green", sourceTag: "USDA", nameEn: "Rambutan", sourceTagEn: "USDA"),
        .init(name: "紫甘蓝", uricPer100g: 8, level: "green", sourceTag: "USDA", nameEn: "Red cabbage", sourceTagEn: "USDA"),
        .init(name: "羽衣甘蓝", uricPer100g: 10, level: "green", sourceTag: "USDA", nameEn: "Kale", sourceTagEn: "USDA"),
        .init(name: "秋葵", uricPer100g: 10, level: "green", sourceTag: "卫健委2024", nameEn: "Okra", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "豆苗", uricPer100g: 60, level: "yellow", sourceTag: "卫健委2024", nameEn: "Pea shoots", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "荷兰豆", uricPer100g: 40, level: "green", sourceTag: "USDA", nameEn: "Snow peas", sourceTagEn: "USDA"),
        .init(name: "蘑菇（口蘑）", uricPer100g: 50, level: "yellow", sourceTag: "卫健委2024", nameEn: "Button mushrooms", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "香菇（干）", uricPer100g: 350, level: "red", sourceTag: "卫健委2024（干品浓缩）", nameEn: "Dried shiitake", sourceTagEn: "NHHC 2024 (dried concentrate)"),
        .init(name: "木耳（水发）", uricPer100g: 15, level: "green", sourceTag: "卫健委2024", nameEn: "Wood ear (rehydrated)", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "银耳（水发）", uricPer100g: 15, level: "green", sourceTag: "卫健委2024", nameEn: "Snow fungus (rehydrated)", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "鹌鹑蛋", uricPer100g: 5, level: "green", sourceTag: "卫健委2024", nameEn: "Quail eggs", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "牛肉干", uricPer100g: 250, level: "red", sourceTag: "脱水浓缩·Drugs.com", nameEn: "Beef jerky", sourceTagEn: "Dehydrated concentrate · Drugs.com"),
        .init(name: "猪肉脯", uricPer100g: 240, level: "red", sourceTag: "脱水浓缩·Drugs.com", nameEn: "Pork jerky", sourceTagEn: "Dehydrated concentrate · Drugs.com"),
        .init(name: "鸡胸肉", uricPer100g: 130, level: "yellow", sourceTag: "卫健委2024", nameEn: "Chicken breast", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "鸡腿肉", uricPer100g: 140, level: "yellow", sourceTag: "卫健委2024", nameEn: "Chicken thigh", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "鸭血", uricPer100g: 30, level: "green", sourceTag: "卫健委2024", nameEn: "Duck blood curd", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "羊肉串", uricPer100g: 150, level: "red", sourceTag: "估算·烧烤浓缩", nameEn: "Lamb skewers", sourceTagEn: "Estimated (BBQ concentrate)"),
        .init(name: "烤鸭", uricPer100g: 145, level: "red", sourceTag: "估算·卫健委基表", nameEn: "Roast duck", sourceTagEn: "Estimated (NHHC base)"),
        .init(name: "鹅肝", uricPer100g: 400, level: "red", sourceTag: "Drugs.com（内脏最高档）", nameEn: "Goose liver (foie gras)", sourceTagEn: "Drugs.com（内脏最高档）"),
        .init(name: "夜宵·炒粉/炒面", uricPer100g: 40, level: "yellow", sourceTag: "估算·复合", nameEn: "Late-night stir-fried noodles", sourceTagEn: "Estimated (composite)"),
        .init(name: "夜宵·烤串（综合）", uricPer100g: 160, level: "red", sourceTag: "估算·复合", nameEn: "Late-night BBQ skewers", sourceTagEn: "Estimated (composite)"),
        .init(name: "夜宵·小龙虾", uricPer100g: 140, level: "red", sourceTag: "卫健委2024", nameEn: "Late-night crayfish", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "酒会·下酒拼盘", uricPer100g: 150, level: "red", sourceTag: "估算·复合", nameEn: "Party platter", sourceTagEn: "Estimated (composite)"),
        .init(name: "婚宴·宴席（综合）", uricPer100g: 130, level: "red", sourceTag: "估算·复合", nameEn: "Wedding banquet", sourceTagEn: "Estimated (composite)"),
        .init(name: "晚宴·西式套餐", uricPer100g: 100, level: "yellow", sourceTag: "估算·复合", nameEn: "Western dinner set", sourceTagEn: "Estimated (composite)"),
        .init(name: "聚会·火锅（已在场景）", uricPer100g: 200, level: "red", sourceTag: "估算·汤底浓缩", nameEn: "Hot pot party", sourceTagEn: "估算·汤底浓缩"),
        .init(name: "蛋糕（奶油）", uricPer100g: 8, level: "green", sourceTag: "USDA", nameEn: "Cream cake", sourceTagEn: "USDA"),
        .init(name: "提拉米苏", uricPer100g: 10, level: "green", sourceTag: "USDA", nameEn: "Tiramisu", sourceTagEn: "USDA"),
        .init(name: "马卡龙", uricPer100g: 5, level: "green", sourceTag: "USDA", nameEn: "Macaron", sourceTagEn: "USDA"),
        .init(name: "月饼", uricPer100g: 15, level: "green", sourceTag: "卫健委2024", nameEn: "Mooncake", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "绿豆糕", uricPer100g: 20, level: "green", sourceTag: "卫健委2024", nameEn: "Mung bean cake", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "蛋黄酥", uricPer100g: 15, level: "green", sourceTag: "卫健委2024", nameEn: "Egg yolk pastry", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "薯片", uricPer100g: 15, level: "green", sourceTag: "USDA（嘌呤低但高脂高盐）", nameEn: "Potato chips", sourceTagEn: "USDA（嘌呤低但高脂高盐）"),
        .init(name: "巧克力（黑巧 70%）", uricPer100g: 20, level: "green", sourceTag: "USDA", nameEn: "Dark chocolate (70%)", sourceTagEn: "USDA"),
        .init(name: "冰淇淋", uricPer100g: 5, level: "green", sourceTag: "USDA（高糖注意）", nameEn: "Ice cream", sourceTagEn: "USDA（高糖注意）"),
        .init(name: "果冻", uricPer100g: 2, level: "green", sourceTag: "USDA", nameEn: "Jelly", sourceTagEn: "USDA"),
        .init(name: "辣条", uricPer100g: 30, level: "yellow", sourceTag: "估算·调味浓缩", nameEn: "Spicy strips (latiao)", sourceTagEn: "估算·调味浓缩"),
        .init(name: "锅巴", uricPer100g: 25, level: "green", sourceTag: "卫健委2024", nameEn: "Crispy rice", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "海苔", uricPer100g: 100, level: "yellow", sourceTag: "日本食品嘌呤表（干品）", nameEn: "Nori (dried)", sourceTagEn: "日本食品嘌呤表（干品）"),
        .init(name: "话梅", uricPer100g: 10, level: "green", sourceTag: "USDA", nameEn: "Dried plum", sourceTagEn: "USDA"),
        .init(name: "坚果混合装", uricPer100g: 30, level: "green", sourceTag: "USDA（适量·热量高）", nameEn: "Mixed nuts", sourceTagEn: "USDA（适量·热量高）"),
        // ---- 欧洲板块（健哥11-21深夜令：全球扩容第二波）----
        .init(name: "法式鹅肝酱", uricPer100g: 420, level: "red", sourceTag: "Drugs.com（内脏制品最高档）", nameEn: "Foie gras (French)", sourceTagEn: "Drugs.com（内脏制品最高档）"),
        .init(name: "法式洋葱汤", uricPer100g: 25, level: "green", sourceTag: "估算·法国菜谱基表", nameEn: "French onion soup", sourceTagEn: "估算·法国菜谱基表"),
        .init(name: "法式蜗牛（勃艮第）", uricPer100g: 80, level: "yellow", sourceTag: "法国食品成分表", nameEn: "Escargots de Bourgogne", sourceTagEn: "French food composition table"),
        .init(name: "法棍面包", uricPer100g: 15, level: "green", sourceTag: "USDA", nameEn: "Baguette", sourceTagEn: "USDA"),
        .init(name: "可颂", uricPer100g: 10, level: "green", sourceTag: "USDA", nameEn: "Croissant", sourceTagEn: "USDA"),
        .init(name: "法式咸派（洛林糕）", uricPer100g: 60, level: "yellow", sourceTag: "估算·复合（培根奶油）", nameEn: "Quiche Lorraine", sourceTagEn: "估算·复合（培根奶油）"),
        .init(name: "马赛鱼汤", uricPer100g: 120, level: "red", sourceTag: "估算·复合（多种海鱼浓缩汤底）", nameEn: "Bouillabaisse", sourceTagEn: "估算·复合（多种海鱼浓缩汤底）"),
        .init(name: "生蚝拼盘（法国）", uricPer100g: 165, level: "red", sourceTag: "Drugs.com", nameEn: "Oyster platter (French)", sourceTagEn: "Drugs.com"),
        .init(name: "蓝纹奶酪", uricPer100g: 15, level: "green", sourceTag: "USDA", nameEn: "Blue cheese", sourceTagEn: "USDA"),
        .init(name: "布里奶酪", uricPer100g: 10, level: "green", sourceTag: "USDA", nameEn: "Brie", sourceTagEn: "USDA"),
        .init(name: "帕玛森奶酪", uricPer100g: 15, level: "green", sourceTag: "USDA", nameEn: "Parmesan", sourceTagEn: "USDA"),
        .init(name: "马苏里拉奶酪", uricPer100g: 10, level: "green", sourceTag: "USDA", nameEn: "Mozzarella", sourceTagEn: "USDA"),
        .init(name: "意大利帕尔玛火腿", uricPer100g: 130, level: "red", sourceTag: "Drugs.com（腌制肉类）", nameEn: "Prosciutto", sourceTagEn: "Drugs.com（腌制肉类）"),
        .init(name: "意式萨拉米", uricPer100g: 140, level: "red", sourceTag: "Drugs.com（腌制肉类）", nameEn: "Salami", sourceTagEn: "Drugs.com（腌制肉类）"),
        .init(name: "意式肉酱面（博洛尼亚）", uricPer100g: 70, level: "yellow", sourceTag: "估算·复合（牛肉酱）", nameEn: "Spaghetti Bolognese", sourceTagEn: "Estimated (beef sauce)"),
        .init(name: "意式烩饭（海鲜）", uricPer100g: 90, level: "yellow", sourceTag: "估算·复合", nameEn: "Seafood risotto", sourceTagEn: "Estimated (composite)"),
        .init(name: "意式烩饭（蘑菇）", uricPer100g: 50, level: "yellow", sourceTag: "估算·复合", nameEn: "Mushroom risotto", sourceTagEn: "Estimated (composite)"),
        .init(name: "千层面", uricPer100g: 65, level: "yellow", sourceTag: "估算·复合", nameEn: "Lasagna", sourceTagEn: "Estimated (composite)"),
        .init(name: "西班牙海鲜饭", uricPer100g: 95, level: "yellow", sourceTag: "估算·复合（虾贝）", nameEn: "Paella", sourceTagEn: "Estimated (shrimp & shellfish)"),
        .init(name: "西班牙火腿（伊比利亚）", uricPer100g: 125, level: "red", sourceTag: "Drugs.com", nameEn: "Iberian ham", sourceTagEn: "Drugs.com"),
        .init(name: "西班牙油条（吉拿棒）", uricPer100g: 10, level: "green", sourceTag: "USDA", nameEn: "Churros", sourceTagEn: "USDA"),
        .init(name: "德国白香肠", uricPer100g: 120, level: "red", sourceTag: "德国联邦食品库", nameEn: "Weisswurst", sourceTagEn: "German federal food DB"),
        .init(name: "德国猪肘", uricPer100g: 140, level: "red", sourceTag: "德国联邦食品库", nameEn: "Pork knuckle (German)", sourceTagEn: "German federal food DB"),
        .init(name: "德国酸菜", uricPer100g: 8, level: "green", sourceTag: "德国联邦食品库", nameEn: "Sauerkraut", sourceTagEn: "German federal food DB"),
        .init(name: "德国碱水面包（布雷结）", uricPer100g: 15, level: "green", sourceTag: "USDA", nameEn: "Pretzel (German)", sourceTagEn: "USDA"),
        .init(name: "黑麦面包", uricPer100g: 18, level: "green", sourceTag: "USDA", nameEn: "Rye bread", sourceTagEn: "USDA"),
        .init(name: "俄式鱼子酱", uricPer100g: 145, level: "red", sourceTag: "俄罗斯食品表（鱼卵嘌呤浓缩）", nameEn: "Caviar (Russian)", sourceTagEn: "俄罗斯食品表（鱼卵嘌呤浓缩）"),
        .init(name: "俄式红鱼子", uricPer100g: 120, level: "red", sourceTag: "俄罗斯食品表", nameEn: "Red caviar", sourceTagEn: "Russian food table"),
        .init(name: "俄式罗宋汤（牛肉甜菜汤）", uricPer100g: 55, level: "yellow", sourceTag: "估算·复合", nameEn: "Borscht", sourceTagEn: "Estimated (composite)"),
        .init(name: "俄式腌鲱鱼", uricPer100g: 155, level: "red", sourceTag: "俄罗斯食品表（腌制浓缩）", nameEn: "Pickled herring", sourceTagEn: "俄罗斯食品表（腌制浓缩）"),
        .init(name: "俄式饺子（佩尔梅尼）", uricPer100g: 60, level: "yellow", sourceTag: "估算·复合（肉馅）", nameEn: "Pelmeni", sourceTagEn: "估算·复合（肉馅）"),
        .init(name: "俄式蜂蜜蛋糕", uricPer100g: 12, level: "green", sourceTag: "USDA", nameEn: "Medovik (honey cake)", sourceTagEn: "USDA"),
        .init(name: "伏特加（俄罗斯标准）", uricPer100g: 0, level: "red", sourceTag: "ACR 2020（酒精代谢抑排泄）", nameEn: "Vodka (Russian standard)", sourceTagEn: "ACR 2020（酒精代谢抑排泄）"),
        .init(name: "格瓦斯", uricPer100g: 10, level: "yellow", sourceTag: "俄罗斯食品表（发酵麦芽饮）", nameEn: "Kvass", sourceTagEn: "俄罗斯食品表（发酵麦芽饮）"),
        .init(name: "英国炸鱼薯条", uricPer100g: 85, level: "yellow", sourceTag: "估算·复合（鳕鱼）", nameEn: "Fish & chips (UK)", sourceTagEn: "估算·复合（鳕鱼）"),
        .init(name: "英式早餐（全套）", uricPer100g: 95, level: "yellow", sourceTag: "估算·复合（香肠培根蛋）", nameEn: "Full English breakfast", sourceTagEn: "估算·复合（香肠培根蛋）"),
        .init(name: "苏格兰蛋", uricPer100g: 100, level: "yellow", sourceTag: "估算·复合", nameEn: "Scotch egg", sourceTagEn: "Estimated (composite)"),
        .init(name: "希腊烤羊肉串", uricPer100g: 145, level: "red", sourceTag: "估算·卫健委基表", nameEn: "Greek lamb souvlaki", sourceTagEn: "Estimated (NHHC base)"),
        .init(name: "希腊 gyro 卷", uricPer100g: 110, level: "yellow", sourceTag: "估算·复合", nameEn: "Gyro wrap", sourceTagEn: "Estimated (composite)"),
        .init(name: "中东烤肉串（Kebab）", uricPer100g: 130, level: "red", sourceTag: "估算·卫健委基表", nameEn: "Kebab", sourceTagEn: "Estimated (NHHC base)"),
        .init(name: "中东鹰嘴豆泥", uricPer100g: 40, level: "green", sourceTag: "USDA（豆类嘌呤植物源）", nameEn: "Hummus", sourceTagEn: "USDA（豆类嘌呤植物源）"),
        .init(name: "土耳其烤肉（Doner）", uricPer100g: 135, level: "red", sourceTag: "估算·复合", nameEn: "Doner kebab", sourceTagEn: "Estimated (composite)"),
        .init(name: "瑞士芝士火锅", uricPer100g: 12, level: "green", sourceTag: "USDA（高脂注意）", nameEn: "Cheese fondue", sourceTagEn: "USDA（高脂注意）"),
        .init(name: "荷兰鲱鱼生吃", uricPer100g: 155, level: "red", sourceTag: "荷兰食品表（腌制鲱鱼）", nameEn: "Raw herring (Dutch)", sourceTagEn: "荷兰食品表（腌制鲱鱼）"),
        .init(name: "比利时淡菜薯条", uricPer100g: 110, level: "red", sourceTag: "估算·贝类", nameEn: "Moules-frites", sourceTagEn: "Estimated (shellfish)"),
        .init(name: "葡萄牙烤沙丁鱼", uricPer100g: 180, level: "red", sourceTag: "日本食品嘌呤表（沙丁鱼族）", nameEn: "Grilled sardines (Portuguese)", sourceTagEn: "日本食品嘌呤表（沙丁鱼族）"),
        .init(name: "葡萄牙蛋挞", uricPer100g: 10, level: "green", sourceTag: "USDA", nameEn: "Pastel de nata", sourceTagEn: "USDA"),
        // ---- 美洲板块 ----
        .init(name: "美式烧烤（BBQ 排骨）", uricPer100g: 140, level: "red", sourceTag: "估算·卫健委基表", nameEn: "BBQ ribs", sourceTagEn: "Estimated (NHHC base)"),
        .init(name: "美式牛排（西冷）", uricPer100g: 135, level: "red", sourceTag: "USDA", nameEn: "Steak", sourceTagEn: "USDA"),
        .init(name: "美式热狗", uricPer100g: 145, level: "red", sourceTag: "Drugs.com", nameEn: "Hot dog", sourceTagEn: "Drugs.com"),
        .init(name: "美式水牛城鸡翅", uricPer100g: 145, level: "red", sourceTag: "USDA", nameEn: "Buffalo wings", sourceTagEn: "USDA"),
        .init(name: "德州烤牛腩", uricPer100g: 130, level: "red", sourceTag: "USDA", nameEn: "Texas brisket", sourceTagEn: "USDA"),
        .init(name: "路易斯安那小龙虾锅", uricPer100g: 140, level: "red", sourceTag: "估算·甲壳类", nameEn: "Crawfish boil (Louisiana)", sourceTagEn: "Estimated (crustaceans)"),
        .init(name: "墨西哥卷饼（牛肉）", uricPer100g: 75, level: "yellow", sourceTag: "估算·复合", nameEn: "Beef burrito", sourceTagEn: "Estimated (composite)"),
        .init(name: "墨西哥玉米片配鳄梨酱", uricPer100g: 20, level: "green", sourceTag: "USDA", nameEn: "Tortilla chips & guacamole", sourceTagEn: "USDA"),
        .init(name: "墨西哥法士达（Fajita）", uricPer100g: 80, level: "yellow", sourceTag: "估算·复合", nameEn: "Fajitas", sourceTagEn: "Estimated (composite)"),
        .init(name: "墨西哥玉米粽（Tamale）", uricPer100g: 35, level: "green", sourceTag: "估算·复合", nameEn: "Tamale", sourceTagEn: "Estimated (composite)"),
        .init(name: "秘鲁酸橘汁腌鱼（Ceviche）", uricPer100g: 105, level: "yellow", sourceTag: "估算·生鱼", nameEn: "Ceviche", sourceTagEn: "Estimated (raw fish)"),
        .init(name: "巴西烤肉（Churrasco）", uricPer100g: 135, level: "red", sourceTag: "USDA", nameEn: "Churrasco", sourceTagEn: "USDA"),
        .init(name: "巴西黑豆炖肉（Feijoada）", uricPer100g: 90, level: "yellow", sourceTag: "估算·复合（猪肉豆）", nameEn: "Feijoada", sourceTagEn: "估算·复合（猪肉豆）"),
        .init(name: "阿根廷烤肠（Chorizo）", uricPer100g: 130, level: "red", sourceTag: "Drugs.com", nameEn: "Chorizo", sourceTagEn: "Drugs.com"),
        .init(name: "加拿大肉汁奶酪薯条（Poutine）", uricPer100g: 55, level: "yellow", sourceTag: "估算·复合", nameEn: "Poutine", sourceTagEn: "Estimated (composite)"),
        .init(name: "美式蛤蜊浓汤（New England）", uricPer100g: 90, level: "yellow", sourceTag: "估算·贝类", nameEn: "New England clam chowder", sourceTagEn: "Estimated (shellfish)"),
        .init(name: "美式蟹饼（Crab Cake）", uricPer100g: 130, level: "red", sourceTag: "USDA", nameEn: "Crab cake", sourceTagEn: "USDA"),
        .init(name: "阿拉斯加帝王蟹腿", uricPer100g: 135, level: "red", sourceTag: "USDA", nameEn: "King crab legs (Alaska)", sourceTagEn: "USDA"),
        .init(name: "加拿大烟熏三文鱼", uricPer100g: 145, level: "red", sourceTag: "日本食品嘌呤表（烟熏浓缩）", nameEn: "Smoked salmon (Canada)", sourceTagEn: "日本食品嘌呤表（烟熏浓缩）"),
        // ---- 非洲/大洋洲补位 ----
        .init(name: "摩洛哥塔吉锅（羊肉）", uricPer100g: 125, level: "red", sourceTag: "估算·卫健委基表", nameEn: "Tagine (lamb)", sourceTagEn: "Estimated (NHHC base)"),
        .init(name: "埃塞俄比亚英杰拉饼", uricPer100g: 20, level: "green", sourceTag: "USDA（苔麸粉）", nameEn: "Injera (Ethiopian)", sourceTagEn: "USDA（苔麸粉）"),
        .init(name: "南非干肉条（Biltong）", uricPer100g: 240, level: "red", sourceTag: "脱水浓缩·Drugs.com", nameEn: "Biltong", sourceTagEn: "Dehydrated concentrate · Drugs.com"),
        .init(name: "澳大利亚肉派", uricPer100g: 70, level: "yellow", sourceTag: "估算·复合", nameEn: "Meat pie (Aussie)", sourceTagEn: "Estimated (composite)"),
        .init(name: "新西兰青口贝", uricPer100g: 120, level: "red", sourceTag: "澳新食品标准局", nameEn: "Green mussels (NZ)", sourceTagEn: "FSANZ (AU/NZ)"),
        .init(name: "新西兰炸鱼薯条", uricPer100g: 85, level: "yellow", sourceTag: "估算·复合", nameEn: "Fish & chips (NZ)", sourceTagEn: "Estimated (composite)"),
        // ---- 通用补充 ----
        .init(name: "鱼头汤", uricPer100g: 220, level: "red", sourceTag: "估算·浓缩汤底", nameEn: "Fish head soup", sourceTagEn: "Estimated (concentrated broth)"),
        .init(name: "鱼籽寿司", uricPer100g: 150, level: "red", sourceTag: "日本食品嘌呤表", nameEn: "Roe sushi", sourceTagEn: "Japanese purine table"),
        .init(name: "海胆", uricPer100g: 100, level: "yellow", sourceTag: "日本食品嘌呤表", nameEn: "Sea urchin", sourceTagEn: "Japanese purine table"),
        .init(name: "蟹膏", uricPer100g: 180, level: "red", sourceTag: "日本食品嘌呤表", nameEn: "Crab butter", sourceTagEn: "Japanese purine table"),
        .init(name: "蟹黄", uricPer100g: 185, level: "red", sourceTag: "卫健委2024", nameEn: "Crab roe", sourceTagEn: "NHHC 2024 (China)"),
        .init(name: "虾脑", uricPer100g: 200, level: "red", sourceTag: "日本食品嘌呤表", nameEn: "Shrimp head paste", sourceTagEn: "Japanese purine table"),
        .init(name: "干贝（瑶柱）", uricPer100g: 390, level: "red", sourceTag: "干品浓缩·卫健委2024", nameEn: "Dried scallops", sourceTagEn: "Dried concentrate · NHHC 2024"),
        .init(name: "蚝干", uricPer100g: 380, level: "red", sourceTag: "干品浓缩·卫健委2024", nameEn: "Dried oysters", sourceTagEn: "Dried concentrate · NHHC 2024"),
        .init(name: "虾米（干）", uricPer100g: 400, level: "red", sourceTag: "干品浓缩·卫健委2024", nameEn: "Dried shrimp", sourceTagEn: "Dried concentrate · NHHC 2024"),

    ]
}

// MARK: - 更新日志（用户反馈回环标注——v6 反馈案例）

struct ChangelogView: View {
    private let entries: [(version: String, date: String, items: [(String, Bool)])] = [
        ("0.1.0", L("First release", "首个版本"), [(L("3-second flare logging, purine library, lab values, water tracking", "3 秒发作记录、嘌呤库、化验值、饮水打卡"), false)]),
    ]

    var body: some View {
        List {
            ForEach(entries, id: \.version) { e in
                Section(header: Text("v\(e.version) · \(e.date)")) {
                    ForEach(e.items, id: \.0) { item, fromFeedback in
                        HStack(alignment: .top, spacing: 8) {
                            Text(item).font(.callout)
                            if fromFeedback {
                                Text(L("From user feedback", "来自用户反馈"))
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
        .navigationTitle(L("Changelog", "更新日志"))
    }
}

// MARK: - 反馈/评分（v7/v8 文案；评分只在主动点击时触发）

enum FeedbackHelper {
    static func open() {
        let subject = L("UricNote - user feedback", "UricNote 尿酸笔记 - 用户反馈")
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
                Text(L("High uric acid is more than gout.", "高尿酸，不只是痛风。"))
                    .font(.title2.bold())
                Text(L("Gout is when uric acid crystals form in joints — but its impact goes beyond joints. Long-term high uric acid quietly affects multiple organs.", "尿酸高在关节形成结晶时是痛风；但它的影响不止关节——长期高尿酸会悄悄波及多个器官。"))
                    .font(.callout)
                    .foregroundColor(.secondary)

                Divider()

                harmRow("person.fill", L("Kidneys", "肾脏"),
                        L("Urate crystals can deposit in kidneys and urinary tract — chronic kidney disease risk rises; uric acid stones are common.", "尿酸盐可沉积在肾间质和尿路——高尿酸人群慢性肾病风险显著升高；尿酸性肾结石也常见。"))
                harmRow("heart.fill", L("Cardiovascular", "心血管"),
                        L("Studies link high uric acid with hypertension and atherosclerosis — one signal of metabolic dysfunction.", "流行病学研究提示高尿酸与高血压、动脉硬化相关——它是代谢异常的信号灯之一。"))
                harmRow("square.stack.3d.up.fill", L("Metabolic health", "代谢整体"),
                        L("High uric acid often travels with obesity, high cholesterol, fatty liver and high blood sugar — part of metabolic syndrome.", "高尿酸常与肥胖、高血脂、脂肪肝、高血糖结伴出现——代谢综合征的成员之一。"))
                harmRow("brain.head.profile", L("Related conditions", "关联疾病"),
                        L("Observational studies link high uric acid with diabetes and NAFLD — managing it is part of metabolic care.", "观察性研究报道高尿酸与糖尿病、非酒精性脂肪肝等存在关联——机制复杂，管理尿酸是整体代谢管理的一环。"))

                Divider()

                Text(L("The good news", "好消息")).font(.headline)
                Text(L("Once managed to target (per your doctor), crystals can slowly dissolve and risk falls — that's what daily logging is for: visible trends, informed adjustments.", "达标管理（具体目标遵医嘱）后，结晶可以逐渐溶解，风险随之回落——这正是每天记录的意义：让趋势可见，让调整有据。"))
                    .font(.callout)

                Text(L("A summary of published research for education — not medical advice. Sources: ACR 2020 guideline / published studies.", "以上为公开研究共识的科普整理，不构成诊断或治疗建议。数据来源：ACR 2020 指南 / 公开流行病学研究。"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle(L("Risks of high uric acid", "高尿酸的危害"))
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
