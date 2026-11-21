import SwiftUI

// MARK: - 反馈一级页 v11.1 #6（健哥令：需要足够的用户反馈——入口独立强化）

struct FeedbackPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 大按钮（brand 色圆角大卡）
                Button {
                    FeedbackHelper.open()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.brand)
                        Text(L("Write feedback to the developer", "给开发者写反馈"))
                            .font(.headline)
                        Text(L("Opens a pre-filled email — just write", "点开就是一封预填好的邮件，直接写就行"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(Color.brand.opacity(0.10))
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text(L("Anything you want to say", "说什么都可以"))
                        .font(.subheadline.weight(.semibold))
                    feedbackRow(L("What's clunky", "哪别扭"), L("A page feels clunky, entry is hidden, text too small…", "某个页面用着别扭、找不到入口、字太小……"))
                    feedbackRow(L("What you wish existed", "想要什么"), L("what to log, what trends to see, what to cut", "希望记录什么、希望看到什么趋势、希望少点什么"))
                    feedbackRow(L("Criticism", "批评"), L("Criticism is most valuable — every message gets read", "批评最有价值——每一条都会被认真读"))
                    feedbackRow(L("Report a bug", "报问题"), L("Crash / data loss / display error — note roughly when it happened", "闪退/数据丢了/显示错了，写上大概什么时候发生的"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.cardBG)
                .cornerRadius(14)
                .padding(.horizontal)

                NavigationLink {
                    ChangelogView()
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath").foregroundColor(.brand)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L("Changelog", "更新日志")).font(.callout.weight(.medium))
                            Text(L("Many improvements come from user feedback", "不少改进来自用户反馈")).font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(Color.cardBG)
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                Text(L("Your feedback directly shapes where this app goes.", "你的反馈直接决定这个 App 往哪走。"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.vertical, 20)
        }
        .navigationTitle(L("Feedback", "反馈"))
        .background(Color.appBG)
    }

    private func feedbackRow(_ title: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.brand)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout.weight(.medium))
                Text(desc).font(.caption).foregroundColor(.secondary)
            }
        }
    }
}
