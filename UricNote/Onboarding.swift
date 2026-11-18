import SwiftUI

// MARK: - Onboarding v11.1（动机锚 → 健康档案引导 → 愿景页；种子步已取消）
// v11.1：第2步从"习惯种子"改为"健康档案"引导（种子功能暂时下线，健哥裁）

struct OnboardingView: View {
    @ObservedObject var store = Store.shared
    @State private var step = 0
    @State private var motivation: MotivationChoice?
    @State private var heightText = ""
    @State private var weightText = ""
    @State private var ageText = ""
    @State private var gender = "男"

    var body: some View {
        VStack(spacing: 0) {
            // 进度点
            HStack(spacing: 8) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(i <= step ? Color.brand : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 24)

            Spacer()

            switch step {
            case 0: motivationStep
            case 1: profileStep
            default: visionStep
            }

            Spacer()

            // 底部按钮
            HStack(spacing: 12) {
                Button("跳过") { finish() }
                    .foregroundColor(.secondary)
                Button(action: { next() }) {
                    Text(step == 2 ? "开始使用" : (step == 1 ? "保存并继续" : "下一步"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(step == 0 && motivation == nil ? Color.gray.opacity(0.3) : Color.brand)
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
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.brand)
                        }
                    }
                    .padding(16)
                    .background(motivation == c ? Color.brand.opacity(0.12) : Color.cardBG)
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

    // 第2步：健康档案引导（v11.1：替换原习惯种子步——A6 档案前置，越早填报告越完整）
    private var profileStep: some View {
        VStack(spacing: 20) {
            Text("先认识一下你")
                .font(.title2.bold())
            Text("身高体重年龄性别——医生看记录先想知道这些。只存本机，可以以后再补。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    TextField("身高 cm", text: $heightText).keyboardType(.numberPad)
                    TextField("体重 kg", text: $weightText).keyboardType(.decimalPad)
                }
                .padding(12)
                .background(Color.cardBG)
                .cornerRadius(12)
                HStack(spacing: 10) {
                    TextField("年龄", text: $ageText).keyboardType(.numberPad)
                    Picker("性别", selection: $gender) {
                        Text("男").tag("男"); Text("女").tag("女"); Text("其他").tag("其他")
                    }
                    .pickerStyle(.menu)
                }
                .padding(12)
                .background(Color.cardBG)
                .cornerRadius(12)
            }

            Text("想填更全（疾病/过敏/家族史）可以之后在仪表盘的「健康档案」卡里补。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private func saveProfileIfFilled() {
        if let h = Double(heightText), h > 0 { store.profile.heightCm = h }
        if let w = Double(weightText), w > 0 { store.profile.weightKg = w }
        if let a = Int(ageText), a > 0 { store.profile.age = a }
        store.profile.gender = gender
        if store.profile.heightCm != nil || store.profile.age != nil {
            store.profile.isComplete = true
        }
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
                .foregroundColor(.brand)
                .frame(width: 22)
            Text(text).font(.callout)
        }
    }

    private func next() {
        if step == 0 {
            if let m = motivation { store.meta.motivation = m }
            step = 1
        } else if step == 1 {
            saveProfileIfFilled()
            step = 2
        } else {
            finish()
        }
    }

    private func finish() {
        // 跳过也记录动机（若有）
        if let m = motivation { store.meta.motivation = m }
        store.meta.onboardingDone = true
        store.meta.lastOpenedAt = Date()
        store.save()
    }
}
