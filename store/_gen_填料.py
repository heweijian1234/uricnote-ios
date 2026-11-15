# -*- coding: utf-8 -*-
"""生成 UricNote 版 asc_填料.py：从公证母版改造（APP_ID/文案/隐私URL/截图路径）"""
import re

src = open(r'E:\AI-Projects\个人成长\10-项目\SaaS项目\notarytrack-ios\store\asc_填料.py', encoding='utf-8').read()

t = src
t = t.replace('"""NotaryTrack ASC 上架填料（照 countdown 母版；前置：build 47 VALID 已在 ASC）',
              '"""UricNote ASC 上架填料（照 notarytrack 母版改造；前置：build VALID 已在 ASC + ASC 档案已建）')
t = t.replace('措辞纪律：track/log/record only，禁 diagnose/notarize/compliant journal（州法规雷区）',
              '措辞纪律：track/log/record only，禁 diagnose/treat（合规线）+ 4.3 防火墙差异化文案已入')
t = t.replace('APP_ID = "6832398956"   # NotaryTrack', 'APP_ID = "6834462104"   # UricNote')
t = t.replace('notarytrack-ios', 'uricnote-ios')
t = t.replace('PRIVACY_URL = "https://postwriter.cn/seo/notarytrack-privacy.html"',
              'PRIVACY_URL = "https://postwriter.cn/seo/uricnote-privacy.html"')
t = t.replace('APP_NAME = "NotaryTrack"', 'APP_NAME = "UricNote"')

# EN_DESC 替换
en_new = '''EN_DESC = """The record-keeper for people living with gout and high uric acid.

Built on a clinically-tested treat-to-target rhythm. No ads. No subscription.

WHY URICNOTE
7 in 10 patients believe diet alone is enough — but urate control needs both medication AND lifestyle. UricNote shows you both tracks side by side, so your data — not guesswork — guides your habits.

WHAT MAKES IT DIFFERENT
• Flare-free day counter with the Well Controlled badge (aligned with clinical remission criteria)
• Review-day rhythm engine — labs auto-schedule your next check (the 2-month rhythm validated in clinical trials)
• Trigger ranking from YOUR data — what did your last 3 flares have in common? (rule-based, explainable — never a black-box score)
• Dual-track view: medication adherence vs hydration vs pain-free trend
• Purine library with traffic lights, sourced from the ACR 2020 Guideline
• Green-first browsing: see what you CAN eat before what to avoid
• Missed days? Confirm-and-restore — no guilt, no ruined streaks
• Habit seeds: start with ONE tiny action, celebrate instantly

DOCTOR REPORT (one-time unlock)
A single page your rheumatologist can read in 15 minutes: urate trend, flare history, adherence rate, current meds. Missing data is clearly marked "not recorded" — never fabricated.

PRIVACY
All data stays on your device. No account. No tracking.

Founding price for early users — one-time unlock, no subscription. The developer lives with high uric acid too.

This app is a record-keeping tool. It does not diagnose or treat.
Data sources: ACR 2020 Guideline, G-CAN 2024 remission criteria, published clinical trials."""'''
m = re.search(r'EN_DESC = """.*?"""', t, re.S)
assert m, 'EN_DESC block not found'
t = t[:m.start()] + en_new + t[m.end():]

# LOCALES 替换（读七语文案母版数据，写成代码）
m2 = re.search(r'LOCALES = \{.*?\n\}', t, re.S)
assert m2, 'LOCALES block not found'
locales_new = r'''LOCALES = {
    "en-US": {"subtitle": "Track urate, flares & purines",
              "keywords": "gout,uric acid,purine,flare,urate,tracker,diet,log,attack,crystal,remission",
              "description": EN_DESC},
    "ja": {"subtitle": "尿酸値・発作・プリン体を記録、目標6.0へ",
           "keywords": "痛風,尿酸,プリン体,記録,発作,食事,通風,ヘルスケア,目標値",
           "description": "痛風・高尿酸血症の方のための記録アプリ。臨床試験で検証された「2ヶ月ごとのチェック」リズムで、尿酸値を目標に近づけましょう。広告なし。サブスクなし。買い切り。\n\nなぜ尿酸ノートなのか\n日本人男性の約30%が高尿酸血症と言われています。でも「発作がないから記録しない」——これが痛風管理の一番の落とし穴です。尿酸ノートは、検査のたびに次の通院日を自動で設定する「リズムエンジン」で、発作のない期間も記録を続けられます。\n\n主な機能\n• 無発作日数カウンター＋「制御下」バッジ（G-CAN 2024の寛解基準に準拠）\n• 検査値を記録すると次の検査日を自動スケジュール\n• あなた自身のデータから誘因ランキング——直近3回の発作に共通して食べたものは？（ルールベースで説明可能）\n• 尿酸値の自動単位切替：mg/dL ⇄ µmol/L\n• プリン体食品ライブラリ：信号機方式、ACR 2020ガイドライン準拠\n• 「食べられるもの」を先に表示——制限より、まず選択肢を\n• 記録しなかった日も、確認するだけ\n• 習慣の種：小さな一歩から\n\n主治医への報告書（買い切りで解放）\n診察の15分で読める1枚：尿酸値の推移、発作履歴、服薬アドヒアランス、現在の処方薬。記録のない日は「未記録」と明示——決して捏造しません。\n\nプライバシー\nデータは端末内のみ。アカウント登録不要。追跡なし。\n\n先着100名様：9.99ドルの買い切り特価。あなたのご意見が開発の道しるべ。開発者自身も尿酸値が高めです——すべてのフィードバックを真剣に読みます。\n\n本アプリは記録ツールです。診断や治療は行いません。出典：ACR 2020ガイドライン、G-CAN 2024寛解基準、公開臨床試験。"},
    "de-DE": {"subtitle": "Harnsäure, Schübe & Purine",
           "keywords": "gicht,harnsäure,purine,schub,ernährung,tracker,diät",
           "description": "Der Begleiter für Menschen mit Gicht und Harnsäure. Basierend auf einem klinisch erprobten Treat-to-Target-Rhythmus. Keine Werbung. Kein Abo.\n\nWARUM URICNOTE\n63 % der Patienten glauben, Ernährung allein reiche aus — aber die Kontrolle braucht BEIDES: Medikamente UND Lebensstil. UricNote zeigt beide Spuren nebeneinander.\n\nWAS ANDERS IST\n• Schubfreie-Tage-Zähler mit Abzeichen (G-CAN 2024)\n• Rhythmus-Engine: automatische nächste Kontrolle (GoutSMART, 2022)\n• Trigger-Ranking aus IHREN Daten — regelbasiert, erklärbar\n• Purin-Datenbank mit Ampelsystem (ACR 2020)\n• Grün-erst-Prinzip: zuerst sehen, was Sie essen dürfen\n• Ausgelassene Tage? Bestätigen und weiter\n• Gewohnheits-Samen: EINE kleine Aktion\n\nÄRZTEBERICHT (einmalige Freischaltung)\nEine Seite für 15 Minuten: Verlauf, Schubhistorie, Therapietreue. Fehlende Tage klar markiert — nie erfunden.\n\nDATENSCHUTZ\nAlle Daten auf dem Gerät. Kein Konto. Kein Tracking.\n\nGründerpreis für die ersten 100. Der Entwickler lebt selbst damit.\n\nErfassungswerkzeug — keine Diagnose, keine Behandlung. Quellen: ACR 2020, G-CAN 2024."},
    "fr-FR": {"subtitle": "Suivez urate, crises & purines",
           "keywords": "goutte,acide urique,purine,crise,régime,suivi,urate",
           "description": "L'app de suivi pour les personnes vivant avec la goutte. Basée sur un rythme de suivi tous les 2 mois — validé par un essai clinique. Sans publicité. Sans abonnement.\n\nPOURQUOI URICNOTE\n63 % des patients pensent que l'alimentation suffit — le contrôle demande LES DEUX : traitement ET mode de vie. UricNote affiche les deux voies côte à côte.\n\nCE QUI CHANGE\n• Compteur de jours sans crise + badge « Sous contrôle » (G-CAN 2024)\n• Moteur de rythme : prochain contrôle automatique (essai GoutSMART, 2022)\n• Classement des déclencheurs depuis VOS données — règles explicables\n• Bibliothèque de purines feux tricolores (ACR 2020)\n• Le vert d'abord : voyez ce que vous POUVEZ manger\n• Jours manqués ? Confirmez et continuez\n• Graines d'habitude : une petite action, célébrée\n\nRAPPORT MÉDECINAL (déverrouillage unique)\nUne page pour 15 minutes. Jours sans données marqués « non enregistré » — jamais inventés.\n\nCONFIDENTIALITÉ\nDonnées sur votre appareil. Aucun compte. Aucun suivi.\n\nPrix fondateur pour les 100 premiers. Le développeur vit lui-même avec un acide urique élevé.\n\nOutil de suivi — ne diagnostique ni ne traite. Sources : ACR 2020, G-CAN 2024."},
    "es-ES": {"subtitle": "Urate, crisis y purinas",
           "keywords": "gota,ácido úrico,purinas,crisis,dieta,registro,urate",
           "description": "La app de registro para personas con gota y ácido úrico alto. Basada en un ritmo de revisión cada 2 meses — validado en un ensayo clínico. Sin anuncios. Sin suscripción.\n\nPOR QUÉ URICNOTE\nEl 63 % de los pacientes cree que la dieta basta — el control necesita AMBOS: medicación Y estilo de vida. UricNote muestra ambas vías lado a lado.\n\nQUÉ LA DIFERENCIA\n• Contador de días sin crisis + insignia «Bajo control» (G-CAN 2024)\n• Motor de ritmo: próxima revisión automática (ensayo GoutSMART, 2022)\n• Ranking de desencadenantes desde TUS datos — reglas explicables\n• Biblioteca de purinas con semáforo (ACR 2020)\n• Primero lo verde: mira lo que SÍ puedes comer\n• ¿Días sin registrar? Confirma y sigue\n• Semillas de hábito: UNA pequeña acción\n\nINFORME MÉDICO (desbloqueo único)\nUna página para 15 minutos. Días sin datos como «no registrado» — nunca inventados.\n\nPRIVACIDAD\nDatos en tu dispositivo. Sin cuenta. Sin rastreo.\n\nPrecio fundador para los primeros 100. El desarrollador también vive con ácido úrico alto.\n\nHerramienta de registro — no diagnostica ni trata. Fuentes: ACR 2020, G-CAN 2024."},
    "zh-Hans": {"subtitle": "记录尿酸、发作与嘌呤，目标 6.0",
           "keywords": "痛风,尿酸,嘌呤,发作,记录,饮食,健康,高尿酸,降尿酸,尿酸值",
           "description": "为痛风和高尿酸人群打造的记录应用。基于临床试验验证的「每 2 个月复查」节律。无广告、无订阅、一次买断。\n\n为什么是尿酸笔记\n63% 的患者以为管住嘴就够了——但尿酸控制需要「药物+生活方式」双轨并行。尿酸笔记把两条线并排展示：用你自己的数据说话。\n\n差异化功能\n• 无痛天数计数器+「已控制」徽章（对齐 G-CAN 2024 缓解标准）\n• 复查节律引擎：录入化验值自动排下次复查（GoutSMART 2022 试验验证的节律）\n• 诱因排行来自你自己的数据——最近 3 次发作前共同吃了什么？（规则级可解释，不是黑盒评分）\n• 嘌呤食物库红黄绿灯（ACR 2020 指南，标注版本）\n• 绿灯优先浏览：先看能吃什么，再看要注意什么\n• 断记不用怕：确认一下就补上，不惩罚\n• 习惯种子：从一个最小动作开始，即时庆祝\n\n医生报告（一次买断解锁）\n一页 A4，医生 15 分钟读完：尿酸趋势+发作史+依从率+用药清单。缺数据明确标「未记录」——绝不编造。\n\n隐私\n数据只在你的手机上。无账号。无追踪。\n\n创始价给前 100 名用户。开发者本人就是高尿酸人群。\n\n本应用是记录工具，不提供诊断或治疗建议。数据来源：ACR 2020 指南、G-CAN 2024 缓解标准、公开临床试验。"},
    "zh-Hant": {"subtitle": "記錄尿酸值、發作與普林，目標 6.0",
           "keywords": "痛風,尿酸,普林,發作,記錄,飲食,健康",
           "description": "為痛風和高尿酸人群打造的記錄應用。基於臨床試驗驗證的「每 2 個月複查」節律。無廣告、無訂閱、一次買斷。\n\n差異化\n• 無痛天數計數器+「已控制」徽章（對齊 G-CAN 2024 緩解標準）\n• 複查節律引擎：錄入化驗值自動排下次複查（GoutSMART 2022 試驗驗證的節律）\n• 誘因排行來自你自己的數據——規則級可解釋，不是黑盒評分\n• 普林食物庫紅黃綠燈（ACR 2020 指南，標註版本）\n• 綠燈優先瀏覽：先看能吃什麼\n• 斷記不用怕：確認一下就補上，不懲罰\n• 習慣種子：從一個最小動作開始\n\n醫師報告（一次買斷解鎖）\n一頁 A4，醫師 15 分鐘讀完。缺數據明確標「未記錄」——絕不編造。\n\n隱私：資料只在你的手機上。\n\n創始價給前 100 名。開發者本人就是高尿酸人群。\n\n本應用是記錄工具，不提供診斷或治療建議。資料來源：ACR 2020 指南、G-CAN 2024 緩解標準。"},
}'''
t = t[:m2.start()] + locales_new + t[m2.end():]

out = r'E:\AI-Projects\个人成长\10-项目\SaaS项目\uricnote-ios\store\asc_填料.py'
open(out, 'w', encoding='utf-8').write(t)
import ast
ast.parse(t)
print('asc_填料.py 生成+语法OK')
print('APP_ID=6834462104 / 七语LOCALES / 隐私URL=uricnote-privacy / 截图=uricnote store/shot1-3.png')
