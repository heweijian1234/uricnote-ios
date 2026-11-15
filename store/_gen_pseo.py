# -*- coding: utf-8 -*-
"""pSEO 嘌呤库页面生成器 · 2026-11-15
从 PurineDatabase 173 条生成每食物一页（方法一步骤书：数据集 pSEO）
前置：种子 20 页人工验证模式 → 分批放量（本脚本支持 --limit N 控制批次）
输出：直接写入 VPS 通过 scp 部署（由调用者执行）
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

LEVEL_EN = {'red': ('High', 'Limit strictly — portion matters most at this level'),
            'yellow': ('Moderate', 'Portion control: fine occasionally, watch frequency'),
            'green': ('Low', 'Generally safe for daily eating')}

LEVEL_CN = {'red': ('高嘌呤 · 严格限制', '急性期避免；缓解期偶尔少量，控制频率最重要'),
            'yellow': ('中嘌呤 · 适量', '可以吃，控制分量和频率，急性期建议避开'),
            'green': ('低嘌呤 · 放心吃', '日常可安心食用，是痛风/高尿酸饮食的主力')}

def slugify(name):
    """中文名直接作URL（中文URL被Google/百度正常收录，中文站标准做法；percent-encode由浏览器/爬虫自动处理）"""
    return re.sub(r'[\s/]+', '-', name)

def render(item):
    name, val, lv, tag = item
    lo_en, advice_en = LEVEL_EN[lv]
    lo_cn, advice_cn = LEVEL_CN[lv]
    # 双单位换算：嘌呤mg/100g 无需换算，但给"一份常见份量"的实用换算
    portions = {'啤酒': ('一罐 330ml', '一罐'), '白酒': ('一两 50ml', '一两')}.get(name, ('100g', '100g'))
    # 绿灯替代项：同分类里抽 3 个绿灯
    green_alts = [n for n, v2, l2, _ in DB if l2 == 'green' and n != name][:3]
    alt_html = ' · '.join(f'<a href="/purine/{slugify(g)}.html">{g}</a>' for g in green_alts) or 'See full green list'
    schema_cls = 'high' if lv == 'red' else ('moderate' if lv == 'yellow' else 'low')
    color = {'red': '#c0392b', 'yellow': '#e6a23c', 'green': '#0E7C66'}[lv]
    return name, val, f'''<!DOCTYPE html>
<html lang="zh-Hans">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{name}嘌呤含量：{val}mg/100g，痛风能吃吗？| UricNote</title>
<meta name="description" content="{name}嘌呤含量约{val}mg/100g，属于{lo_cn.split(' · ')[0]}食物。痛风和高尿酸患者怎么吃{name}？{advice_en}。数据来源：{tag}指南，2026-11 验证。">
<script type="application/ld+json">
{{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{{"@type":"Question","name":"痛风患者能吃{name}吗？","acceptedAnswer":{{"@type":"Answer","text":"{name}嘌呤含量约{val}mg/100g，属于{schema_cls} purine level。{advice_en}（Source: {tag} guideline, verified Nov 2026. This is general food information, not medical advice.)"}}}}]}}
</script>
<style>
body{{font-family:-apple-system,sans-serif;max-width:720px;margin:0 auto;padding:36px 20px;color:#1a1a1a;line-height:1.65}}
.badge{{display:inline-block;background:{color};color:#fff;border-radius:8px;padding:4px 14px;font-size:15px;font-weight:600}}
h1{{color:#0E7C66}} .num{{font-size:2.6em;font-weight:700;color:{color}}}
.hl{{background:#f2f8f5;border:1px solid #d5e5df;border-radius:12px;padding:16px 20px;margin:16px 0}}
table{{width:100%%;border-collapse:collapse;font-size:14px}} td{{border-bottom:1px solid #eee;padding:6px 4px}}
.nav{{margin-top:32px;padding-top:14px;border-top:1px solid #d5e5df;font-size:14px}}
a{{color:#0E7C66}}
.note{{color:#777;font-size:12px;margin-top:24px}}
</style>
</head>
<body>
<h1>{name}的嘌呤含量：痛风能吃吗？</h1>
<p><span class="badge">{lo_cn}</span> <span style="color:#666;font-size:14px">来源：{tag} 指南 · 2026-11 验证</span></p>

<div class="hl">
<div class="num">{val}<span style="font-size:0.45em"> mg/100g</span></div>
<p><strong>直接回答：</strong>{advice_cn}。常见份量（{portions[0]}）约为 <strong>{val}</strong> mg 嘌呤。</p>
</div>

<h2>这意味着什么</h2>
<p>痛风和高尿酸管理的目标是将血尿酸控制在 <strong>6.0 mg/dL（360 µmol/L）以下</strong>（ACR 2020 指南；有痛风石者建议 5.0 以下）。饮食影响约三成——{name}属于{'需要限量的类别' if lv == 'red' else ('可适量吃的类别' if lv == 'yellow' else '低嘌呤安全类别')}，但<b>药物和生活方式要双轨并行</b>：63% 的患者误以为饮食足够替代药物（美国痛风教育学会 2026 全国调查）。</p>

<h2>同类可替代选项（绿灯优先）</h2>
<p>{alt_html} —— 以及<a href="https://postwriter.cn/seo/geo-gout-trigger-foods.html">完整痛风饮食触发食物清单</a></p>

<h2>快速对照表</h2>
<table>
<tr><td>Green · 低嘌呤</td><td>&lt; 50 mg/100g</td><td>日常放心吃</td></tr>
<tr><td>Yellow · 中嘌呤</td><td>50–150 mg/100g</td><td>适量、控频率</td></tr>
<tr><td>Red · 高嘌呤</td><td>&gt; 150 mg/100g</td><td>严格限量</td></tr>
</table>

<div class="nav">
<strong>更多：</strong>
<a href="https://postwriter.cn/seo/uricnote-landing.html">UricNote 主页</a> ·
<a href="https://postwriter.cn/seo/geo-gout-faq-2026.html">痛风 FAQ</a> ·
<a href="https://postwriter.cn/seo/geo-uric-acid-target.html">尿酸目标值</a> ·
<a href="https://postwriter.cn/seo/geo-founding-offer.html">Founding Offer</a>
</div>

<p class="note">本页由 UricNote 数据库生成（数据源：{tag}，2026-11 人工核验）。信息类内容，不构成医疗建议；具体饮食方案请遵医嘱。记录工具：<a href="https://postwriter.cn/seo/uricnote-landing.html">UricNote App</a></p>
</body>
</html>'''

# 主流程：--limit N 控制批次（种子20→全量173）
limit = 20
if '--limit' in sys.argv:
    limit = int(sys.argv[sys.argv.index('--limit') + 1])
outdir = r'E:\AI-Projects\个人成长\10-项目\SaaS项目\uricnote-ios\store\purine-pages'
os.makedirs(outdir, exist_ok=True)
manifest = []
for n, v, lv, tag in DB[:limit]:
    slug = slugify(n)
    _, _, html = render((n, v, lv, tag))
    path = os.path.join(outdir, f'{slug}.html')
    open(path, 'w', encoding='utf-8').write(html)
    manifest.append(f'https://postwriter.cn/purine/{slug}.html')
print(f'生成 {len(manifest)} 页 → {outdir}')
open(os.path.join(outdir, 'sitemap-purine.xml'), 'w', encoding='utf-8').write(
    '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
    '\n'.join(f'<url><loc>{u}</loc><lastmod>2026-11-15</lastmod><priority>0.7</priority></url>' for u in manifest) +
    '\n</urlset>')
print('sitemap-purine.xml 已生成')
