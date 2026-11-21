import Foundation

// MARK: - 双语切换（2026-11-22 上架令：英文上架版——G/H 同款机制）
// 机制：全部 UI 字符串经 L() 取值；上架=en。中文测试版改回 .zh 即可。
// 翻译口径：患者用语优先（flare=发作/gout=痛风/uric acid=尿酸），非学术腔

enum AppLang {
    case en
    case zh

    static let current: AppLang = .en   // 🔴上架版=英文。中文测试版改回 .zh
}

func L(_ en: String, _ zh: String) -> String {
    AppLang.current == .en ? en : zh
}
