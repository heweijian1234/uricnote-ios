# UricNote 数据迁移链预案 · 2026-11-15（v1 → v1.1 → v2 预演）

> 原则：UserDefaults JSON 编码升级必须向后兼容（旧数据零丢失）；每次模型变更 = 新增字段带默认值（Codable 的 `decodeIfPresent` 模式），永不删除字段。

## v1 → v1.1（双模式/诱因排行/体重已在 v1——此轮无结构变更）
v1.1 的诱因排行是纯派生（从 FoodLog+Flare 现算），无迁移。
风险点：无。

## v1.1 → v1.2（预期：提醒调度落地 UNUserNotificationCenter）
- MedPlan 增加 `reminderIds: [String]?`（通知 ID，可空）
- Codable 兼容：`reminderIds = try container.decodeIfPresent([String].self, forKey: .reminderIds)`
- 风险点：删除计划时要同步清通知——计划内逻辑，不动数据。

## v1.x → v2（血压 Tab/多病合一——数据模型演进）
- 新增 `BPReading`（date/systolic/diastolic/provenance）独立数组 key `ur.bpReadings`
- 旧 key 全部不动 → 新 App 版本首启按 key 各自解析
- AppMeta 加 `installedFeatures: [String]?`（功能标记，供"新功能引导"判断）
- **迁移函数模板**（届时启用）：
```swift
private func migrateIfNeeded() {
    let v = defaults.integer(forKey: "ur.schemaVersion")
    if v < 2 {
        // v2: BPReading 数组默认空、meta.installedFeatures 默认空——零动作，仅记录版本
        defaults.set(2, forKey: "ur.schemaVersion")
    }
}
```

## v2 → 安卓/Web（跨平台预留）
- 导出格式：所有数组 → JSON（字段名=Swift 属性名，日期 ISO8601）；CSV 逐实体导出
- 通用字段命名已就位（无 Swift 特有类型；UUID 字符串化）
- Web 报告生成器直接消费同一 JSON schema

## 铁律（与 SOP 缺失数据铁律联动）
1. 字段只增不删；删除=标记 deprecated 保留兼容
2. 每次 schemaVersion+1 必须带迁移测试（本地造旧 JSON 喂解码）
3. provenance 三态字段永不迁移改写
