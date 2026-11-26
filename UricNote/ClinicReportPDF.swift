import UIKit

// MARK: - 门诊记录 PDF（多页手绘：档案 + KPI + 趋势图 + 完整明细表）
//
// 2026-11-26 重做原因：原实现 `ctx.beginPage()` 只调一次，把整份 HTML 转成富文本
// 硬画到一张 A4 上，超出页面的内容（大部分明细）直接被裁掉——导出的 PDF 只有很少信息。
// 而且富文本画不了图表，医生看不到趋势。
//
// 现在：Core Graphics 手绘，按内容自动分页；补上四张图和一张诱因排行；
// 化验/发作表给全部记录而不是前 10 条。

enum ClinicReportPDF {

    static let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)   // A4 pt

    static func make(store: Store) -> Data {
        let readings = store.readings.sorted { $0.date < $1.date }
        let flares = store.flares.sorted { $0.startDate > $1.startDate }

        let fmt = UIGraphicsPDFRendererFormat()
        fmt.documentInfo = [
            kCGPDFContextTitle as String: "UricNote Clinic Record",
            kCGPDFContextCreator as String: "UricNote",
            kCGPDFContextSubject as String: "Patient self-recorded gout / uric acid log"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: fmt)

        return renderer.pdfData { ctx in
            let d = Builder(ctx: ctx, page: pageRect)
            d.beginPage()

            // ── 页眉 ──
            d.masthead(store: store, readingCount: readings.count, flareCount: flares.count)

            // ── 1. 患者档案 ──
            d.sectionTitle(1, L("Patient profile", "患者档案"))
            d.profileGrid(store.profile)

            // ── 2. 关键指标 ──
            d.sectionTitle(2, L("At a glance", "关键指标"))
            d.kpiRow(store: store, flares: flares)

            // ── 3. 尿酸趋势 ──
            if readings.count >= 2 {
                d.sectionTitle(3, L("Uric acid over time", "尿酸趋势"))
                let unitIsUmol = store.meta.unitIsUmol
                let vals = readings.map { unitIsUmol ? $0.urateUnit : $0.valueMgDl }
                let target = unitIsUmol ? 360.0 : 6.0
                d.lineChart(values: vals,
                            dates: readings.map(\.date),
                            target: target,
                            yLabel: unitIsUmol ? "µmol/L" : "mg/dL",
                            height: 150)
                d.caption(L("Dashed line = treatment target (\(unitIsUmol ? "360 µmol/L" : "6.0 mg/dL")). Gaps = no test that period.",
                            "虚线=治疗目标（\(unitIsUmol ? "360 µmol/L" : "6.0 mg/dL")）。断点=该时段没化验，不是正常。"))
            }

            // ── 4. 发作频次（近 12 个月） ──
            let monthly = monthlyFlareCounts(flares)
            if monthly.contains(where: { $0.count > 0 }) {
                d.sectionTitle(4, L("Flares per month (last 12 months)", "每月发作次数（近 12 个月）"))
                d.barChart(values: monthly.map { Double($0.count) },
                           labels: monthly.map { $0.label },
                           colors: monthly.map { $0.count == 0 ? UIColor(white: 0.88, alpha: 1) : UIColor(red: 0.82, green: 0.26, blue: 0.24, alpha: 1) },
                           height: 96,
                           goalLine: nil,
                           unit: L("flares", "次"))
                d.caption(L("Each bar = number of episodes that month. Empty bar = none recorded.",
                            "每根柱=当月发作次数。空柱=没记录发作。"))
            }

            // ── 5. 饮水 / 入睡（近 30 天） ──
            let water30 = Array(store.waterDays.filter { $0.provenance == .recorded }.suffix(30))
            if water30.count >= 3 {
                d.sectionTitle(5, L("Daily water (last 30 recorded days)", "每日饮水（近 30 个记录日）"))
                let goal = Double(water30.first?.goalMl ?? 2000)
                d.barChart(values: water30.map { Double($0.totalMl) },
                           labels: [],
                           colors: water30.map { Double($0.totalMl) >= Double($0.goalMl)
                               ? UIColor(red: 0.16, green: 0.55, blue: 0.85, alpha: 1)
                               : UIColor(red: 0.16, green: 0.55, blue: 0.85, alpha: 0.32) },
                           height: 88,
                           goalLine: goal,
                           unit: "ml")
                let onGoal = water30.filter { $0.totalMl >= $0.goalMl }.count
                d.caption(L("Solid bar = reached the \(Int(goal)) ml goal (\(onGoal)/\(water30.count) days).",
                            "实心柱=达到 \(Int(goal)) ml 目标（\(water30.count) 天里 \(onGoal) 天）。"))
            }

            let sleep30 = Array(store.sleepLogs.sorted { $0.night < $1.night }.suffix(30))
            if sleep30.count >= 3 {
                d.sectionTitle(6, L("Bedtime (last 30 nights)", "入睡时间（近 30 晚）"))
                d.barChart(values: sleep30.map { Double($0.bucket + 1) },
                           labels: [],
                           colors: sleep30.map { $0.bucket >= 2
                               ? UIColor(red: 0.90, green: 0.60, blue: 0.13, alpha: 1)
                               : UIColor(red: 0.055, green: 0.486, blue: 0.4, alpha: 1) },
                           height: 76,
                           goalLine: nil,
                           unit: L("bedtime bucket", "入睡档"),
                           axisTicks: [L("<23:00", "<23点"), L("23–24", "23-24点"), L("0–1", "0-1点"), L("after 1", "1点后")])
                d.caption(L("Bar height = bedtime bucket. Yellow = after midnight (known trigger for many patients).",
                            "柱高=入睡档位。黄色=过了零点（对很多患者是诱因）。"))
            }

            // ── 6. 诱因排行 ──
            let triggers = triggerRanking(store: store)
            if !triggers.isEmpty {
                d.sectionTitle(7, L("Foods common before flares", "发作前共同出现的饮食"))
                d.rankBars(items: triggers)
                d.caption(L("Counted from your own logs: what appeared in the 72 h before each flare. Not a score — just your pattern.",
                            "从你自己的记录统计：每次发作前 72 小时内出现过的饮食。不是评分，是你自己的规律。"))
            }

            // ── 7. 化验明细 ──
            d.sectionTitle(8, L("Uric acid labs — full list", "尿酸化验 — 全部记录"))
            if readings.isEmpty {
                d.emptyNote(L("No lab values recorded.", "没有化验记录。"))
            } else {
                let unitIsUmol = store.meta.unitIsUmol
                d.table(headers: [L("Date", "日期"), L("Urate", "尿酸"), L("Creatinine", "肌酐"), L("Status", "判定"), L("Source", "来源")],
                        widths: [78, 108, 78, 96, 78],
                        rows: readings.reversed().map { r in
                            let v = unitIsUmol ? String(format: "%.0f µmol/L", r.urateUnit) : String(format: "%.2f mg/dL", r.valueMgDl)
                            return [dayString(r.date), v,
                                    r.creatinineMgDl.map { String(format: "%.2f", $0) } ?? "—",
                                    r.atTarget ? L("At target", "达标") : L("Above", "超标"),
                                    r.source == "home" ? L("Home", "家测") : L("Lab", "医院")]
                        })
            }

            // ── 8. 发作明细 ──
            d.sectionTitle(9, L("Flare episodes — full list", "发作记录 — 全部"))
            if flares.isEmpty {
                d.emptyNote(L("No flares recorded.", "没有发作记录。"))
            } else {
                d.table(headers: [L("Date", "日期"), L("Joints", "部位"), L("Peak", "峰值"), L("Walk", "行走"), L("Painkiller", "止痛药"), L("Trigger note", "诱因备注")],
                        widths: [64, 96, 44, 46, 64, 124],
                        rows: flares.map { f in
                            [dayString(f.startDate),
                             f.joints.joined(separator: "/"),
                             "\(f.painPeak)/10",
                             f.canWalk ? L("Yes", "能") : L("No", "不能"),
                             f.tookPainkiller.map { $0 ? L("Yes", "吃了") : L("No", "没吃") } ?? "—",
                             (f.triggerNotes?.isEmpty == false ? f.triggerNotes! : "—")]
                        })
            }

            // ── 9. 用药 ──
            d.sectionTitle(10, L("Medication", "用药"))
            d.medBlock(store: store)

            // ── 10. 生活方式汇总 ──
            d.sectionTitle(11, L("Lifestyle summary", "生活方式汇总"))
            d.lifestyleBlock(store: store)

            // ── 尾注 ──
            d.disclaimer()

            d.finishFooter()
        }
    }

    // MARK: - 统计

    private static func dayString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: d)
    }

    private static func monthlyFlareCounts(_ flares: [Flare]) -> [(label: String, count: Int)] {
        let cal = Calendar.current
        let now = Date()
        var out: [(label: String, count: Int)] = []
        let f = DateFormatter()
        f.dateFormat = L("MMM", "M月")
        for back in stride(from: 11, through: 0, by: -1) {
            guard let monthStart = cal.date(byAdding: .month, value: -back, to: cal.startOfDay(for: now)),
                  let range = cal.dateInterval(of: .month, for: monthStart) else { continue }
            let n = flares.filter { $0.startDate >= range.start && $0.startDate < range.end }.count
            out.append((label: f.string(from: monthStart), count: n))
        }
        return out
    }

    /// 诱因排行：每次发作前 72h 的饮食项，按出现次数排序（与 TriggerRankView 同源逻辑）
    private static func triggerRanking(store: Store) -> [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for flare in store.flares {
            guard let window = Calendar.current.date(byAdding: .hour, value: -72, to: flare.startDate) else { continue }
            let days = store.foodDays.filter { $0.day >= window && $0.day <= flare.startDate && !$0.noTriggerToday }
            for d in days {
                for item in d.items + d.scenes {
                    counts[item, default: 0] += 1
                }
            }
        }
        return counts.sorted { $0.value > $1.value }.prefix(5).map { (name: foodDisplayName($0.key), count: $0.value) }
    }

    // MARK: - 绘制器

    final class Builder {
        private let ctx: UIGraphicsPDFRendererContext
        private let page: CGRect
        private let m: CGFloat = 40
        private var y: CGFloat = 0
        private var pageNo = 0

        private let brand = UIColor(red: 0.055, green: 0.486, blue: 0.40, alpha: 1)   // #0E7C66
        private let ink = UIColor(red: 0.10, green: 0.12, blue: 0.12, alpha: 1)
        private let sub = UIColor(red: 0.42, green: 0.44, blue: 0.43, alpha: 1)
        private let hair = UIColor(white: 0.90, alpha: 1)

        init(ctx: UIGraphicsPDFRendererContext, page: CGRect) {
            self.ctx = ctx
            self.page = page
        }

        private var contentW: CGFloat { page.width - m * 2 }
        private var bottomLimit: CGFloat { page.height - m - 22 }

        // MARK: 页面

        func beginPage() {
            ctx.beginPage()
            pageNo += 1
            y = m
            // 窄页眉
            let f = UIFont.systemFont(ofSize: 7.5, weight: .medium)
            draw("UricNote · Clinic Record", font: f, color: sub,
                 rect: CGRect(x: m, y: page.height - m - 14, width: contentW / 2, height: 10))
            let p = "\(L("Page", "第")) \(pageNo)"
            draw(p, font: f, color: sub, align: .right,
                 rect: CGRect(x: page.width - m - contentW / 2, y: page.height - m - 14, width: contentW / 2, height: 10))
        }

        func finishFooter() {
            // 最后一页的页码已在 beginPage 里画好，这里只补一条收尾线
            let path = UIBezierPath()
            path.move(to: CGPoint(x: m, y: min(y + 6, page.height - m - 20)))
            path.addLine(to: CGPoint(x: page.width - m, y: min(y + 6, page.height - m - 20)))
            hair.setStroke()
            path.lineWidth = 0.5
            path.stroke()
        }

        private func need(_ h: CGFloat) {
            if y + h > bottomLimit { beginPage() }
        }

        // MARK: 文本

        @discardableResult
        private func draw(_ s: String, font: UIFont, color: UIColor,
                          align: NSTextAlignment = .left,
                          rect: CGRect) -> CGFloat {
            let ps = NSMutableParagraphStyle()
            ps.alignment = align
            ps.lineBreakMode = .byTruncatingTail
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: ps]
            let h = (s as NSString).boundingRect(with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
                                                 options: .usesLineFragmentOrigin, attributes: attrs, context: nil).height
            (s as NSString).draw(with: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: min(h, rect.height)),
                                 options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            return h
        }

        func masthead(store: Store, readingCount: Int, flareCount: Int) {
            draw(L("UricNote · Clinic Record", "UricNote · 就诊记录"),
                 font: .systemFont(ofSize: 21, weight: .bold), color: brand,
                 rect: CGRect(x: m, y: y, width: contentW - 150, height: 26))
            let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
            draw(L("Generated \(df.string(from: Date()))", "生成于 \(df.string(from: Date()))"),
                 font: .systemFont(ofSize: 8.5), color: sub, align: .right,
                 rect: CGRect(x: page.width - m - 170, y: y + 2, width: 170, height: 12))
            draw(L("Patient self-reported log · \(readingCount) labs · \(flareCount) flares",
                   "患者自我记录 · \(readingCount) 条化验 · \(flareCount) 次发作"),
                 font: .systemFont(ofSize: 8.5), color: sub, align: .right,
                 rect: CGRect(x: page.width - m - 220, y: y + 14, width: 220, height: 12))
            y += 30
            line(brand, weight: 2)
            y += 10
        }

        func sectionTitle(_ index: Int, _ title: String) {
            need(30)
            y += 8
            draw("\(index). \(title)", font: .systemFont(ofSize: 12, weight: .bold),
                 color: brand, rect: CGRect(x: m, y: y, width: contentW, height: 15))
            y += 17
            line(hair, weight: 0.6)
            y += 7
        }

        func caption(_ s: String) {
            need(16)
            y += draw(s, font: .systemFont(ofSize: 7.5), color: sub,
                      rect: CGRect(x: m, y: y, width: contentW, height: 24)) + 6
        }

        func emptyNote(_ s: String) {
            need(16)
            draw(s, font: .systemFont(ofSize: 8.5), color: sub,
                 rect: CGRect(x: m, y: y, width: contentW, height: 14))
            y += 18
        }

        private func line(_ c: UIColor, weight: CGFloat) {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: m, y: y))
            p.addLine(to: CGPoint(x: page.width - m, y: y))
            c.setStroke(); p.lineWidth = weight; p.stroke()
        }

        // MARK: 档案

        func profileGrid(_ p: HealthProfile) {
            var items: [(String, String)] = []
            if let a = p.age { items.append((L("Age", "年龄"), L("\(a) y/o", "\(a) 岁"))) }
            if let g = p.gender { items.append((L("Sex", "性别"), g)) }
            if let h = p.heightCm { items.append((L("Height", "身高"), "\(Int(h)) cm")) }
            if let w = p.weightKg { items.append((L("Weight", "体重"), String(format: "%.1f kg", w))) }
            if let r = p.region, !r.isEmpty { items.append((L("Region", "地区"), r)) }
            if let fam = p.familyGout { items.append((L("Family gout", "家族痛风"), fam)) }
            if let hla = p.hlaTested { items.append(("HLA-B*5801", hla)) }
            if !p.conditions.isEmpty { items.append((L("Conditions", "共病"), p.conditions.joined(separator: "、"))) }
            if let d = p.drugAllergies, !d.isEmpty { items.append((L("Drug allergy", "药物过敏"), d)) }
            if let f = p.foodAllergies, !f.isEmpty { items.append((L("Food allergy", "食物过敏"), f)) }

            if items.isEmpty {
                emptyNote(L("Profile not filled in. Ask the patient to complete it in the app for a more useful report.",
                            "未填写健康档案。可请患者在 App 内补全，报告会更有用。"))
                return
            }

            let colW = contentW / 2
            var i = 0
            while i < items.count {
                need(16)
                let left = items[i]
                let right = i + 1 < items.count ? items[i + 1] : nil
                draw(left.0, font: .systemFont(ofSize: 7.5), color: sub,
                     rect: CGRect(x: m, y: y, width: colW * 0.42, height: 12))
                draw(left.1, font: .systemFont(ofSize: 9), color: ink,
                     rect: CGRect(x: m + colW * 0.42, y: y, width: colW * 0.56, height: 12))
                if let r = right {
                    draw(r.0, font: .systemFont(ofSize: 7.5), color: sub,
                         rect: CGRect(x: m + colW, y: y, width: colW * 0.42, height: 12))
                    draw(r.1, font: .systemFont(ofSize: 9), color: ink,
                         rect: CGRect(x: m + colW + colW * 0.42, y: y, width: colW * 0.56, height: 12))
                }
                y += 14
                i += 2
            }
            y += 4
        }

        // MARK: KPI

        func kpiRow(store: Store, flares: [Flare]) {
            need(56)
            let cal = Calendar.current
            let since90 = cal.date(byAdding: .day, value: -90, to: Date()) ?? Date()
            let f90 = flares.filter { $0.startDate >= since90 }
            let worst = f90.map(\.painPeak).max()

            let latest = store.lastReading.map {
                store.meta.unitIsUmol ? String(format: "%.0f", $0.urateUnit) : String(format: "%.1f", $0.valueMgDl)
            } ?? "—"
            let unit = store.meta.unitIsUmol ? "µmol/L" : "mg/dL"

            let cells: [(String, String, UIColor)] = [
                (latest, L("Latest urate (\(unit))", "最近尿酸（\(unit)）"),
                 store.isAtTarget == true ? UIColor(red: 0.22, green: 0.62, blue: 0.39, alpha: 1) : brand),
                ("\(f90.count)", L("Flares, last 90 d", "近 90 天发作"),
                 f90.isEmpty ? UIColor(red: 0.22, green: 0.62, blue: 0.39, alpha: 1) : UIColor(red: 0.82, green: 0.26, blue: 0.24, alpha: 1)),
                (worst.map { "\($0)/10" } ?? "—", L("Worst pain, 90 d", "最痛（90 天）"), ink),
                (store.flareFreeDays.map { "\($0)" } ?? "—", L("Flare-free days", "无痛天数"), ink)
            ]

            let gap: CGFloat = 8
            let w = (contentW - gap * 3) / 4
            var x = m
            for c in cells {
                let r = CGRect(x: x, y: y, width: w, height: 48)
                let bg = UIBezierPath(roundedRect: r, cornerRadius: 6)
                UIColor(red: 0.95, green: 0.97, blue: 0.96, alpha: 1).setFill()
                bg.fill()
                draw(c.0, font: .systemFont(ofSize: 16, weight: .bold), color: c.2,
                     align: .center, rect: CGRect(x: x, y: y + 8, width: w, height: 20))
                draw(c.1, font: .systemFont(ofSize: 6.8), color: sub,
                     align: .center, rect: CGRect(x: x + 3, y: y + 30, width: w - 6, height: 12))
                x += w + gap
            }
            y += 56
        }

        // MARK: 折线图

        func lineChart(values: [Double], dates: [Date], target: Double, yLabel: String, height: CGFloat) {
            guard values.count >= 2, values.count == dates.count else { return }
            need(height + 26)

            let chartH = height
            let plot = CGRect(x: m + 6, y: y + 8, width: contentW - 34, height: chartH)
            let lo = min(values.min() ?? 0, target) * 0.92
            let hi = max(values.max() ?? 1, target) * 1.06
            let span = max(hi - lo, 0.001)

            func py(_ v: Double) -> CGFloat {
                plot.maxY - CGFloat((v - lo) / span) * plot.height
            }
            let t0 = dates.first!.timeIntervalSince1970
            let t1 = dates.last!.timeIntervalSince1970
            let tSpan = max(t1 - t0, 1)
            func px(_ d: Date) -> CGFloat {
                plot.minX + CGFloat((d.timeIntervalSince1970 - t0) / tSpan) * plot.width
            }

            // 网格
            for i in 0...3 {
                let gy = plot.minY + plot.height * CGFloat(i) / 3
                let p = UIBezierPath()
                p.move(to: CGPoint(x: plot.minX, y: gy))
                p.addLine(to: CGPoint(x: plot.maxX, y: gy))
                UIColor(white: 0.94, alpha: 1).setStroke()
                p.lineWidth = 0.5
                p.stroke()
            }

            // 目标线
            let ty = py(target)
            let tp = UIBezierPath()
            tp.move(to: CGPoint(x: plot.minX, y: ty))
            tp.addLine(to: CGPoint(x: plot.maxX, y: ty))
            tp.setLineDash([4, 3], count: 2, phase: 0)
            UIColor(red: 0.22, green: 0.62, blue: 0.39, alpha: 0.85).setStroke()
            tp.lineWidth = 1
            tp.stroke()

            // 折线
            let lp = UIBezierPath()
            for (i, v) in values.enumerated() {
                let pt = CGPoint(x: px(dates[i]), y: py(v))
                if i == 0 { lp.move(to: pt) } else { lp.addLine(to: pt) }
            }
            brand.setStroke()
            lp.lineWidth = 1.6
            lp.stroke()

            // 点
            for (i, v) in values.enumerated() {
                let pt = CGPoint(x: px(dates[i]), y: py(v))
                let dot = UIBezierPath(ovalIn: CGRect(x: pt.x - 2, y: pt.y - 2, width: 4, height: 4))
                (v <= target ? UIColor(red: 0.22, green: 0.62, blue: 0.39, alpha: 1) : brand).setFill()
                dot.fill()
            }

            // Y 轴刻度
            let df = DateFormatter(); df.dateFormat = "M/d"
            for i in 0...3 {
                let v = hi - span * Double(i) / 3
                let gy = plot.minY + plot.height * CGFloat(i) / 3
                draw(String(format: "%.0f", v), font: .systemFont(ofSize: 6.5), color: sub, align: .right,
                     rect: CGRect(x: m - 4, y: gy - 4, width: 14, height: 9))
            }
            // X 轴首尾日期
            draw(df.string(from: dates.first!), font: .systemFont(ofSize: 6.5), color: sub,
                 rect: CGRect(x: plot.minX, y: plot.maxY + 3, width: 40, height: 9))
            draw(df.string(from: dates.last!) + "  " + yLabel, font: .systemFont(ofSize: 6.5), color: sub, align: .right,
                 rect: CGRect(x: plot.maxX - 80, y: plot.maxY + 3, width: 80, height: 9))

            y = plot.maxY + 16
        }

        // MARK: 柱状图

        func barChart(values: [Double], labels: [String], colors: [UIColor],
                      height: CGFloat, goalLine: Double?, unit: String,
                      axisTicks: [String]? = nil) {
            guard !values.isEmpty else { return }
            need(height + 30)

            let plot = CGRect(x: m + 6, y: y + 6, width: contentW - 12, height: height)
            let maxV = max(values.max() ?? 1, goalLine ?? 0) * 1.15
            let barW = max(plot.width / CGFloat(values.count) - 1.6, 1)

            // 基线
            let base = UIBezierPath()
            base.move(to: CGPoint(x: plot.minX, y: plot.maxY))
            base.addLine(to: CGPoint(x: plot.maxX, y: plot.maxY))
            UIColor(white: 0.85, alpha: 1).setStroke()
            base.lineWidth = 0.6
            base.stroke()

            for (i, v) in values.enumerated() {
                let h = max(CGFloat(v / max(1, maxV)) * plot.height, v == 0 ? 1.2 : 2)
                let x = plot.minX + CGFloat(i) * (plot.width / CGFloat(values.count)) + 0.8
                let r = CGRect(x: x, y: plot.maxY - h, width: barW, height: h)
                let p = UIBezierPath(roundedRect: r, cornerRadius: 1.2)
                (i < colors.count ? colors[i] : brand).setFill()
                p.fill()
            }

            // 目标线
            if let g = goalLine, g > 0 {
                let gy = plot.maxY - CGFloat(g / maxV) * plot.height
                let p = UIBezierPath()
                p.move(to: CGPoint(x: plot.minX, y: gy))
                p.addLine(to: CGPoint(x: plot.maxX, y: gy))
                p.setLineDash([3, 2], count: 2, phase: 0)
                UIColor(red: 0.90, green: 0.60, blue: 0.13, alpha: 0.9).setStroke()
                p.lineWidth = 0.8
                p.stroke()
            }

            // 刻度标签
            if let ticks = axisTicks, ticks.count == 4 {
                let step = plot.height / 4
                for (i, t) in ticks.enumerated() {
                    let gy = plot.maxY - step * CGFloat(i) - step * 0.5
                    draw(t, font: .systemFont(ofSize: 6.2), color: sub, align: .right,
                         rect: CGRect(x: m - 18, y: gy - 4, width: 22, height: 9))
                }
            } else if !labels.isEmpty {
                // 稀疏标签：最多 6 个
                let strideN = max(1, labels.count / 6)
                for (i, l) in labels.enumerated() where i % strideN == 0 {
                    let x = plot.minX + CGFloat(i) * (plot.width / CGFloat(labels.count))
                    draw(l, font: .systemFont(ofSize: 6), color: sub,
                         rect: CGRect(x: x - 10, y: plot.maxY + 3, width: 24, height: 9))
                }
            }

            draw(unit, font: .systemFont(ofSize: 6), color: sub, align: .right,
                 rect: CGRect(x: plot.maxX - 60, y: plot.minY - 1, width: 60, height: 9))

            y = plot.maxY + (labels.isEmpty && axisTicks == nil ? 10 : 16)
        }

        // MARK: 诱因排行

        func rankBars(items: [(name: String, count: Int)]) {
            guard !items.isEmpty else { return }
            // 注意：Swift 不支持元组元素的 keyPath（\.count 非法），必须用闭包
            let maxC = Double(items.map { $0.count }.max() ?? 1)
            for it in items {
                need(18)
                draw(it.name, font: .systemFont(ofSize: 8.5), color: ink,
                     rect: CGRect(x: m, y: y + 2, width: 150, height: 12))
                let trackW = contentW - 210
                let startX = m + 156
                let track = UIBezierPath(roundedRect: CGRect(x: startX, y: y + 4, width: trackW, height: 8), cornerRadius: 3)
                UIColor(white: 0.94, alpha: 1).setFill()
                track.fill()
                let w = max(CGFloat(Double(it.count) / maxC) * trackW, 3)
                let fill = UIBezierPath(roundedRect: CGRect(x: startX, y: y + 4, width: w, height: 8), cornerRadius: 3)
                brand.setFill()
                fill.fill()
                draw("\(it.count)", font: .systemFont(ofSize: 8, weight: .semibold), color: sub,
                     rect: CGRect(x: startX + trackW + 6, y: y + 2, width: 30, height: 12))
                y += 16
            }
            y += 4
        }

        // MARK: 表格

        func table(headers: [String], widths: [CGFloat], rows: [[String]]) {
            let rowH: CGFloat = 15
            let headH: CGFloat = 17

            func drawHead() {
                need(headH)
                let r = CGRect(x: m, y: y, width: contentW, height: headH)
                brand.setFill()
                UIBezierPath(rect: r).fill()
                var x = m + 4
                for (i, h) in headers.enumerated() {
                    let w = i < widths.count ? widths[i] : 60
                    draw(h, font: .systemFont(ofSize: 7.5, weight: .semibold), color: .white,
                         rect: CGRect(x: x, y: y + 4, width: w - 6, height: 11))
                    x += w
                }
                y += headH
            }

            drawHead()
            for (idx, row) in rows.enumerated() {
                if y + rowH > bottomLimit {
                    beginPage()
                    drawHead()
                }
                if idx % 2 == 1 {
                    UIColor(white: 0.975, alpha: 1).setFill()
                    UIBezierPath(rect: CGRect(x: m, y: y, width: contentW, height: rowH)).fill()
                }
                var x = m + 4
                for (i, cell) in row.enumerated() {
                    let w = i < widths.count ? widths[i] : 60
                    let isStatus = i == 3 && (cell == L("At target", "达标") || cell == L("Above", "超标"))
                    let color: UIColor = isStatus
                        ? (cell == L("At target", "达标") ? UIColor(red: 0.22, green: 0.62, blue: 0.39, alpha: 1) : UIColor(red: 0.82, green: 0.26, blue: 0.24, alpha: 1))
                        : ink
                    draw(cell, font: .systemFont(ofSize: 7.8), color: color,
                         rect: CGRect(x: x, y: y + 4, width: w - 6, height: 11))
                    x += w
                }
                // 细横线
                let p = UIBezierPath()
                p.move(to: CGPoint(x: m, y: y + rowH - 0.4))
                p.addLine(to: CGPoint(x: page.width - m, y: y + rowH - 0.4))
                hair.setStroke(); p.lineWidth = 0.4; p.stroke()
                y += rowH
            }
            y += 8
        }

        // MARK: 用药

        func medBlock(store: Store) {
            let active = store.medPlans.filter { $0.active }
            if active.isEmpty {
                emptyNote(L("No active medication plan.", "没有在用药物方案。"))
                return
            }
            for p in active {
                need(30)
                draw(p.name, font: .systemFont(ofSize: 9.5, weight: .semibold), color: ink,
                     rect: CGRect(x: m, y: y, width: 180, height: 12))
                draw("\(p.dose) · ×\(p.timesPerDay)\(L("/day", "/日"))", font: .systemFont(ofSize: 8.5), color: sub,
                     rect: CGRect(x: m + 185, y: y, width: 200, height: 12))
                let df = DateFormatter(); df.dateFormat = "yyyy-MM"
                draw(L("since \(df.string(from: p.startDate))", "始于 \(df.string(from: p.startDate))"),
                     font: .systemFont(ofSize: 8), color: sub, align: .right,
                     rect: CGRect(x: page.width - m - 110, y: y, width: 110, height: 12))
                y += 15
            }
            if let rate = store.adherenceRate {
                need(16)
                draw(L("30-day adherence: \(Int(rate * 100))%  (backfilled doses are marked as such)",
                       "近 30 天依从率：\(Int(rate * 100))%（补记的剂量已单独标注）"),
                     font: .systemFont(ofSize: 8), color: sub,
                     rect: CGRect(x: m, y: y, width: contentW, height: 12))
                y += 15
            }
            y += 4
        }

        // MARK: 生活方式

        func lifestyleBlock(store: Store) {
            let recorded = store.waterDays.filter { $0.provenance == .recorded && !$0.cups.isEmpty }
            let estimated = store.waterDays.filter { $0.provenance == .estimated }
            let onGoal = recorded.filter { $0.totalMl >= $0.goalMl }.count
            let redDays = store.foodDays.filter { !$0.noTriggerToday && (!$0.items.isEmpty || !$0.scenes.isEmpty) }.count
            let cleanDays = store.foodDays.filter { $0.noTriggerToday }.count

            let weightLine: String
            if let first = store.weightLogs.min(by: { $0.date < $1.date }),
               let last = store.weightLogs.max(by: { $0.date < $1.date }) {
                let df = DateFormatter(); df.dateFormat = "yyyy-MM"
                weightLine = String(format: "%.1f kg → %.1f kg (%@)", first.kg, last.kg, df.string(from: first.date))
            } else {
                weightLine = L("Not recorded", "未记录")
            }

            let sleepLine: String
            if store.sleepLogs.count >= 4 {
                let recent = store.sleepLogs.suffix(14)
                let avg = Double(recent.map { $0.bucket }.reduce(0, +)) / Double(recent.count)
                let idx = min(Int(avg.rounded()), 3)
                sleepLine = [L("before 23:00", "23点前"), L("23:00–24:00", "23-24点"),
                             L("00:00–01:00", "0-1点"), L("after 01:00", "1点后")][idx]
                    + L(" (14-night average, \(store.sleepLogs.count) nights logged)",
                        "（近 14 晚平均，共 \(store.sleepLogs.count) 晚）")
            } else {
                sleepLine = L("Not recorded", "未记录")
            }

            let rows: [(String, String)] = [
                (L("Hydration", "饮水"), L("\(onGoal) days on goal out of \(recorded.count) measured days · \(estimated.count) days auto-filled",
                                       "实测 \(recorded.count) 天中 \(onGoal) 天达标 · \(estimated.count) 天按均值沿用")),
                (L("Diet", "饮食"), L("\(redDays) days with high-purine food · \(cleanDays) days explicitly clean",
                                     "\(redDays) 天登记了高嘌呤 · \(cleanDays) 天明确未碰")),
                (L("Sleep", "入睡"), sleepLine),
                (L("Weight", "体重"), weightLine)
            ]

            for (k, v) in rows {
                need(16)
                draw(k, font: .systemFont(ofSize: 7.5), color: sub,
                     rect: CGRect(x: m, y: y, width: 74, height: 12))
                let h = draw(v, font: .systemFont(ofSize: 8.5), color: ink,
                             rect: CGRect(x: m + 78, y: y, width: contentW - 78, height: 26))
                y += max(14, h + 3)
            }
            y += 4
        }

        func disclaimer() {
            need(46)
            y += 6
            line(hair, weight: 0.5)
            y += 8
            let text = L("All data is self-recorded by the patient in UricNote — not medical-device measurements. \"Not recorded\" means no entry for that period, not a normal result. \"Auto-filled\" means the app carried the patient's prior-week average forward. Reference: ACR 2020 Guideline · treat-to-target (GoutSMART, Lancet Rheumatology 2022).",
                         "全部数据为患者在 UricNote 中的自记录，非医疗设备测量。「未记录」表示该时段没有录入，不代表指标正常。「沿用」表示 App 按患者前一周均值自动填充。参考：ACR 2020 指南 · treat-to-target（GoutSMART, Lancet Rheumatology 2022）。")
            let h = draw(text, font: .systemFont(ofSize: 6.8), color: sub,
                         rect: CGRect(x: m, y: y, width: contentW, height: 40))
            y += h + 4
        }
    }
}
