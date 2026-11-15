# UricNote 审核信息包（六件套就绪核对 · 2026-11-15 预备版）

> GroomerBook 2.1 拒审教训的预防版：提审前六件全齐。4.3 防火墙②的 Notes 内容已并入。
> 状态：①②③⑤已就绪 ④录屏待拍（健哥）⑥隐私标签提审时网页勾选

## ① Notes 全文（提审时贴入 App Review Information → Notes）

```
Thank you for reviewing UricNote v1.0 — a gout-specific record keeper.

1. SCREEN RECORDING
A screen recording captured on a physical iPhone (latest iOS) is available at:
https://postwriter.cn/seo/uricnote-review-demo.mp4
It shows the complete first-run flow: onboarding (motivation pick → habit seed
→ vision page), dashboard (flare-free counter, target delta, review countdown),
3-second flare logging, lab value entry with automatic review scheduling,
purine food library (green-first browsing), and doctor report generation.
The app has NO account creation, NO login, NO user-generated content sharing,
NO paid content within v1.0 (Pro IAP arrives in v1.1) — so account deletion,
content reporting/blocking flows are not applicable.

2. APP PURPOSE AND TARGET AUDIENCE
UricNote is a local record-keeping utility for people living with gout and
high uric acid. It addresses a documented gap: 87% of gout patients discontinue
medication (Mayo Clinic cohort), and tracking apps lose users between flares.
UricNote's review-rhythm engine translates the 2-monthly treat-to-target
cadence validated in the GoutSMART trial (Lancet Rheumatology, 2022) into a
consumer tool. Target audience: gout patients in the US, EU, and Japan.

3. SETUP AND MAIN FEATURES
No account or setup required:
- Dashboard: flare-free counter, distance-to-target, review countdown
- Record tab: 3-second flare logging (9 joints, pain slider, mobility),
  lab value entry with dual units (mg/dL ⇄ µmol/L), medication plans with
  daily reminders, hydration logging with weight-based goals
- Trends: medication adherence rate, explainable trigger ranking (rule-based
  from the user's own flare-food correlations — never a black-box score),
  doctor report generation (Pro, one-time purchase)
- Learn tab: 12 myth-vs-fact cards with sources, purine food library
  (173 items, ACR 2020 sourced, green-first browsing), changelog
- Data safety: three-state provenance (recorded / confirmed backfill /
  not recorded) — reports never fabricate missing data

4. EXTERNAL SERVICES
None. No network access, no analytics, no third-party SDKs. All data is
stored locally on the device. The medication reminder uses local iOS
notifications only (no server).

5. REGIONAL DIFFERENCES
None — all data is local; unit display auto-converts (mg/dL ⇄ µmol/L).

6. REGULATED INDUSTRY / THIRD-PARTY MATERIAL
UricNote is a record-keeping tool. It does NOT diagnose, treat, or
recommend — it logs user-entered values and history only. It does not use
device sensors to measure anything (all values are manually entered from
lab reports). Purine food data is sourced from the ACR 2020 Guideline and
labeled per item. All content is original.
Demo account: Not applicable — no account or login.

DIFFERENTIATION NOTE (per guideline 4.3)
UricNote is purpose-built for gout — not a re-skinned template. Features
unique in the store: dual-track view (medication adherence vs lifestyle vs
pain-free trend), review-rhythm engine with clinical-trial citation,
three-state data provenance, green-first food browsing. The developer
personally lives with high uric acid.
```

## ② 录屏脚本（健哥 iPhone 拍 1.5-2 分钟，TestFlight build 14）
```
1. 冷启动 → Onboarding：选动机（陪家人更久）→ 选种子（水）→ 愿景页快滑 → 开始使用
2. 仪表盘：展示三数字（此时可能有"—"空态——正常，口播说明"从你的第一次记录开始"）
3. 记化验值：输 5.2 → toast「达标了」→ 仪表盘"距目标 0.8✓"+复查倒计时出现
4. 记发作：点九宫格脚趾+滑条8+能走 → 保存 → 安抚 toast
5. 记录 Tab：急性模式开关拨一次（界面变简）再拨回
6. 嘌呤库：搜"beer"红/搜"eggs"绿 → 展示绿灯优先 Tab
7. 趋势页：诱因排行（空态倒计时）→ 改变页（投票行）
8. 医生报告 → Pro 门 toast（口播：one-time unlock, no subscription）
9. 了解页：误区卡滑两张 → 结束
（全程 ≤2 分钟；切横竖屏避免；iOS 自带录屏 1080p+）
```

## ③ 录屏部署流程（拍完发阿零即可）
```
阿零网关 media 拉取 → H.264 转码 <10MB → scp -P 6181 root@192.220.45.139:/opt/postwriter/seo_pages/uricnote-review-demo.mp4
→ curl 验 200 → Notes 里的链接已预填（无需改）
```

## ④ 隐私标签（提审网页勾选指南——一次性说清）
- Data Collection: **NONE**（零勾选——纯本地无采集）
- Contact Info / Health & Fitness / Identifiers / Usage Data：全部 No
- Track（跨 App 追踪）：No

## ⑤ 分级与类别（已定）
- 年龄分级：4+（无任何限制内容；医疗免责句在描述和 App 内）
- 主类别：Medical？**Health & Fitness**（H 先例——Medical 类审核更严，记录工具归 Fitness 是既定打法）
- 辅类别：Lifestyle

## ⑥ 版权与作者
- Copyright: WEI JIAN HE
- 版权行（App 内关于页可加）：© 2026 WEI JIAN HE
