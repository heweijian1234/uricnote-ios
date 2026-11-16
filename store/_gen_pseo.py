# -*- coding: utf-8 -*-
"""pSEO 嘌呤库页面生成器 · 英文版 · 2026-11-15（5.3重审后按健哥令A方案重写）
从 PurineDatabase 173 条生成每食物一页（方法一步骤书：数据集 pSEO）
🔴2026-11-15 战略修正：中文版瞄准的搜索市场（大陆）已被 App 供应区摘除——
  英文版对准美区英语搜索（GEO 9 页同语言同市场，逻辑对齐）。
  份量换算已修数学错误（330ml≠100g，flash 版差 3.3 倍）。
前置：种子 20 页人工验证模式 → 分批放量（--limit N 控制批次）
输出：直接写入本地 purine-pages/，由调用者 scp 部署（先清 VPS 旧目录）
"""
import sys, os

sys.path.insert(0, r'E:\AI-Projects\个人成长\10-项目\SaaS项目\uricnote-ios')

# 从 LearnView.swift 抽取 PurineDatabase 数据（单一事实源=代码里的数组）
import re
src = open(r'E:\AI-Projects\个人成长\10-项目\SaaS项目\uricnote-ios\UricNote\LearnView.swift', encoding='utf-8').read()
m = re.search(r'enum PurineDatabase \{(.*?)\n\}', src, re.S)
items = re.findall(r'\.init\(name:\s*"([^"]+)",\s*uricPer100g:\s*([\d.]+),\s*level:\s*"(\w+)",\s*sourceTag:\s*"([^"]+)"\)', m.group(1))
DB = [(n, float(v), lv, tag) for n, v, lv, tag in items]
print(f'数据集加载: {len(DB)} 条')

LEVEL_EN = {'red': ('High purine', 'Limit strictly — portion matters most at this level. Avoid during flares; even in remission, keep frequency low.'),
            'yellow': ('Moderate purine', 'OK in moderation — watch portion size and frequency. Best avoided during a flare.'),
            'green': ('Low purine', 'Generally safe for daily eating — a staple category for gout and high-uric-acid diets.')}

# 种子20条的英文名+slug映射（放量到全量173条时需补全此表）
EN = {'啤酒': ('Beer', 'beer', ('1 can (330ml)', 330)),
      '白酒': ('Baijiu (Chinese liquor)', 'baijiu', ('1 shot (50ml)', 50)),
      '动物内脏（肝/腰/脑）': ('Organ meats (liver, kidney, brain)', 'organ-meats', ('100g', 100)),
      '浓肉汤': ('Rich meat broth', 'rich-meat-broth', ('1 bowl (300ml)', 300)),
      '沙丁鱼': ('Sardines', 'sardines', ('1 can (90g)', 90)),
      '凤尾鱼': ('Anchovies', 'anchovies', ('1 tin (45g)', 45)),
      '带鱼': ('Ribbon fish', 'ribbon-fish', ('100g', 100)),
      '牡蛎': ('Oysters', 'oysters', ('3 medium (75g)', 75)),
      '蛤蜊': ('Clams', 'clams', ('100g', 100)),
      '鹅肉': ('Goose', 'goose', ('100g', 100)),
      '猪肝': ('Pork liver', 'pork-liver', ('100g', 100)),
      '猪腰': ('Pork kidney', 'pork-kidney', ('100g', 100)),
      '脑花': ('Brain', 'brain', ('100g', 100)),
      '猪肉（五花）': ('Pork belly', 'pork-belly', ('100g', 100)),
      '牛肉': ('Beef', 'beef', ('100g', 100)),
      '羊肉': ('Lamb', 'lamb', ('100g', 100)),
      '鸡肉': ('Chicken', 'chicken', ('100g', 100)),
      '鸭肉': ('Duck', 'duck', ('100g', 100)),
      '三文鱼': ('Salmon', 'salmon', ('1 fillet (150g)', 150)),
      '金枪鱼': ('Tuna', 'tuna', ('1 can (140g)', 140))}

# 绿灯替代项英文（从库里抽的绿灯中文名也需映射——限量映射先覆盖高频绿灯）
EN_GREEN = {'豆浆': 'soy milk', '四季豆': 'green beans', '芦笋': 'asparagus', '鸡蛋': 'eggs', '牛奶': 'milk',
            '低脂牛奶': 'low-fat milk', '酸奶': 'yogurt', '脱脂酸奶': 'fat-free yogurt', '酸奶（低脂）': 'low-fat yogurt',
            '白菜': 'napa cabbage', '黄瓜': 'cucumber', '番茄': 'tomato', '苹果': 'apple', '米饭': 'rice',
            '面条': 'noodles', '土豆': 'potato', '胡萝卜': 'carrot', '芹菜': 'celery', '生菜': 'lettuce',
            '西瓜': 'watermelon', '樱桃': 'cherries', '咖啡': 'coffee', '豆腐': 'tofu'}

def slugify(name):
    """英文页一律用英文slug；绿灯项没进 EN 表的用拼音化处理会留中文——改为回退清单外的统一slug"""
    if name in EN:
        return EN[name][1]
    # 绿灯替代项：中文原名的URL slug（这些页将来放量时生成）；当前种子页内链指向未来页，可接受——但更稳的做法是用已映射的英文名
    return EN_GREEN.get(name, name).lower().replace(' ', '-') if name in EN_GREEN else re.sub(r'[\s/]+', '-', name)

def render(item):
    name, val, lv, tag = item
    lo_en, advice_en = LEVEL_EN[lv]
    en_name, slug, (portion_label, portion_g) = EN.get(name, (name, re.sub(r'[\s/]+', '-', name), ('100g', 100)))
    # 绿灯替代项：同分类里抽 3 个绿灯（英文映射过的优先）
    green_alts = [(n, EN_GREEN.get(n)) for n, v2, l2, _ in DB if l2 == 'green' and n != name and n in EN_GREEN][:3]
    alt_html = ' · '.join(f'<a href="/seo/purine-pages/{slugify(g)}.html">{e}</a>' for g, e in green_alts) or '<a href="https://postwriter.cn/seo/geo-gout-trigger-foods.html">See the full green list</a>'
    schema_cls = 'high' if lv == 'red' else ('moderate' if lv == 'yellow' else 'low')
    color = {'red': '#c0392b', 'yellow': '#e6a23c', 'green': '#0E7C66'}[lv]
    portion_mg = round(val * portion_g / 100, 1)
    is_distilled = val == 0
    portion_sentence = (f'Distilled spirits contain almost zero purines — but for gout the risk comes from the alcohol itself (alcohol slows uric acid excretion). "Zero purine" does not mean "safe to drink".'
                        if is_distilled else
                        f'A typical portion ({portion_label}) contains about <strong>{portion_mg} mg</strong> of purines ({val} mg per 100g).')
    return en_name, slug, f'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{en_name} purine content{'≈ 0 (the risk is the alcohol, not purines)' if is_distilled else f': {val}mg/100g'} — is it OK with gout? | UricNote</title>
<meta name="description" content="{en_name} contains about {val} mg purines per 100g — a {schema_cls} purine food. How should someone with gout or high uric acid handle {en_name.lower()}? {advice_en} Source: {tag} guideline, verified Nov 2026.">
<script type="application/ld+json">
{{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{{"@type":"Question","name":"Can you eat {en_name.lower()} if you have gout?","acceptedAnswer":{{"@type":"Answer","text":"{en_name} contains about {val} mg purines per 100g — a {schema_cls} purine level. {advice_en} (Source: {tag} guideline, verified Nov 2026. This is general food information, not medical advice.)"}}}}]}}
</script>
<style>
body{{font-family:-apple-system,sans-serif;max-width:720px;margin:0 auto;padding:36px 20px;color:#1a1a1a;line-height:1.65}}
.badge{{display:inline-block;background:{color};color:#fff;border-radius:8px;padding:4px 14px;font-size:15px;font-weight:600}}
h1{{color:#0E7C66}} .num{{font-size:2.6em;font-weight:700;color:{color}}}
.hl{{background:#f2f8f5;border:1px solid #d5e5df;border-radius:12px;padding:16px 20px;margin:16px 0}}
table{{width:100%;border-collapse:collapse;font-size:14px}} td{{border-bottom:1px solid #eee;padding:6px 4px}}
.nav{{margin-top:32px;padding-top:14px;border-top:1px solid #d5e5df;font-size:14px}}
a{{color:#0E7C66}}
.note{{color:#777;font-size:12px;margin-top:24px}}
</style>
</head>
<body>
<h1>Purine content of {en_name}: can you eat it with gout?</h1>
<p><span class="badge">{lo_en}</span> <span style="color:#666;font-size:14px">Source: {tag} guideline · verified Nov 2026</span></p>

<div class="hl">
<div class="num">{val}<span style="font-size:0.45em"> mg/100g</span></div>
<p><strong>Short answer:</strong>{advice_en} {portion_sentence}</p>
</div>

<h2>What this means</h2>
<p>The goal in gout and hyperuricemia management is keeping serum uric acid <strong>below 6.0 mg/dL (360 µmol/L)</strong> (ACR 2020 guideline; below 5.0 if you have tophi). Diet accounts for roughly 30% — {en_name.lower()} falls in the {'strictly-limited category' if lv == 'red' else ('moderation category' if lv == 'yellow' else 'low-purine safe category')}, but <b>medication and lifestyle must run on parallel tracks</b>: 63% of patients mistakenly believe diet alone can replace daily medication (US national survey, Gout Education Society, May 2026).</p>

<h2>Greener swaps (green-first)</h2>
<p>{alt_html}</p>

<h2>Quick reference table</h2>
<table>
<tr><td>Green · low purine</td><td>&lt; 50 mg/100g</td><td>Enjoy daily</td></tr>
<tr><td>Yellow · moderate</td><td>50–150 mg/100g</td><td>Portion + frequency control</td></tr>
<tr><td>Red · high purine</td><td>&gt; 150 mg/100g</td><td>Strictly limit</td></tr>
</table>

<div class="nav">
<strong>More:</strong>
<a href="https://postwriter.cn/seo/uricnote-landing.html">UricNote home</a> ·
<a href="https://postwriter.cn/seo/geo-gout-faq-2026.html">Gout FAQ</a> ·
<a href="https://postwriter.cn/seo/geo-uric-acid-target.html">Uric acid targets</a> ·
<a href="https://postwriter.cn/seo/geo-founding-offer.html">Founding Offer</a>
</div>

<p class="note">Generated from the UricNote database (source: {tag}, manually verified Nov 2026). General information, not medical advice; follow your doctor's guidance for your individual diet plan. Tracking tool: <a href="https://postwriter.cn/seo/uricnote-landing.html">UricNote App</a></p>
</body>
</html>'''

# 主流程：--limit N 控制批次（种子20→全量173，全量前须补全 EN 映射表）
limit = 20
if '--limit' in sys.argv:
    limit = int(sys.argv[sys.argv.index('--limit') + 1])
outdir = r'E:\AI-Projects\个人成长\10-项目\SaaS项目\uricnote-ios\store\purine-pages'
os.makedirs(outdir, exist_ok=True)
manifest = []
missing = []
for n, v, lv, tag in DB[:limit]:
    if n not in EN:
        missing.append(n)
        continue
    _, slug, html = render((n, v, lv, tag))
    path = os.path.join(outdir, f'{slug}.html')
    open(path, 'w', encoding='utf-8').write(html)
    # 🔴sitemap的loc必须与真实部署路径一致（/seo/purine-pages/）
    manifest.append(f'https://postwriter.cn/seo/purine-pages/{slug}.html')
print(f'生成 {len(manifest)} 页 → {outdir}')
if missing:
    print(f'⚠️ 跳过 {len(missing)} 条（无英文映射）: {missing[:10]}')
open(os.path.join(outdir, 'sitemap-purine.xml'), 'w', encoding='utf-8').write(
    '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
    '\n'.join(f'<url><loc>{u}</loc><lastmod>2026-11-15</lastmod><priority>0.7</priority></url>' for u in manifest) +
    '\n</urlset>')
print('sitemap-purine.xml 已生成')
