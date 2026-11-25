import SwiftUI

// MARK: - 付费墙（UricNote 风格：暖米白底 / 白卡片 / 鼠尾草绿）

struct ProPaywallView: View {
    @EnvironmentObject private var pro: ProStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    benefits
                    buySection
                    legal
                }
                .padding(.horizontal, 22)
                .padding(.top, 34)
                .padding(.bottom, 40)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.cardBG))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 18)
            .padding(.top, 14)
        }
        .task {
            if pro.product == nil { await pro.load() }
        }
        .alert(pro.message ?? "", isPresented: Binding(
            get: { pro.message != nil },
            set: { if !$0 { pro.message = nil } }
        )) {
            Button(L("OK", "知道了")) { pro.message = nil }
        }
    }

    // MARK: 头部

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "seal.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("PRO")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.2)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.brand))

            Text(L("UricNote Pro", "UricNote Pro"))
                .font(.title2.bold())
                .foregroundColor(.primary)

            Text(L("Pay once. Keep it forever.",
                   "一次买断，永久使用。"))
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: 权益

    private var benefits: some View {
        VStack(spacing: 12) {
            benefitRow(
                icon: "doc.text.fill",
                title: L("Clinic report export", "门诊记录导出"),
                body: L("One page your doctor can read in 15 minutes — every lab value, flare, medication and habit, honestly marked where data is missing. PDF, CSV or plain text.",
                        "一页纸，医生 15 分钟就能看完——每次化验、每次发作、用药、习惯全在里面，缺记录的地方如实标「未记录」。支持 PDF、CSV、纯文本。")
            )
            benefitRow(
                icon: "chart.line.uptrend.xyaxis",
                title: L("Your full history", "全部历史趋势"),
                body: L("The free version shows the last 90 days. Pro shows every lab value you have ever logged — the long arc is what your doctor actually needs.",
                        "免费版显示最近 90 天。Pro 显示你记录过的全部化验值——医生真正要看的，是那条长曲线。")
            )
        }
    }

    private func benefitRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.brand)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.brand.opacity(0.12)))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
                Text(body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineSpacing(2.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBG))
    }

    // MARK: 购买

    private var buySection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await pro.purchase() }
            } label: {
                HStack(spacing: 8) {
                    if pro.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(L("Unlock for \(pro.priceText)", "\(pro.priceText) 解锁"))
                            .font(.body.weight(.semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.brand))
            }
            .buttonStyle(.plain)
            .disabled(pro.isLoading)

            Button {
                Task { await pro.restore() }
            } label: {
                Text(L("Restore purchase", "恢复购买"))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.brand)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    // MARK: 说明

    private var legal: some View {
        Text(L("One-time purchase, not a subscription. Charged to your Apple ID. Restore it any time on any device signed in with the same Apple ID.",
               "一次性买断，不是订阅。费用由 Apple ID 扣款；换设备后用同一 Apple ID 可随时恢复。"))
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .padding(.horizontal, 8)
    }
}

// MARK: - PRO 小胶囊（列表行标题旁）

struct ProTag: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 8.5, weight: .heavy))
            .tracking(0.6)
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.brand))
    }
}

// MARK: - 锁提示条（列表里插一行用）

struct ProLockRow: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.brand))
                VStack(alignment: .leading, spacing: 2) {
                    Text(text)
                        .font(.callout.weight(.medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Text(L("Tap to see what Pro includes", "点击查看 Pro 包含什么"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
