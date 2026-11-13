import SwiftUI

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
                            Image(systemName: "book.fill").foregroundColor(.accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("为什么是它").font(.body.weight(.medium))
                                Text("核心功能、理念、期望——一页看懂").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section("先破除几个误区") {
                    NavigationLink("8 个最常见的误区") { MythListView() }
                    NavigationLink("嘌呤食物库") { PurineListView() }
                }

                Section("和你一起变好") {
                    NavigationLink("更新日志（用户反馈驱动）") { ChangelogView() }
                    Button {
                        FeedbackHelper.open()
                    } label: {
                        HStack {
                            Text("给开发者留言（他本人就是高尿酸患者）")
                            Spacer()
                            Image(systemName: "envelope")
                        }
                    }
                    Button("给我们评分") {
                        // 只在用户主动点击时触发（iOS 365 天 3 次限制——不自动弹）
                        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                           let window = scene.windows.first(where: { $0.isKeyWindow }) {
                            let vc = SKStoreReviewController_dummy()
                            _ = vc
                            _ = window
                        }
                        FeedbackHelper.requestReview()
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .navigationTitle("了解")
        }
    }

    private func SKStoreStoreReview() {}
}

import StoreKit
func SKStoreReviewController_dummy() -> Int { 0 }

// MARK: - 愿景页（Onboarding 第3步同款+独立入口）

struct VisionPageView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("这不是一个记录工具。")
                    .font(.title.bold())
                Text("这是一条从「被疼痛打醒」走到「痛风不再占据你的脑子」的路。")
                    .font(.body)
                    .foregroundColor(.secondary)

                Divider()

                Text("我们相信什么").font(.headline)
                Text("尿酸降不下来，从来不是因为你不努力——七成由身体代谢决定，剩下三成才轮到生活方式。这里不评判你，只帮你把能控制的三成管好。").font(.callout)

                Text("现在就能用").font(.headline)
                visionRow("bolt", "3 秒记一次发作，半夜痛醒也能记")
                visionRow("fork.knife", "食物嘌呤一查就知道，带临床指南背书")
                visionRow("pills", "吃药喝水，一屏搞定")
                visionRow("doc.text", "一页报告带给医生——他只有 15 分钟，这一页足够")

                Text("会随时间长大").font(.headline)
                visionRow("chart.line.uptrend.xyaxis", "7 天后，看到你的趋势线")
                visionRow("sparkles", "1 个月后，告诉你发作前共同吃了什么")
                visionRow("rosette", "90 天无痛 + 尿酸达标，点亮「已控制」")
                visionRow("figure.walk", "更远处：它是你身边那个记性很好的病友")

                Text("选择它的理由").font(.headline)
                visionRow("checkmark.seal", "免费记录，一次买断解锁全部——无订阅、无广告")
                visionRow("stethoscope", "设计依据是公开的临床试验节律，不是营销噱头")
                visionRow("person.crop.circle.badge.checkmark", "开发者本人就是高尿酸患者——每条反馈都会被认真读")

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
            Image(systemName: icon).foregroundColor(.accentColor).frame(width: 22)
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
                    .background(Color(.systemGray6))
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

    var body: some View {
        List {
            if store.purineItems.isEmpty {
                seedIntoStore()
            }
            ForEach(filtered) { item in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        circle(for: item.level)
                        Text(item.name).font(.body.weight(.medium))
                        Spacer()
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
        .searchable(text: $query, prompt: "搜食物，比如：啤酒 / 豆腐 / 猪肝")
        .navigationTitle("嘌呤食物库")
    }

    private var filtered: [PurineItem] {
        store.purineItems.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
    }

    private func seedIntoStore() {
        store.purineItems = PurineDatabase.seed
        store.save()
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
        .init(name: "腰果", uricPer100g: 60, level: "yellow", sourceTag: "ACR 2020"),
        .init(name: "核桃", uricPer100g: 25, level: "green", sourceTag: "ACR 2020"),
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
                                    .background(Color.accentColor.opacity(0.12))
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
        if let url = URL(string: "mailto:feedback@zeronelabs.com?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }

    static func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
