import Foundation

// MARK: - 双语切换（2026-11-22 上架令：英文上架版——G/H 同款机制）
// 机制：全部 UI 字符串经 L() 取值；上架=en。中文测试版改回 .zh 即可。
// 翻译口径：患者用语优先（flare=发作/gout=痛风/uric acid=尿酸），非学术腔

enum AppLang {
    case en
    case zh

    // 健哥11-22令：中文版自己用——语言跟随手机系统（中文系统=中文，其他=英文上架版）
    // 上架只上一份包：美区用户英文，健哥手机中文，不用维护两个版本
    static let current: AppLang = {
        // Bundle.preferredLanguages 首选语言含 zh（简/繁/中国区）即中文
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("zh") ? .zh : .en
    }()
}

func L(_ en: String, _ zh: String) -> String {
    AppLang.current == .en ? en : zh
}
