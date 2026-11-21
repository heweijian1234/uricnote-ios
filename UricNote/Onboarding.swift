import SwiftUI

// MARK: - Onboarding v11.1（动机锚 → 健康档案引导 → 愿景页；种子步已取消）
// v11.1：第2步从"习惯种子"改为"健康档案"引导（种子功能暂时下线，健哥裁）

struct OnboardingView: View {
    @ObservedObject var store = Store.shared
    @State private var step = 0
    @State private var motivation: MotivationChoice?
    @State private var otherMotivationText = ""   // 健哥11-21令：其他-自填
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
                        .background(step == 0 && (motivation == nil || (motivation == .other && otherMotivationText.trimmingCharacters(in: .whitespaces).isEmpty)) ? Color.gray.opacity(0.3) : Color.brand)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(step == 0 && (motivation == nil || (motivation == .other && otherMotivationText.trimmingCharacters(in: .whitespaces).isEmpty)))
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
            // 健哥11-21令：选"其他"展开自填框（这段话会放在仪表盘一直陪你）
            if motivation == .other {
                TextField("写下你的原因…（它会出现在仪表盘）", text: $otherMotivationText, axis: .vertical)
                    .lineLimit(2...3)
                    .padding(12)
                    .background(Color.cardBG)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
    }

    private func icon(for c: MotivationChoice) -> String {
        switch c {
        case .painFree: return "sun.max"
        case .work: return "briefcase"
        case .family: return "heart"
        case .other: return "pencil.circle"
        }
    }

    // 第2步：健康档案引导（v11.1：替换原习惯种子步——A6 档案前置，越早填报告越完整）
    private var profileStep: some View {
        VStack(spacing: 20) {
            Text("我是你的伙伴，想认识一下你")
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

    // 第3步：愿景页（健哥11-21令全量改版——伙伴口吻/蜕变宣言/功能重述/选择理由重写）
    private var visionStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("这不只是一份记录。")
                    .font(.title.bold())
                Text("这是一次尊重身体，自我救赎的蜕变。愿你能更幸福的生活。")
                    .font(.body)
                    .foregroundColor(.secondary)

                Divider()

                Text("我们相信")
                    .font(.headline)
                Text("尿酸降不下来，从来不是因为你不努力——七成由身体代谢决定，剩下三成才轮到生活方式。这里不评判你，只帮你把能控制的三成管好，只需要养成习惯。")
                    .font(.callout)

                Text("现在就能用")
                    .font(.headline)
                visionRow(icon: "fork.knife", text: "食物嘌呤清单，带临床指南背书")
                visionRow(icon: "brain", text: "每天回忆记录，寻找疼痛的嘌呤因子进行改善")
                visionRow(icon: "pills", text: "提醒吃药，记录喝水量习惯")
                visionRow(icon: "doc.text", text: "一页报告带给医生，让他快速且详细的了解你的近况，获得更准确的建议")

                Text("会随时间长大")
                    .font(.headline)
                visionRow(icon: "chart.line.uptrend.xyaxis", text: "会随时间记录，画出你的蜕变之路")
                visionRow(icon: "calendar", text: "7 天后，看到你的习惯趋势线")
                visionRow(icon: "sparkles", text: "一个月后，发现疼痛前共同吃了什么")
                visionRow(icon: "figure.walk", text: "更远处：我是一直陪你走过来的朋友")

                Text("选择我的理由")
                    .font(.headline)
                visionRow(icon: "person.crop.circle.badge.checkmark", text: "开发者本人就是高尿酸痛风患者，正在改善的路上，此 App 是自用也是想帮助更多患友")
                visionRow(icon: "checkmark.seal", text: "免费使用，持续更新，日后不排除买断制与订阅制，但与你无关——开发初期，下载的患友都是终身免费使用")
                visionRow(icon: "stethoscope", text: "设计依据是公开的临床试验节律，不是营销噱头")
                visionRow(icon: "wand.and.stars", text: "设计细节会加入开发者的个人心得")

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
            store.meta.motivationCustomText = motivation == .other && !otherMotivationText.trimmingCharacters(in: .whitespaces).isEmpty ? otherMotivationText.trimmingCharacters(in: .whitespaces) : nil
            step = 1
        } else if step == 1 {
            saveProfileIfFilled()
            step = 2
        } else {
            finish()
        }
    }

    private func finish() {
        // 健哥11-21令：跳过也保存已填的身高体重年龄（防"填了却没带到档案"二次填写）
        saveProfileIfFilled()
        // 跳过也记录动机（若有）
        if let m = motivation { store.meta.motivation = m }
        if motivation == .other && !otherMotivationText.trimmingCharacters(in: .whitespaces).isEmpty {
            store.meta.motivationCustomText = otherMotivationText.trimmingCharacters(in: .whitespaces)
        }
        store.meta.onboardingDone = true
        store.meta.lastOpenedAt = Date()
        store.save()
    }
}
