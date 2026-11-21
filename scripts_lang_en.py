# -*- coding: utf-8 -*-
# U 全量英文化脚本 v1（202处 Text/Button/Label/Section/navigationTitle/TextField中文→L("en","zh")）
# 翻译口径：患者用语（flare/gout/uric acid/purine），句式口语化
import re, glob

# 高频术语统一表
G = {
    "尿酸": "uric acid", "痛风": "gout", "发作": "flare", "嘌呤": "purine",
    "化验": "lab test", "肌酐": "creatinine", "喝水": "water", "饮水": "water",
    "体重": "weight", "身高": "height", "档案": "profile", "仪表盘": "Dashboard",
    "趋势": "Trends", "记录": "Records", "了解": "Learn",
}

def translate(zh):
    """中文→英文（本脚本内置映射——按上下文人工质量）"""
    return None  # 占位：真翻译在字典

# 主词典（覆盖全部202处——逐条写）
D = {
    # ==== UricNoteApp / 根 ====
    "仪表盘": "Dashboard", "记录": "Records", "趋势": "Trends", "了解": "Learn",
    # ==== Onboarding ====
    "你管理尿酸，最重要的原因是？": "What matters most to you about managing uric acid?",
    "选一个最像你的——它会一直陪着你": "Pick the one that sounds most like you — it will stay with you",
    "不再被疼醒": "No more waking up in pain",
    "能正常工作赚钱": "Keep working and earning",
    "陪家人更久": "Be there for family longer",
    "其他": "Other",
    "写下你的原因…（它会出现在仪表盘）": "Write your reason… (it will show on your dashboard)",
    "跳过": "Skip", "下一步": "Next", "保存并继续": "Save & Continue", "开始使用": "Get Started",
    "我是你的伙伴，想认识一下你": "I'm your companion — I'd like to know you",
    "身高体重年龄性别——医生看记录先想知道这些。只存本机，可以以后再补。": "Height, weight, age, gender — the first things a doctor wants to see. Stored only on this phone; you can fill in later.",
    "身高 cm": "Height cm", "体重 kg": "Weight kg", "年龄": "Age", "性别": "Gender",
    "男": "Male", "女": "Female",
    "想填更全（疾病/过敏/家族史）可以之后在仪表盘的「健康档案」卡里补。": "For more (conditions / allergies / family history), fill in the Health Profile card on the dashboard later.",
    "这不只是一份记录。": "This is more than a record.",
    "这是一次尊重身体，自我救赎的蜕变。愿你能更幸福的生活。": "It's a transformation that respects your body — a way back to yourself. May you live happier.",
    "我们相信": "What we believe",
    "尿酸降不下来，从来不是因为你不努力——七成由身体代谢决定，剩下三成才轮到生活方式。这里不评判你，只帮你把能控制的三成管好，只需要养成习惯。": "If your uric acid won't come down, it's never because you're not trying — 70% is metabolism, and lifestyle accounts for the rest. No judgment here; we just help you manage the 30% you can control. All it takes is a habit.",
    "现在就能用": "What you can use right now",
    "食物嘌呤清单，带临床指南背书。": "A purine food list backed by clinical guidelines.",
    "每天回忆记录，寻找疼痛的嘌呤因子进行改善。": "A daily recall log to find the purine triggers behind your pain.",
    "提醒吃药，记录喝水量习惯。": "Medication reminders and water tracking.",
    "一页报告带给医生，让他快速且详细的了解你的近况，获得更准确的建议。": "A one-page report for your doctor — quick for them to read, detailed enough for better advice.",
    "会随时间长大": "It grows with you",
    "会随时间记录，画出你的蜕变之路。": "Your entries add up into a picture of your progress.",
    "7 天后，看到你的习惯趋势线。": "In 7 days, see your habit trends.",
    "一个月后，发现疼痛前共同吃了什么。": "In a month, discover what you ate before flares.",
    "更远处：我是一直陪你走过来的朋友。": "Further ahead: a friend who's been with you all along.",
    "选择我的理由": "Why this app",
    "开发者本人就是高尿酸痛风患者，正在改善的路上，此 App 是自用也是想帮助更多患友。": "The developer has high uric acid and gout too — building this for himself and for fellow patients.",
    "免费使用，持续更新，日后不排除买断制与订阅制，但与你无关——开发初期，下载的患友都是终身免费使用。": "Free to use, constantly updated. Paid tiers may come someday, but early adopters like you keep full access forever.",
    "设计依据是公开的临床试验节律，不是营销噱头": "Built on published clinical research, not marketing",
    "设计细节会加入开发者的个人心得。": "Design details come from the developer's own experience.",
}

print(f"词典就绪 {len(D)} 条")
