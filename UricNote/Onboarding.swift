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
    @State private var gender = L("Male", "男")

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
                Button(L("Skip", "跳过")) { finish() }
                    .foregroundColor(.secondary)
                Button(action: { next() }) {
                    Text(step == 2 ? L("Get Started", "开始使用")) : (step == 1 ? L("Save & continue", "保存并继续") : L("Next", "下一步")))
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
            Text(L("What matters most to you about managing uric acid?", "你管理尿酸，最重要的原因是？"))
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(L("Pick the one that sounds most like you — it will stay with you", "选一个最像你的——它会一直陪着你"))
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
                TextField(L("Write your reason… (it will show on your dashboard)", "写下你的原因…（它会出现在仪表盘）"), text: $otherMotivationText, axis: .vertical)
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
            Text(L("I'm your companion — I'd like to know you", "我是你的伙伴，想认识一下你"))
                .font(.title2.bold())
            Text(L("Height, weight, age, gender — the first things a doctor wants to see. Stored only on this phone; fill in later.", "身高体重年龄性别——医生看记录先想知道这些。只存本机，可以以后再补。"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    TextField(L("Height cm", "身高 cm"), text: $heightText).keyboardType(.numberPad)
                    TextField(L("Weight kg", "体重 kg"), text: $weightText).keyboardType(.decimalPad)
                }
                .padding(12)
                .background(Color.cardBG)
                .cornerRadius(12)
                HStack(spacing: 10) {
                    TextField(L("Age", "年龄"), text: $ageText).keyboardType(.numberPad)
                    Picker(L("Gender", "性别"), selection: $gender) {
                        Text(L("Male", "男")).tag("男"); Text(L("Female", "女")).tag("女"); Text(L("Other", "其他")).tag("其他")
                    }
                    .pickerStyle(.menu)
                }
                .padding(12)
                .background(Color.cardBG)
                .cornerRadius(12)
            }

            Text(L("For more (conditions / allergies / family history), fill in the Health Profile card on the dashboard later.", "想填更全（疾病/过敏/家族史）可以之后在仪表盘的「健康档案」卡里补。"))
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
                Text(L("This is more than a record.", "这不只是一份记录。"))
                    .font(.title.bold())
                Text(L("It's a transformation that respects your body — a way back to yourself. May you live happier.", "这是一次尊重身体，自我救赎的蜕变。愿你能更幸福的生活。"))
                    .font(.body)
                    .foregroundColor(.secondary)

                Divider()

                Text(L("What we believe", "我们相信"))
                    .font(.headline)
                Text(L("If your uric acid won't come down, it's never because you're not trying — 70% is metabolism, the rest is lifestyle. No judgment here; we just help you manage what you can control. All it takes is a habit.", "尿酸降不下来，从来不是因为你不努力——七成由身体代谢决定，剩下三成才轮到生活方式。这里不评判你，只帮你把能控制的三成管好，只需要养成习惯。"))
                    .font(.callout)

                Text(L("What you can use right now", "现在就能用"))
                    .font(.headline)
                visionRow(icon: "fork.knife", text: L("A purine food list backed by clinical guidelines.", "食物嘌呤清单，带临床指南背书"))
                visionRow(icon: "brain", text: L("A daily recall log to find the purine triggers behind your pain", "每天回忆记录，寻找疼痛的嘌呤因子进行改善"))
                visionRow(icon: "pills", text: L("Medication reminders and water tracking", "提醒吃药，记录喝水量习惯"))
                visionRow(icon: "doc.text", text: L("A one-page report for your doctor — quick to read, detailed enough for better advice", "一页报告带给医生，让他快速且详细的了解你的近况，获得更准确的建议"))

                Text(L("It grows with you", "会随时间长大"))
                    .font(.headline)
                visionRow(icon: "chart.line.uptrend.xyaxis", text: L("Your entries add up into a picture of your progress", "会随时间记录，画出你的蜕变之路"))
                visionRow(icon: "calendar", text: L("In 7 days, see your habit trends", "7 天后，看到你的习惯趋势线"))
                visionRow(icon: "sparkles", text: L("In a month, discover what you ate before flares", "一个月后，发现疼痛前共同吃了什么"))
                visionRow(icon: "figure.walk", text: L("Further ahead: a friend who's been with you all along", "更远处：我是一直陪你走过来的朋友"))

                Text(L("Why this app", "选择我的理由"))
                    .font(.headline)
                visionRow(icon: "person.crop.circle.badge.checkmark", text: L("The developer has high uric acid and gout too — building this for himself and for fellow patients", "开发者本人就是高尿酸痛风患者，正在改善的路上，此 App 是自用也是想帮助更多患友"))
                visionRow(icon: "checkmark.seal", text: L("Free to use, constantly updated. Paid tiers may come someday, but early adopters keep full access forever", "免费使用，持续更新，日后不排除买断制与订阅制，但与你无关——开发初期，下载的患友都是终身免费使用"))
                visionRow(icon: "stethoscope", text: L("Built on published clinical research, not marketing", "设计依据是公开的临床试验节律，不是营销噱头"))
                visionRow(icon: "wand.and.stars", text: L("Design details come from the developer's own experience", "设计细节会加入开发者的个人心得"))

                Text(L("This app is a logging tool, not medical advice. Sources: ACR 2020 guideline / G-CAN 2024 / published trials.", "本 App 是记录工具，不提供诊断或治疗建议。数据来源：ACR 2020 指南 / G-CAN 2024 缓解标准 / 公开临床试验。"))
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
        // 🔴健哥11-22实测实锤"每次进都弹前三屏"——防御性双写：
        // 独立key直写 UserDefaults（绕开 meta Codable 链路一切可能的解码失败回退）
        UserDefaults.standard.set(true, forKey: "ur.onboarded.v2")
    }
}
