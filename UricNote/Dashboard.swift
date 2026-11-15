import SwiftUI

// MARK: - Tab1 仪表盘（三数字+已控制徽章+动机铭牌+今日待办+断记确认触发）

struct DashboardView: View {
    @ObservedObject var store = Store.shared
    @State private var showGapConfirm = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if store.needsGapConfirm {
                        gapBanner
                    }
                    wellControlledBadge
                    bigNumbers
                    motivationPlaque
                    todayTodos
                    quickActions
                }
                .padding()
            }
            .navigationTitle("尿酸笔记")
            .sheet(isPresented: $showGapConfirm) { GapConfirmView() }
            .onAppear {
                if store.needsGapConfirm { showGapConfirm = true }
            }
        }
    }

    // 断记横幅（v10 微调：静默不吓人）
    private var gapBanner: some View {
        Button {
            showGapConfirm = true
        } label: {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                Text("有几天没记录了——补个确认，报告更准确")
                    .font(.callout)
                Spacer()
                Image(systemName: "chevron.right").font(.caption)
            }
            .padding(12)
            .background(Color.amber.opacity(0.15))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // 已控制徽章（v9：无痛≥90+达标双条件；副文案=mental load 红利）
    @ViewBuilder
    private var wellControlledBadge: some View {
        if store.wellControlled {
            VStack(spacing: 4) {
                Label("已控制", systemImage: "rosette")
                    .font(.title2.bold())
                Text("痛风不再占据你的脑子")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.green.opacity(0.12))
            .cornerRadius(16)
        }
    }

    // 三数字（v9 措辞：无痛X天/距目标/复查倒计时）
    private var bigNumbers: some View {
        HStack(spacing: 12) {
            bigNum(value: store.flareFreeDays.map { "\($0)" } ?? "—", label: "无痛天数", footnote: store.flareFreeDays == nil ? "记录第一次发作后开始计数" : flareFootnote)
            bigNum(value: deltaText, label: "距目标", footnote: "目标 <6.0 mg/dL")
            bigNum(value: reviewText, label: "复查倒计时", footnote: "临床试验验证的节律")
        }
    }

    private var deltaText: String {
        guard let d = store.deltaToTarget else { return "—" }
        return String(format: "%.1f", abs(d)) + (d < 0 ? "✓" : "")
    }

    private var reviewText: String {
        guard let d = store.daysToReview else { return "—" }
        return "\(d)天"
    }

    // 三段递进（v9：正在路上→结晶在溶解→已控制）
    private var flareFootnote: String {
        guard let d = store.flareFreeDays else { return "" }
        if d == 0 { return "从今天开始计数" }   // P1: 刚记完发作不嘲讽（v8 安抚）
        if d < 30 { return "正在路上" }
        if d < 90 { return "结晶在溶解" }
        return "已控制标准：90 天+达标"
    }

    private var motivationPlaque: some View {
        Group {
            if let m = store.meta.motivation {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.pink)
                    Text("为了：\(m.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // 今日待办条（种子行为打卡入口）
    private var todayTodos: some View {
        VStack(spacing: 8) {
            if let seed = store.seed {
                HStack {
                    Image(systemName: "leaf")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("习惯种子：\(seedTitle(seed.type))").font(.callout.weight(.medium))
                        Text("锚点：\(seed.anchorMoment) · 连续 \(seed.realStreak) 天（实时记录才计数）")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("打卡") {
                        seedDone(seed)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            if let plan = store.medPlans.first(where: { $0.active }) {
                HStack {
                    Image(systemName: "pills").foregroundColor(.blue)
                    Text("服药：\(plan.name) \(plan.dose)").font(.callout)
                    Spacer()
                    NavigationLink("记录") { MedTodayView() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }

    private func seedTitle(_ t: String) -> String {
        switch t {
        case "water": return "每天喝一杯水"
        case "med": return "每晚记一次药"
        case "weigh": return "每周称一次体重"
        default: return t
        }
    }

    private func seedDone(_ seed: Seed) {
        var s = seed
        s.realStreak += 1
        if s.realStreak >= 14 { s.unlockedSecond = true }
        store.seed = s
        store.meta.seedVotesTotal += 1
        store.save()
        // 即时庆祝（Fogg：1 秒内；v9 情绪激励）
        UricCelebrate.show("Done — that's today handled.")
    }

    // 快捷入口（发作 3 秒置顶原则）
    private var quickActions: some View {
        VStack(spacing: 10) {
            NavigationLink {
                FlareEditorView()
            } label: {
                Label("记一次发作", systemImage: "exclamationmark.triangle")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            HStack(spacing: 10) {
                NavigationLink("记化验值") { UricReadingEditor() }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                NavigationLink("记饮水") { WaterEditor() }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
}

struct bigNum: View {
    let value: String
    let label: String
    let footnote: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title.bold())
            Text(label).font(.caption.weight(.medium))
            Text(footnote).font(.caption2).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
}

// MARK: - 断记确认弹层（v7 健哥修正案+v10 微调2：confirmed 不投票）

struct GapConfirmView: View {
    @ObservedObject var store = Store.shared
    @Environment(\.dismiss) var dismiss
    @State private var answer: String = ""

    private var gapStart: Date {
        store.meta.lastOpenedAt ?? Calendar.current.date(byAdding: .day, value: -3, to: Date())!
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.largeTitle)
                .foregroundColor(.amber)
            Text("过去几天没有你的记录")
                .font(.title3.bold())
            Text("这段时间服药正常吗？")
                .font(.body)
            VStack(spacing: 10) {
                gapButton("✓ 正常，都吃了", value: "normal")
                gapButton("✗ 有漏", value: "missed")
                gapButton("— 不记得 / 不想补", value: "unknown")
            }
            Text("确认后，报告里这几天才会标为「按计划」；不确认则标「未记录」——医生看报告时能分清哪些是实测、哪些是补记，避免误判你的真实情况。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("先跳过") { dismiss() }
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(24)
    }

    private func gapButton(_ title: String, value: String) -> some View {
        Button {
            answer = value
            store.confirmGap(
                start: Calendar.current.date(byAdding: .day, value: -2, to: gapStart) ?? gapStart,
                end: Date(),
                answer: value
            )
            store.meta.lastOpenedAt = Date()
            store.save()
            dismiss()
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 庆祝组件（Fogg：动作后 1 秒内；全 App 共用）

enum UricCelebrate {
    static func show(_ text: String) {
        let toast = UILabel()
        toast.text = "✓ " + text
        toast.font = .systemFont(ofSize: 14, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.92)
        toast.textAlignment = .center
        toast.numberOfLines = 0
        toast.layer.cornerRadius = 14
        toast.clipsToBounds = true
        toast.frame = CGRect(x: 30, y: 100, width: UIScreen.main.bounds.width - 60, height: 44)
        toast.autoresizingMask = [.flexibleWidth]
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = scene.windows.first(where: { $0.isKeyWindow }) {
            window.addSubview(toast)
            toast.transform = CGAffineTransform(translationX: 0, y: -60)
            UIView.animate(withDuration: 0.25) { toast.transform = .identity }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                UIView.animate(withDuration: 0.3, animations: { toast.alpha = 0 }) { _ in
                    toast.removeFromSuperview()
                }
            }
        }
    }
}

extension Color {
    static let amber = Color(red: 0.96, green: 0.70, blue: 0.20)
}
