# -*- coding: utf-8 -*-
# 批量转换的四类残病逐个修（本轮精修）：
# A.数组元素L(...))  → L(...)（多右括）
# B.?? L(...)) } → ?? L(...) }（多右括）
# C.feedbackRow(L(..), L(...))) → 两个参数各一个)收尾=...))恰好但多了外层）
# D.L("..\n..", L("..", "..")) 双层嵌套+换行串
import re, glob

def fix(f, pairs):
    s = open(f, encoding='utf-8').read()
    for old, new in pairs:
        if old in s:
            s = s.replace(old, new)
            print('OK %s: %s' % (f.split('\\')[-1].split('/')[-1], old[:35]))
        else:
            print('MISS %s: %s' % (f.split('\\')[-1].split('/')[-1], old[:35]))
    open(f, 'w', encoding='utf-8').write(s)

# A. Dashboard 435 数组
fix('UricNote/Dashboard.swift', [
    ('Text([L("before 11 PM", "23 点前")), L("11 PM–12 AM", "23 点-24 点"), L("12–1 AM", "0 点-1 点"), L("after 1 AM", "1 点后")][b])',
     'Text([L("before 11 PM", "23 点前"), L("11 PM–12 AM", "23 点-24 点"), L("12–1 AM", "0 点-1 点"), L("after 1 AM", "1 点后")][b])'),
    # B. 618 Picker get闭包内
    ('Picker(L("Gender", "性别"), selection: Binding(get: { store.profile.gender ?? L("Male", "男")) }, set: { store.profile.gender = $0 })) {',
     'Picker(L("Gender", "性别"), selection: Binding(get: { store.profile.gender ?? "男" }, set: { store.profile.gender = $0 })) {'),
])

# C. FeedbackPage 36
fix('UricNote/FeedbackPage.swift', [
    ('feedbackRow(L("Criticism", "批评"), L("Criticism is most valuable — every message gets read", "批评最有价值——每一条都会被认真读")))',
     'feedbackRow(L("Criticism", "批评"), L("Criticism is most valuable — every message gets read", "批评最有价值——每一条都会被认真读"))'),
])

# D. LearnView 118 双层+换行串
p = 'UricNote/LearnView.swift'
s = open(p, encoding='utf-8').read()
old_d = '''Text(L("This app is a logging tool, not medical advice.
Sources: ACR 2020 guideline / G-CAN 2024 / published trials.", L("This app is a logging tool, not medical advice.
Sources: ACR 2020 guideline / G-CAN 2024 / published trials.", "本 App 是记录工具，不提供诊断或治疗建议。\\n数据来源：ACR 2020 指南 / G-CAN 2024 缓解标准 / 公开临床试验。")))'''
new_d = '''Text(L("This app is a logging tool, not medical advice.\\nSources: ACR 2020 guideline / G-CAN 2024 / published trials.", "本 App 是记录工具，不提供诊断或治疗建议。\\n数据来源：ACR 2020 指南 / G-CAN 2024 缓解标准 / 公开临床试验。"))'''
if old_d in s:
    s = s.replace(old_d, new_d)
    print('OK LearnView 换行双层串')
else:
    print('MISS LearnView——打印实况：')
    i = s.find('logging tool, not medical advice')
    print(repr(s[i-60:i+300]))
open(p, 'w', encoding='utf-8').write(s)

# 全库再扫同族：数组/闭包内的 L(...))  多右括模式（") , L(" 与 ")) L(" 与 ")) ,"）
print('--- 全库扫残余多括号模式 ---')
for f in glob.glob('UricNote/*.swift'):
    s = open(f, encoding='utf-8').read()
    orig = s
    # 模式1：] 前数组末元素 L(...))] → L(...)]
    s = re.sub(r'(L\("[^"]*",\s*"[^"]*"\))\)\]', r'\1]', s)
    # 模式2：get闭包 ?? L(...)) } → ?? L(...) }
    s = re.sub(r'\?\? L\("([^"]*)",\s*"([^"]*)"\)\) \}', r'?? L("\1", "\2") }', s)
    # 模式3：feedbackRow/二元参数尾 L(...))) → L(...))
    s = re.sub(r'(feedbackRow\(L\("[^"]*",\s*"[^"]*"\),\s*L\("[^"]*",\s*"[^"]*"\))\)', r'\1)', s)
    if s != orig:
        open(f, 'w', encoding='utf-8').write(s)
        print('修', f)
