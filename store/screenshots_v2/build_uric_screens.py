# -*- coding: utf-8 -*-
"""UricNote 上架截图 · 真实 UI HTML 重建 · 2026-11-23
按 SwiftUI 源码 1:1 重建 5 屏在用界面（1320×2868 = 6.9" iPhone 16 Pro Max），
顶部 caption 条（功能名+一句话）+ 下方纯 UI——S12 新规合规形态（NotaryTrack 2.3.3 拒审教训）。
英文版（上架主语言 en-US）。
"""
import os

W, H = 1320, 2868
CAP_H = 380
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)))

# U 的品牌色板（SwiftUI Theme：brand teal-green 系）
BG = "#F7F5F0"        # 纸感米白（v2视觉）
CARD = "#FFFFFF"
BRAND = "#0E7C66"
BRAND_DEEP = "#0a5c4d"
TEXT = "#1c2321"
SUB = "#5b6663"
SEP = "#e4ded2"
GREEN = "#34C759"
WARN = "#FF9500"
RED = "#FF3B30"
BLUE = "#007AFF"

FONT = "font-family:-apple-system,'SF Pro Text','Segoe UI',Georgia,sans-serif"

def caption(kicker, line):
    return f'''
<div style="height:{CAP_H}px;display:flex;flex-direction:column;justify-content:center;align-items:center;
     background:linear-gradient(180deg,{BRAND_DEEP} 0%,{BRAND} 100%);{FONT}">
  <div style="color:#A8E6D5;font-size:30px;font-weight:600;letter-spacing:2px;text-transform:uppercase">{kicker}</div>
  <div style="color:#fff;font-size:52px;font-weight:700;text-align:center;padding:0 60px;line-height:1.25">{line}</div>
</div>'''

def phone(body, status_time="9:41"):
    return f'''<!DOCTYPE html><html><head><meta charset=utf-8><style>
*{{margin:0;padding:0;box-sizing:border-box}}
body{{width:{W}px;height:{H}px;{FONT};background:{BG};overflow:hidden}}
.status{{height:66px;display:flex;justify-content:space-between;align-items:center;padding:0 44px;
        font-size:30px;font-weight:600;color:{TEXT};background:{BG}}}
.nav{{height:100px;display:flex;align-items:center;justify-content:center;font-size:40px;font-weight:700;color:{TEXT};background:{BG}}}
</style></head><body>
<div class="status"><span>{status_time}</span><span>●●● ⌾ 🔋</span></div>
<div class="nav">UricNote</div>
{body}
</body></html>'''

# ════════ 屏1：Dashboard（三数字+今日待办+动机铭牌）════════
s1 = phone(caption("Track Everything", "Your uric acid, flares &amp; habits — one dashboard") + f'''
<div style="padding:30px 36px">
  <div style="background:{BRAND}14;border-radius:20px;padding:26px 30px;margin-bottom:26px;{FONT}">
    <span style="font-size:30px;color:{BRAND}">❝</span>
    <span style="font-size:32px;color:{SUB};font-weight:600">Your reason: No more waking up in pain</span>
  </div>
  <div style="display:flex;gap:18px;margin-bottom:26px">
    <div style="flex:1;background:{CARD};border:1px solid {SEP};border-radius:20px;padding:28px 16px;text-align:center">
      <div style="font-size:64px;font-weight:800;color:{BRAND}">23</div>
      <div style="font-size:26px;color:{SUB}">Pain-free days</div>
    </div>
    <div style="flex:1;background:{CARD};border:1px solid {SEP};border-radius:20px;padding:28px 16px;text-align:center">
      <div style="font-size:64px;font-weight:800;color:{TEXT}">420</div>
      <div style="font-size:26px;color:{SUB}">Last uric acid</div>
      <div style="font-size:22px;color:{SUB}">µmol/L</div>
    </div>
    <div style="flex:1;background:{CARD};border:1px solid {SEP};border-radius:20px;padding:28px 16px;text-align:center">
      <div style="font-size:64px;font-weight:800;color:{WARN}">14d</div>
      <div style="font-size:26px;color:{SUB}">Recheck in</div>
    </div>
  </div>
  <div style="background:{CARD};border:1px solid {SEP};border-radius:20px;padding:30px;margin-bottom:20px">
    <div style="display:flex;align-items:center;gap:18px;padding:14px 0;border-bottom:1px solid {SEP}">
      <span style="font-size:38px">🔔</span>
      <span style="font-size:32px;font-weight:600;color:{TEXT};flex:1">Evening review reminder</span>
      <span style="font-size:30px;color:{BRAND}">20:30</span>
    </div>
    <div style="display:flex;align-items:center;gap:18px;padding:14px 0;border-bottom:1px solid {SEP}">
      <span style="font-size:38px">🌙</span>
      <span style="font-size:32px;font-weight:600;color:{TEXT};flex:1">What time did you sleep?</span>
    </div>
    <div style="display:flex;align-items:center;gap:18px;padding:14px 0">
      <span style="font-size:38px">💊</span>
      <span style="font-size:32px;font-weight:600;color:{TEXT};flex:1">Log morning dose</span>
      <span style="font-size:30px;color:{BRAND};border:2px solid {BRAND};border-radius:14px;padding:6px 18px">Tap</span>
    </div>
  </div>
  <div style="background:{CARD};border:1px solid {SEP};border-radius:20px;padding:26px 30px">
    <div style="font-size:28px;color:{SUB};margin-bottom:10px">💧 Water today</div>
    <div style="height:26px;background:{SEP};border-radius:13px;overflow:hidden">
      <div style="width:72%;height:100%;background:#4A90D9;border-radius:13px"></div>
    </div>
    <div style="font-size:30px;font-weight:700;color:{TEXT};margin-top:12px">1,440 ml <span style="color:{SUB};font-weight:400">/ 2,000 ml goal</span></div>
  </div>
</div>''')

# ════════ 屏2：趋势（化验折线+达标线）════════
s2 = phone(caption("See Your Trend", "Lab values, targets &amp; what changed") + f'''
<div style="padding:30px 36px">
  <div style="background:{CARD};border:1px solid {SEP};border-radius:20px;padding:30px;margin-bottom:24px">
    <div style="font-size:32px;font-weight:700;color:{TEXT};margin-bottom:24px">Uric acid trend</div>
    <svg width="100%" height="520" viewBox="0 0 1100 520">
      <line x1="0" y1="160" x2="1100" y2="160" stroke="{BRAND}" stroke-width="4" stroke-dasharray="14,10"/>
      <text x="1000" y="140" font-size="26" fill="{BRAND}" font-weight="600">Target &lt;360</text>
      <polyline points="60,380 220,340 380,300 540,265 700,240 860,180 1020,155"
                fill="none" stroke="{RED}" stroke-width="6" stroke-linecap="round"/>
      <circle cx="60" cy="380" r="12" fill="{RED}"/><circle cx="220" cy="340" r="12" fill="{RED}"/>
      <circle cx="380" cy="300" r="12" fill="{RED}"/><circle cx="540" cy="265" r="12" fill="{RED}"/>
      <circle cx="700" cy="240" r="12" fill="{WARN}"/><circle cx="860" cy="180" r="12" fill="{GREEN}"/>
      <circle cx="1020" cy="155" r="14" fill="{GREEN}" stroke="#fff" stroke-width="4"/>
      <text x="40" y="440" font-size="24" fill="{SUB}">Aug</text><text x="320" y="440" font-size="24" fill="{SUB}">Sep</text>
      <text x="600" y="440" font-size="24" fill="{SUB}">Oct</text><text x="880" y="440" font-size="24" fill="{SUB}">Nov</text>
      <text x="940" y="110" font-size="28" fill="{GREEN}" font-weight="700">5.8 ✓</text>
    </svg>
  </div>
  <div style="display:flex;gap:18px">
    <div style="flex:1;background:{CARD};border:1px solid {SEP};border-radius:20px;padding:24px;text-align:center">
      <div style="font-size:26px;color:{SUB}">Adherence 30d</div>
      <div style="font-size:56px;font-weight:800;color:{BRAND}">92%</div>
    </div>
    <div style="flex:1;background:{CARD};border:1px solid {SEP};border-radius:20px;padding:24px;text-align:center">
      <div style="font-size:26px;color:{SUB}">Weight</div>
      <div style="font-size:56px;font-weight:800;color:{TEXT}">78.4</div>
      <div style="font-size:24px;color:{GREEN}">−4.2 kg since start</div>
    </div>
  </div>
  <div style="background:{CARD};border:1px solid {SEP};border-radius:20px;padding:28px 30px;margin-top:24px">
    <div style="font-size:30px;font-weight:700;color:{TEXT};margin-bottom:14px">🔍 Trigger ranking</div>
    <div style="font-size:28px;color:{TEXT};padding:8px 0">1. <b>Beer</b> <span style="color:{SUB}">— before 2 of 3 flares</span></div>
    <div style="font-size:28px;color:{TEXT};padding:8px 0">2. <b>Hot pot broth</b> <span style="color:{SUB}">— before 2 flares</span></div>
    <div style="font-size:28px;color:{TEXT};padding:8px 0">3. <b>Late sleep</b> <span style="color:{SUB}">— correlates</span></div>
  </div>
</div>''')

# ════════ 屏3：嘌呤食物库（三列+分类chip+实拍感）════════
s3 = phone(caption("Purine Food Library", "308 foods · clinical guidelines · safe / moderate / caution") + f'''
<div style="padding:26px 36px">
  <div style="display:flex;justify-content:center;gap:12px;margin-bottom:22px">
    <span style="background:{BRAND};color:#fff;font-size:28px;font-weight:700;padding:12px 34px;border-radius:24px">✓ Safe</span>
    <span style="background:{CARD};border:1.5px solid {SEP};color:{TEXT};font-size:28px;font-weight:600;padding:12px 34px;border-radius:24px">Moderate</span>
    <span style="background:{CARD};border:1.5px solid {SEP};color:{TEXT};font-size:28px;font-weight:600;padding:12px 34px;border-radius:24px">Caution</span>
  </div>
  <div style="display:flex;flex-wrap:wrap;gap:10px;margin-bottom:22px">
    <span style="background:{CARD};border:1.5px solid {BRAND};color:{BRAND};font-size:24px;font-weight:600;padding:8px 22px;border-radius:20px">All</span>
    <span style="background:{SEP}60;color:{TEXT};font-size:24px;padding:8px 22px;border-radius:20px">Vegetables</span>
    <span style="background:{SEP}60;color:{TEXT};font-size:24px;padding:8px 22px;border-radius:20px">Fruits</span>
    <span style="background:{SEP}60;color:{TEXT};font-size:24px;padding:8px 22px;border-radius:20px">Seafood</span>
    <span style="background:{SEP}60;color:{TEXT};font-size:24px;padding:8px 22px;border-radius:20px">Meats</span>
    <span style="background:{SEP}60;color:{TEXT};font-size:24px;padding:8px 22px;border-radius:20px">Alcohol</span>
  </div>
  <div style="background:{CARD};border:1px solid {SEP};border-radius:20px;overflow:hidden">
    <div style="display:flex;align-items:center;padding:24px 28px;border-bottom:1px solid {SEP}">
      <div style="width:86px;height:60px;background:linear-gradient(135deg,#7FB069,#5A8F3C);border-radius:12px;flex-shrink:0"></div>
      <div style="flex:1;margin-left:22px"><div style="font-size:32px;font-weight:700;color:{TEXT}">Broccoli</div>
        <div style="font-size:24px;color:{SUB}">Purine ~21 mg/100g · USDA</div></div>
      <span style="font-size:24px;font-weight:700;color:{GREEN};background:{GREEN}18;padding:8px 20px;border-radius:14px">Safe</span>
    </div>
    <div style="display:flex;align-items:center;padding:24px 28px;border-bottom:1px solid {SEP}">
      <div style="width:86px;height:60px;background:linear-gradient(135deg,#E8A87C,#C97B4A);border-radius:12px;flex-shrink:0"></div>
      <div style="flex:1;margin-left:22px"><div style="font-size:32px;font-weight:700;color:{TEXT}">Salmon</div>
        <div style="font-size:24px;color:{SUB}">Purine ~110 mg/100g · Japanese purine table</div></div>
      <span style="font-size:24px;font-weight:700;color:{WARN};background:{WARN}18;padding:8px 20px;border-radius:14px">Moderate</span>
    </div>
    <div style="display:flex;align-items:center;padding:24px 28px;border-bottom:1px solid {SEP}">
      <div style="width:86px;height:60px;background:linear-gradient(135deg,#D9534F,#A93226);border-radius:12px;flex-shrink:0"></div>
      <div style="flex:1;margin-left:22px"><div style="font-size:32px;font-weight:700;color:{TEXT}">Rich meat broth</div>
        <div style="font-size:24px;color:{SUB}">Purine ~400 mg/100g · ACR 2020</div></div>
      <span style="font-size:24px;font-weight:700;color:{RED};background:{RED}18;padding:8px 20px;border-radius:14px">Caution</span>
    </div>
    <div style="display:flex;align-items:center;padding:24px 28px">
      <div style="width:86px;height:60px;background:linear-gradient(135deg,#8E44AD,#6C3483);border-radius:12px;flex-shrink:0"></div>
      <div style="flex:1;margin-left:22px"><div style="font-size:32px;font-weight:700;color:{TEXT}">Beer</div>
        <div style="font-size:24px;color:{SUB}">Purines + alcohol double hit · strongest trigger</div></div>
      <span style="font-size:24px;font-weight:700;color:{RED};background:{RED}18;padding:8px 20px;border-radius:14px">Caution</span>
    </div>
  </div>
</div>''')

# ════════ 屏4：3秒记发作 ════════
s4 = phone(caption("3-Second Flare Log", "Even at 2 AM, one hand is enough") + f'''
<div style="padding:30px 36px">
  <div style="background:{CARD};border:1px solid {SEP};border-radius:20px;padding:30px;margin-bottom:24px">
    <div style="font-size:32px;font-weight:700;color:{TEXT};margin-bottom:24px">Where does it hurt?</div>
    <div style="display:flex;flex-wrap:wrap;gap:16px">
      <span style="background:{RED}22;color:{RED};font-size:30px;font-weight:700;padding:18px 36px;border-radius:16px;border:2px solid {RED}">Toes ✓</span>
      <span style="background:{BG};color:{TEXT};font-size:30px;padding:18px 36px;border-radius:16px;border:1.5px solid {SEP}">Ankle</span>
      <span style="background:{BG};color:{TEXT};font-size:30px;padding:18px 36px;border-radius:16px;border:1.5px solid {SEP}">Knee</span>
      <span style="background:{BG};color:{TEXT};font-size:30px;padding:18px 36px;border-radius:16px;border:1.5px solid {SEP}">Fingers</span>
    </div>
  </div>
  <div style="background:{CARD};border:1px solid {SEP};border-radius:20px;padding:34px 30px;margin-bottom:24px">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:18px">
      <span style="font-size:32px;font-weight:700;color:{TEXT}">Pain level</span>
      <span style="font-size:40px;font-weight:800;color:{RED}">8/10</span>
    </div>
    <div style="height:30px;background:{SEP};border-radius:15px;position:relative">
      <div style="width:80%;height:100%;background:linear-gradient(90deg,{GREEN},{WARN},{RED});border-radius:15px"></div>
      <div style="width:44px;height:44px;background:#fff;border:4px solid {RED};border-radius:50%;position:absolute;top:-8px;left:calc(80% - 22px)"></div>
    </div>
    <div style="display:flex;justify-content:space-between;margin-top:14px">
      <span style="font-size:24px;color:{SUB}">1 barely</span><span style="font-size:24px;color:{SUB}">7 can't walk</span><span style="font-size:24px;color:{SUB}">10 ER</span>
    </div>
  </div>
  <div style="background:{CARD};border:1px solid {SEP};border-radius:20px;padding:30px">
    <div style="font-size:32px;font-weight:700;color:{TEXT};margin-bottom:20px">Trigger note (optional)</div>
    <div style="background:{BG};border:1.5px solid {SEP};border-radius:14px;padding:24px;font-size:30px;color:{TEXT}">Had 2 beers + BBQ last night…</div>
  </div>
</div>''')

# ════════ 屏5：门诊报告（导出）════════
s5 = phone(caption("One-Page Clinic Report", "Your doctor gets the full picture in 15 minutes") + f'''
<div style="padding:26px 36px">
  <div style="background:#fff;border:1px solid {SEP};border-radius:18px;padding:30px;box-shadow:0 4px 18px rgba(0,0,0,0.08);margin-bottom:24px">
    <div style="display:flex;justify-content:space-between;align-items:flex-end;border-bottom:3px solid {BRAND};padding-bottom:14px;margin-bottom:18px">
      <div><div style="font-size:34px;font-weight:800;color:{BRAND}">UricNote Clinic Report</div>
        <div style="font-size:22px;color:{SUB}">Patient self-recorded log</div></div>
      <div style="font-size:22px;color:{SUB};text-align:right">2026-11-23<br>UricNote App</div>
    </div>
    <div style="display:flex;gap:12px;margin-bottom:18px">
      <div style="flex:1;background:{BRAND}12;border-radius:12px;padding:14px;text-align:center">
        <div style="font-size:34px;font-weight:800;color:{BRAND}">23</div><div style="font-size:20px;color:{SUB}">Flare-free</div></div>
      <div style="flex:1;background:{BRAND}12;border-radius:12px;padding:14px;text-align:center">
        <div style="font-size:34px;font-weight:800;color:{BRAND}">92%</div><div style="font-size:20px;color:{SUB}">Adherence</div></div>
      <div style="flex:1;background:{BRAND}12;border-radius:12px;padding:14px;text-align:center">
        <div style="font-size:34px;font-weight:800;color:{BRAND}">5.8</div><div style="font-size:20px;color:{SUB}">mg/dL</div></div>
    </div>
    <div style="font-size:26px;font-weight:700;color:{BRAND};border-bottom:2px solid {BRAND};padding-bottom:8px;margin-bottom:12px">1. Uric Acid Labs</div>
    <table style="width:100%;font-size:24px;color:{TEXT};border-collapse:collapse">
      <tr style="background:{BRAND};color:#fff"><td style="padding:10px 14px">Date</td><td>Urate</td><td>Cr</td><td>Status</td></tr>
      <tr><td style="padding:10px 14px;border-bottom:1px solid {SEP}">Nov 18</td><td style="border-bottom:1px solid {SEP}">420 µmol/L</td><td style="border-bottom:1px solid {SEP}">1.0</td><td style="border-bottom:1px solid {SEP};color:{RED}">Above</td></tr>
      <tr><td style="padding:10px 14px">Nov 23</td><td>345 µmol/L</td><td>1.0</td><td style="color:{GREEN};font-weight:700">At target ✓</td></tr>
    </table>
    <div style="font-size:26px;font-weight:700;color:{BRAND};border-bottom:2px solid {BRAND};padding-bottom:8px;margin:18px 0 12px">4. Lifestyle</div>
    <div style="font-size:24px;color:{TEXT};line-height:1.7">💧 Water: on-goal 21d · auto 5d<br>🍽 Diet: high-purine 4d · clean 17d<br>😴 Sleep: before 11 PM (avg)</div>
  </div>
  <div style="display:flex;gap:14px;justify-content:center">
    <span style="background:{CARD};border:1.5px solid {SEP};font-size:26px;padding:16px 30px;border-radius:16px;color:{TEXT}">📄 PDF</span>
    <span style="background:{CARD};border:1.5px solid {SEP};font-size:26px;padding:16px 30px;border-radius:16px;color:{TEXT}">🌐 HTML</span>
    <span style="background:{CARD};border:1.5px solid {SEP};font-size:26px;padding:16px 30px;border-radius:16px;color:{TEXT}">📊 CSV</span>
    <span style="background:{BRAND};font-size:26px;padding:16px 30px;border-radius:16px;color:#fff;font-weight:700">Export</span>
  </div>
</div>''')

for i, (name, html) in enumerate([("01-dashboard", s1), ("02-trend", s2), ("03-food-library", s3), ("04-flare-log", s4), ("05-clinic-report", s5)], 1):
    with open(os.path.join(OUT, f"{name}.html"), "w", encoding="utf-8") as f:
        f.write(html)
    print(f"✓ {name}.html")
print("--- 5屏 HTML 生成完，下一步 Playwright 截图 ---")
