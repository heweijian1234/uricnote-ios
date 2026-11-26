import Foundation
import StoreKit

// MARK: - Pro 买断（一次性，非消耗型）
// 免费：无限记录、仪表盘、趋势图（近 90 天）、食物库、用药提醒、学习内容
// Pro ：门诊记录/生活记录导出（PDF / CSV / 文本）+ 全部历史趋势
//
// 2026-11-25：11-21「门诊记录放开换反馈」的临时状态结束，按 11-23 十资产报告恢复收费。

@MainActor
final class ProStore: ObservableObject {

    static let productID = "com.zeronelabs.uricnote.pro"

    @Published private(set) var isPro = false
    @Published private(set) var product: Product?
    @Published private(set) var isLoading = false
    @Published var message: String?

    /// 商店没返回价格时的兜底显示（仅文案，不参与计价）
    /// 真实售价以 App Store Connect 为准；这里只是断网/商品未就绪时的占位
    var priceText: String {
        product?.displayPrice ?? "$19.99"
    }

    func load() async {
        await refresh()
        do {
            let items = try await Product.products(for: [Self.productID])
            product = items.first
        } catch {
            // 拉不到商品不阻塞使用：已购用户照常解锁，未购用户点了会提示重试
        }
    }

    func refresh() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.productID && transaction.revocationDate == nil {
                owned = true
            }
        }
        isPro = owned
    }

    func purchase() async {
        guard let product else {
            message = L("Product is unavailable right now. Please try again in a moment.",
                        "商品暂时不可用，请稍后再试。")
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    message = L("The purchase could not be verified.", "购买凭证校验失败。")
                    return
                }
                await transaction.finish()
                isPro = true
            case .userCancelled:
                break
            case .pending:
                message = L("The purchase is pending approval.", "购买正在等待批准。")
            @unknown default:
                break
            }
        } catch {
            message = error.localizedDescription
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
        } catch {
            // 用户中途取消也会走到这里，不当作错误
        }
        await refresh()
        if !isPro {
            message = L("No previous purchase was found for this Apple ID.",
                        "该 Apple ID 名下没有查到购买记录。")
        }
    }
}
