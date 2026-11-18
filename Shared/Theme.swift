import SwiftUI
import UIKit

// MARK: - 统一色板 v11.1 · 2026-11-18（设计升级：温暖治愈系浅色，Waterllama 色系参照）
// 全部动态 UIColor 三元支持暗色模式；语义映射：
//   brand=品牌按钮/强调/TaskRing  appBG=页面底  cardBG=卡片底
//   success=达标/绿区/完成  warn=黄区/警告  danger=红区/发作/删除  water=喝水/尿色

extension Color {
    /// 主色：鼠尾草绿偏暖（替代零散 teal/blue/purple）
    static let brand = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.45, green: 0.78, blue: 0.72, alpha: 1)   // #73C7B8
        : UIColor(red: 0.13, green: 0.55, blue: 0.50, alpha: 1) })// #228C80

    /// 页面底色：暖米白
    static let appBG = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.09, green: 0.10, blue: 0.11, alpha: 1)   // #17191C
        : UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1) })// #FAF7F0

    /// 卡片底色
    static let cardBG = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.14, green: 0.16, blue: 0.17, alpha: 1)   // #242A2C
        : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) })   // #FFFFFF

    /// 成功/达标/绿区
    static let success = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.40, green: 0.80, blue: 0.55, alpha: 1)   // #66CC8C
        : UIColor(red: 0.22, green: 0.62, blue: 0.39, alpha: 1) })// #389E63

    /// 警告/黄区（接替旧 amber）
    static let warn = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.98, green: 0.76, blue: 0.35, alpha: 1)   // #FAC259
        : UIColor(red: 0.90, green: 0.60, blue: 0.13, alpha: 1) })// #E69921

    /// 危险/红区/发作
    static let danger = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.95, green: 0.48, blue: 0.45, alpha: 1)   // #F27A73
        : UIColor(red: 0.82, green: 0.26, blue: 0.24, alpha: 1) })// #D2423D

    /// 喝水/尿色专用蓝（水系页不混主色）
    static let water = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.42, green: 0.72, blue: 0.95, alpha: 1)   // #6BB8F2
        : UIColor(red: 0.16, green: 0.55, blue: 0.85, alpha: 1) })// #298CD9

    /// 疼痛 5 档色彩编码（1-10 → 绿→黄→红插值；Daylio 式）
    static func pain(_ level: Int) -> Color {
        switch level {
        case 1...2: return success
        case 3...4: return Color(red: 0.55, green: 0.75, blue: 0.25)
        case 5...6: return warn
        case 7...8: return Color(red: 0.88, green: 0.48, blue: 0.20)
        default: return danger
        }
    }

    /// 兼容旧代码的 amber（逐步迁移到 warn 后删除）
    static let amber = warn
}
