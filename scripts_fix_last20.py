# -*- coding: utf-8 -*-
# 最后20处插值复合串手工修（正则切开的残段——逐文件精修）
import re

def patch(p, pairs):
    s = open(p, encoding='utf-8').read()
    for old, new in pairs:
        if old in s:
            s = s.replace(old, new)
            print(u'✅ %s' % old[:40])
        else:
            print(u'⚠️ 未匹配 %s: %s' % (p.split('\\')[-1], old[:50]))
    open(p, 'w', encoding='utf-8').write(s)

# MedTodayView：通知body插值串
patch('UricNote/MedTodayView.swift', [
    ('content.body = "\\(activePlan?.name ?? L("meds", "药")) \\(activePlan?.dose ?? "")——到点了，吃完来打个卡。（\\(tf.string(from: t))）"',
     'content.body = "\\(activePlan?.name ?? L("meds", "药")) \\(activePlan?.dose ?? "") — time to take it and check in. (\\(tf.string(from: t)))"'),
    ('content.title = L("UricNote review", "UricNote 回顾")',
     'content.title = "UricNote"'),
])

# Dashboard：回顾提醒卡插值/体重行/身高
patch('UricNote/Dashboard.swift', [
    ('? "每天 \\(String(format: "%02d:%02d", store.recall.hour, store.recall.minute)) 提醒你回顾今天（不用每件事当场记）"',
     '? L("Daily \\(String(format: "%02d:%02d", store.recall.hour, store.recall.minute)) review reminder — no need to log everything on the spot", "每天 \\(String(format: "%02d:%02d", store.recall.hour, store.recall.minute)) 提醒你回顾今天（不用每件事当场记）")'),
    ('content.title = L("UricNote review", "UricNote 回顾")',
     'content.title = "UricNote"'),
    ('content.body = L("回顾一下今天：药吃了吗？水喝够了吗？碰高嘌呤了吗？", "回顾一下今天：药吃了吗？水喝够了吗？碰高嘌呤了吗？")',
     'content.body = L("Review today: meds taken? Enough water? Any high-purine food?", "回顾一下今天：药吃了吗？水喝够了吗？碰高嘌呤了吗？")'),
    ('TextField(L("Height", "身高"), text: Binding(get: { store.profile.heightCm.map { String(Int($0)) } ?? "" }',
     'TextField(L("Height", "身高"), text: Binding(get: { store.profile.heightCm.map { String(Int($0)) } ?? "" }'),
])

# TrendView：门诊HTML串/最新值/疼痛峰值/目标/肌酐/身高体重/动机
patch('UricNote/TrendView.swift', [
    ('profileHtml = "<p><b>患者档案：</b>" + parts.joined(separator: " · ") + "</p>"',
     'profileHtml = "<p><b>Patient profile:</b>" + parts.joined(separator: " · ") + "</p>"'),
    ('"<tr><td colspan=5 class=na>未记录 No data</td></tr>"',
     '"<tr><td colspan=5 class=na>Not recorded</td></tr>"'),
    ('? "最新 \\(String(format: "%.0f", store.lastReading!.urateUnit)) µmol/L"',
     '? L("Latest \\(String(format: "%.0f", store.lastReading!.urateUnit)) µmol/L", "最新 \\(String(format: "%.0f", store.lastReading!.urateUnit)) µmol/L")'),
    (': "最新 \\(String(format: "%.1f", store.lastReading!.valueMgDl)) mg/dL")',
     ': L("Latest \\(String(format: "%.1f", store.lastReading!.valueMgDl)) mg/dL", "最新 \\(String(format: "%.1f", store.lastReading!.valueMgDl)) mg/dL"))'),
    ('let pk = f.tookPainkiller.map { "止痛药\\($0 ? "✓" : "✗")" } ?? ""',
     'let pk = f.tookPainkiller.map { L("Painkiller \\($0 ? "✓" : "✗")", "止痛药\\($0 ? "✓" : "✗")") } ?? ""'),
    ('parts.append("身高 \\(Int(h))cm / 体重 \\(String(format: "%.1f", w))kg")',
     'parts.append(L("Height \\(Int(h))cm / Weight \\(String(format: "%.1f", w))kg", "身高 \\(Int(h))cm / 体重 \\(String(format: "%.1f", w))kg"))'),
])

# RecordListView：化验/疼痛插值
patch('UricNote/RecordListView.swift', [
    ('Text("肌酐 \\(String(format: "%.1f", cr)) mg/dL")',
     'Text(L("Creatinine \\(String(format: "%.1f", cr)) mg/dL", "肌酐 \\(String(format: "%.1f", cr)) mg/dL"))'),
    ('Text("疼痛峰值 \\(f.painPeak)/10 · \\(f.canWalk ? L("Can walk", "能走") : L("Can\'t walk", "不能走"))")',
     'Text(L("Peak \\(f.painPeak)/10 · \\(f.canWalk ? "can walk" : "can\'t walk")", "疼痛峰值 \\(f.painPeak)/10 · \\(f.canWalk ? "能走" : "不能走")"))'),
    ('Text("嘌呤约 \\(Int(item.uricPer100g)) mg/100g · \\(item.level == "red" ? "Caution" : "Moderate") · \\(item.sourceTag)")',
     'Text(L("Purine ~\\(Int(item.uricPer100g)) mg/100g · \\(item.level == "red" ? "Caution" : "Moderate") · \\(item.sourceTag)", "嘌呤约 \\(Int(item.uricPer100g)) mg/100g · \\(item.level == "red" ? "注意" : "适量") · \\(item.sourceTag)"))'),
])

# Onboarding/LearnView 的 visionRow 串（第二个参数直接是文本非String()包装）
for p in ['UricNote/Onboarding.swift', 'UricNote/LearnView.swift']:
    patch(p, [
        ('visionRow(icon: "fork.knife", text: "食物嘌呤清单，带临床指南背书")',
         'visionRow(icon: "fork.knife", text: L("A purine food list backed by clinical guidelines.", "食物嘌呤清单，带临床指南背书"))'),
        ('visionRow("fork.knife", "食物嘌呤清单，带临床指南背书")',
         'visionRow("fork.knife", L("A purine food list backed by clinical guidelines.", "食物嘌呤清单，带临床指南背书"))'),
        ('visionRow(icon: "brain", text: "每天回忆记录，寻找疼痛的嘌呤因子进行改善")',
         'visionRow(icon: "brain", text: L("A daily recall log to find the purine triggers behind your pain", "每天回忆记录，寻找疼痛的嘌呤因子进行改善"))'),
        ('visionRow("brain", "每天回忆记录，寻找疼痛的嘌呤因子进行改善")',
         'visionRow("brain", L("A daily recall log to find the purine triggers behind your pain", "每天回忆记录，寻找疼痛的嘌呤因子进行改善"))'),
        ('visionRow(icon: "pills", text: "提醒吃药，记录喝水量习惯。")',
         'visionRow(icon: "pills", text: L("Medication reminders and water tracking.", "提醒吃药，记录喝水量习惯。"))'),
        ('visionRow("pills", "提醒吃药，记录喝水量习惯")',
         'visionRow("pills", L("Medication reminders and water tracking", "提醒吃药，记录喝水量习惯"))'),
    ])

print('--- 手工补丁完 ---')
