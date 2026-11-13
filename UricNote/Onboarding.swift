import SwiftUI

// MARK: - Onboarding 三步（v10：动机锚 → 习惯种子 → 愿景页，全可跳过）

struct OnboardingView: View {
    @ObservedObject var store = Store.shared
    @State private var step = 0
    @State private var motivation: MotivationChoice?
    @State private var seedType = "water"
    @State private var seedAnchor = "早上起床后"

    private let anchors = ["早上起床后", "早上刷牙后", "吃完晚饭后", "睡前"]

    var body: some View {
        VStack(spacing: 0) {
            // 进度点
            HStack(spacing: 8) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(i <= step ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 24)

            Spacer()

            switch step {
            case 0: motivationStep
            case 1: seedStep
            default: visionStep
            }

            Spacer()

            // 底部按钮
            HStack(spacing: 12) {
                Button("跳过") { finish() }
                    .foregroundColor(.secondary)
                Button(action: { next() }) {
                    Text(step == 2 ? "开始使用" : "下一步")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(step == 0 && motivation == nil ? Color.gray.opacity(0.3) : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(step == 0 && motivation == nil)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // 第1步：动机三选一（v8 动机锚——用户选的成为仪表盘铭牌+文案定制轴）
    private var motivationStep: some View {
        VStack(spacing: 20) {
            Text("你管理尿酸，最重要的原因是？")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("选一个最像你的——它会一直陪着你")
                .font(.subheadline)
                .foregroundColor(.secondary)
            ForEach(MotivationChoice.allCases, id: \.self) { c in
                Button {
                    motivation = c
                } label: {
                    HStack {
                        Image(systemName: icon(for: c))
                            .font(.title3)
                        Text(c.rawValue)
                            .font(.body.weight(.medium))
                        Spacer()
                        if motivation == c {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor)
                        }
                    }
                    .padding(16)
                    .background(motivation == c ? Color.accentColor.opacity(0.12) : Color(.systemGray6))
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
    }

    private func icon(for c: MotivationChoice) -> String {
        switch c {
        case .painFree: return "sun.max"
        case .work: return "briefcase"
        case .family: return "heart"
        }
    }

    // 第2步：习惯种子（v9：只选一颗，Fogg 配方）
    private var seedStep: some View {
        VStack(spacing: 20) {
            Text("先从一件最小的事开始")
                .font(.title2.bold())
            Text("不用改变人生。选一颗「习惯种子」，小到最忙的一天也能做。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                seedCard(type: "water", title: "每天喝一杯水", subtitle: "最简单的开始")
                seedCard(type: "med", title: "每晚记一次药", subtitle: "如果你在服药")
                seedCard(type: "weigh", title: "每周称一次体重", subtitle: "减重是降尿酸的搭档")
            }

            Picker("什么时候做", selection: $seedAnchor) {
                ForEach(anchors, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(.horizontal, 24)
    }

    private func seedCard(type: String, title: String, subtitle: String) -> some View {
        Button {
            seedType = type
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body.weight(.medium))
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if seedType == type {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor)
                }
            }
            .padding(14)
            .background(seedType == type ? Color.accentColor.opacity(0.12) : Color(.systemGray6))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    // 第3步：愿景页（v10 完整版——理由三条含"开发者本人就是高尿酸患者"）
    private var visionStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("这不是一个记录工具。")
                    .font(.title.bold())
                Text("这是一条从「被疼痛打醒」走到「痛风不再占据你的脑子」的路。")
                    .font(.body)
                    .foregroundColor(.secondary)

                Divider()

                Text("我们相信什么")
                    .font(.headline)
                Text("尿酸降不下来，从来不是因为你不努力——七成由身体代谢决定，剩下三成才轮到生活方式。这里不评判你，只帮你把能控制的三成管好。")
                    .font(.callout)

                Text("现在就能用")
                    .font(.headline)
                visionRow(icon: "bolt", text: "3 秒记一次发作，半夜痛醒也能记")
                visionRow(icon: "fork.knife", text: "食物嘌呤一查就知道，带临床指南背书")
                visionRow(icon: "pills", text: "吃药喝水，一屏搞定")
                visionRow(icon: "doc.text", text: "一页报告带给医生——他只有 15 分钟，这一页足够")

                Text("会随时间长大")
                    .font(.headline)
                visionRow(icon: "chart.line.uptrend.xyaxis", text: "7 天后，看到你的趋势线")
                visionRow(icon: "sparkles", text: "1 个月后，告诉你发作前共同吃了什么")
                visionRow(icon: "rosette", text: "90 天无痛 + 尿酸达标，点亮「已控制」")
                visionRow(icon: "figure.walk", text: "更远处：它是你身边那个记性很好的病友")

                Text("选择它的理由")
                    .font(.headline)
                visionRow(icon: "checkmark.seal", text: "免费记录，一次买断解锁全部——无订阅、无广告")
                visionRow(icon: "stethoscope", text: "设计依据是公开的临床试验节律，不是营销噱头")
                visionRow(icon: "person.crop.circle.badge.checkmark", text: "开发者本人就是高尿酸患者——每条反馈都会被认真读")

                Text("本 App 是记录工具，不提供诊断或治疗建议。数据来源：ACR 2020 指南 / G-CAN 2024 缓解标准 / 公开临床试验。")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
        }
    }

    private func visionRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 22)
            Text(text).font(.callout)
        }
    }

    private func next() {
        if step == 0 {
            if let m = motivation { store.meta.motivation = m }
            step = 1
        } else if step == 1 {
            let s = Seed(type: seedType, anchorMoment: seedAnchor, startDate: Date())
            store.seed = s
            store.save()
            step = 2
        } else {
            finish()
        }
    }

    private func finish() {
        // 跳过也记录动机（若有），种子给默认水
        if let m = motivation { store.meta.motivation = m }
        if store.seed == nil {
            store.seed = Seed(type: "water", anchorMoment: "早上起床后", startDate: Date())
        }
        store.meta.onboardingDone = true
        store.meta.lastOpenedAt = Date()
        store.save()
    }
}
