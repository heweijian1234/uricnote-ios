import SwiftUI
import UIKit

// MARK: - v11.1 新组件（Streaks/Daylio/HabitKit/Waterllama 设计手法落地）
// 设计纪律（Apple HIG）：不模仿 Activity rings 双层渐变环——用自定图形语言（细描边圆+中心符号）

// MARK: 触感反馈薄封装

enum Haptic {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: TaskRing 圆形任务圈（Streaks 式：完成=实心填充+勾，未完成=灰细描边）

struct TaskRing: View {
    var done: Bool
    var tint: Color = .brand

    var body: some View {
        ZStack {
            Circle()
                .stroke(done ? tint : Color.secondary.opacity(0.25), lineWidth: 3)
            if done {
                Circle()
                    .fill(tint)
                    .padding(4)
                Image(systemName: "checkmark")
                    .font(.footnote.bold())
                    .foregroundColor(.white)
            } else {
                Image(systemName: "circle.dashed")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 40, height: 40)
    }
}

// MARK: WaterGaugeView 水位杯（Waterllama 简化版：矩形填充+spring 动画，纯色降险）

struct WaterGaugeView: View {
    var fraction: CGFloat   // 0...1 = totalMl/goalMl

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.water.opacity(0.4), lineWidth: 2)
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.water.opacity(0.85))
                    .frame(height: geo.size.height * min(max(fraction, 0), 1))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: fraction)
            }
        }
    }
}

// MARK: HeatGrid 记录坚持热力格（HabitKit/GitHub 式：90 天，13 列×7 行，4 档色）

struct HeatGrid: View {
    var levels: [Date: Int]   // 0=未记录 1-3=记了几类

    private var days: [Date] {
        (0..<91).reversed().compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: Calendar.current.startOfDay(for: Date()))
        }
    }

    private func color(for level: Int) -> Color {
        switch level {
        case 1: return Color.brand.opacity(0.35)
        case 2: return Color.brand.opacity(0.65)
        case 3: return Color.brand
        default: return Color.cardBG
        }
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 13), spacing: 3) {
            ForEach(days, id: \.self) { d in
                RoundedRectangle(cornerRadius: 3)
                    .fill(color(for: levels[d] ?? 0))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}

// MARK: FoodChip 食物图标胶囊（Daylio 式：点选高亮，零键盘）

struct FoodChip: View {
    var name: String
    var selected: Bool
    var tint: Color
    var action: () -> Void

    var body: some View {
        Button {
            Haptic.tap()
            action()
        } label: {
            Text(name)
                .font(.callout)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(selected ? tint.opacity(0.18) : Color.cardBG)
                .foregroundColor(selected ? tint : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selected ? tint : Color.secondary.opacity(0.2), lineWidth: selected ? 1.5 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
