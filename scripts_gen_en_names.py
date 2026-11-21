# -*- coding: utf-8 -*-
# 308条食物种子英文名生成（nameEn+sourceTagEn批量写入种子）——中→英食物词典
import re, json

# 中→英食物名全量词典（308条）
EN_NAMES = {
  "啤酒": "Beer", "白酒": "Baijiu (Chinese liquor)", "黄酒/绍兴": "Huangjiu / Shaoxing wine",
  "威士忌": "Whisky", "伏特加": "Vodka", "红酒": "Red wine", "清酒": "Sake",
  "梅酒": "Plum wine", "黑啤酒（世涛/黑啤）": "Stout / dark beer", "伏特加（俄罗斯标准）": "Vodka (Russian standard)",
  "格瓦斯": "Kvass",
  "可乐（含糖）": "Cola (sugary)", "橙汁（含糖）": "Orange juice (sugary)", "蜂蜜": "Honey",
  "奶茶": "Milk tea", "果汁（含纯果汁）": "Juice (incl. 100%)", "功能饮料（含糖）": "Energy drink (sugary)",
  "气泡水": "Sparkling water", "苏打水": "Soda water", "椰子水": "Coconut water",
  "柠檬水（无糖）": "Lemonade (no sugar)", "白开水": "Plain water", "矿泉水": "Mineral water",
  "淡茶水": "Light tea", "燕麦奶": "Oat milk", "杏仁奶": "Almond milk",
  "咖啡（美式/黑咖）": "Coffee (black)", "希腊酸奶": "Greek yogurt", "开菲尔发酵乳": "Kefir",
  "豆浆（无糖）": "Soy milk (unsweetened)", "酸奶（低脂）": "Yogurt (low-fat)", "低脂牛奶": "Low-fat milk",
  "动物内脏（肝/腰/脑）": "Organ meats (liver/kidney/brain)", "猪肝": "Pork liver", "猪腰": "Pork kidney",
  "脑花": "Brain", "鹅肝": "Goose liver (foie gras)", "鹅肝酱": "Foie gras",
  "浓肉汤": "Rich meat broth", "老火汤/浓肉汤": "Slow-cooked soup / rich broth", "鱼头汤": "Fish head soup",
  "鸡汤": "Chicken soup", "味噌汤": "Miso soup", "罗宋汤（牛肉甜菜汤）": "Borscht (beef & beet soup)",
  "火锅汤底": "Hot pot broth", "马赛鱼汤": "Bouillabaisse",
  "沙丁鱼": "Sardines", "凤尾鱼": "Anchovies", "秋刀鱼": "Saury (sanma)", "带鱼": "Ribbon fish",
  "贝类牡蛎": "Oysters", "生蚝（牡蛎）": "Oysters", "蛤蜊": "Clams", "蛤蜊扇贝": "Clams & scallops",
  "蟹": "Crab", "蟹膏": "Crab butter", "蟹黄": "Crab roe", "虾脑": "Shrimp head paste",
  "鱼子虾籽": "Fish/shrimp roe", "俄式鱼子酱": "Caviar (Russian)", "俄式红鱼子": "Red caviar",
  "小鱼干": "Dried small fish", "金枪鱼刺身级": "Tuna (sashimi grade)", "沙丁鱼罐头/鱼罐头（油浸）": "Canned sardines (in oil)",
  "基围虾": "Shrimp", "龙虾": "Lobster", "鲍鱼": "Abalone", "扇贝": "Scallops", "海参": "Sea cucumber",
  "海带": "Kelp", "紫菜": "Nori/laver", "鱿鱼": "Squid", "章鱼": "Octopus", "海蜇皮": "Jellyfish",
  "三文鱼": "Salmon", "金枪鱼": "Tuna", "鳕鱼": "Cod", "鲈鱼": "Sea bass", "俄式腌鲱鱼": "Pickled herring",
  "荷兰鲱鱼生吃": "Raw herring (Dutch)", "新西兰青口贝": "Green mussels (NZ)", "葡萄牙烤沙丁鱼": "Grilled sardines (Portuguese)",
  "海胆": "Sea urchin", "干贝（瑶柱）": "Dried scallops", "蚝干": "Dried oysters", "虾米（干）": "Dried shrimp",
  "鱼露": "Fish sauce", "虾酱": "Shrimp paste", "海苔": "Nori (dried)",
  "腊肠腊肉": "Chinese cured sausage/belly", "咸鱼": "Salted fish", "火腿": "Ham", "培根": "Bacon",
  "香肠/热狗肠": "Sausages / hot dogs", "午餐肉": "Spam/luncheon meat", "意大利帕尔玛火腿": "Prosciutto",
  "意式萨拉米": "Salami", "西班牙火腿（伊比利亚）": "Iberian ham", "阿根廷烤肠": "Chorizo",
  "牛肉": "Beef", "猪肉（五花）": "Pork belly", "羊肉": "Lamb", "鸡肉": "Chicken", "鸭肉": "Duck",
  "鹅肉": "Goose", "鸡胸肉": "Chicken breast", "鸡腿肉": "Chicken thigh", "鸭血": "Duck blood curd",
  "牛肉干": "Beef jerky", "猪肉脯": "Pork jerky", "南非干肉条": "Biltong",
  "羊肉串": "Lamb skewers", "烤鸭": "Roast duck", "牛排（西冷）": "Sirloin steak", "德州烤牛腩": "Texas brisket",
  "美式烧烤（BBQ 排骨）": "BBQ ribs", "美式牛排": "Steak", "美式热狗": "Hot dog", "美式水牛城鸡翅": "Buffalo wings",
  "韩式烤肉（五花肉）": "Korean BBQ (pork belly)", "希腊烤羊肉串": "Greek lamb souvlaki", "中东烤肉串": "Kebab",
  "土耳其烤肉": "Doner kebab", "巴西烤肉": "Churrasco", "摩洛哥塔吉锅（羊肉）": "Tagine (lamb)",
  "热狗肠": "Hot dog sausage", "鸡蛋": "Egg", "鸡蛋（全蛋）": "Whole egg", "鹌鹑蛋": "Quail eggs", "皮蛋": "Century egg",
  "汉堡": "Burger", "热狗": "Hot dog", "披萨": "Pizza", "炸鸡": "Fried chicken", "薯条等油炸食品": "French fries & fried food",
  "披萨": "Pizza", "意大利面": "Pasta", "墨西哥卷饼（牛肉）": "Beef burrito", "墨西哥法士达（Fajita）": "Fajitas",
  "墨西哥玉米粽": "Tamale", "法士达": "Fajita", "加拿大肉汁奶酪薯条": "Poutine", "美式蛤蜊浓汤": "Clam chowder",
  "美式蟹饼": "Crab cake", "阿拉斯加帝王蟹腿": "King crab legs (Alaska)", "加拿大烟熏三文鱼": "Smoked salmon (Canada)",
  "秘鲁酸橘汁腌鱼": "Ceviche", "巴西黑豆炖肉": "Feijoada", "英式炸鱼薯条": "Fish & chips",
  "新西兰炸鱼薯条": "Fish & chips (NZ)", "澳大利亚肉派": "Meat pie (Aussie)", "英国炸鱼薯条": "Fish & chips (UK)",
  "英式早餐（全套）": "Full English breakfast", "苏格兰蛋": "Scotch egg", "比利时淡菜薯条": "Moules-frites",
  "夜宵·炒粉/炒面": "Late-night stir-fried noodles", "夜宵·烤串（综合）": "Late-night BBQ skewers",
  "夜宵·小龙虾": "Late-night crayfish", "酒会·下酒拼盘": "Party platter", "婚宴·宴席（综合）": "Wedding banquet",
  "晚宴·西式套餐": "Western dinner set", "聚会·火锅": "Hot pot party", "宴会": "Banquet",
  "寿司（综合）": "Sushi (assorted)", "三文鱼刺身": "Salmon sashimi", "金枪鱼刺身": "Tuna sashimi",
  "鳗鱼饭": "Unagi rice", "天妇罗": "Tempura", "日式": "Japanese", "寿司": "Sushi",
  "韩式部队锅": "Budae-jjigae (army stew)", "石锅拌饭": "Bibimbap", "泡菜": "Kimchi",
  "豆腐": "Tofu", "豆腐（北）": "Firm tofu", "豆腐乳": "Fermented tofu", "扁豆": "Lentils",
  "豆芽": "Bean sprouts", "四季豆": "Green beans", "荷兰豆": "Snow peas", "豇豆": "Cowpeas", "豆苗": "Pea shoots",
  "脱水香菇/干菌菇": "Dried mushrooms", "香菇（干）": "Dried shiitake", "蘑菇（口蘑）": "Button mushrooms",
  "木耳（水发）": "Wood ear (rehydrated)", "银耳（水发）": "Snow fungus (rehydrated)", "菌菇类": "Mushrooms",
  "紫菜海带干": "Dried nori & kelp", "酵母提取物零食（营养酵母）": "Nutritional yeast snacks",
  "酵母粉（烘焙/啤酒酵母）": "Yeast extract (baking/brewer's)",
  "鸡精/浓汤宝": "Chicken bouillon / stock cubes", "鸡精/浓汤宝类调料": "Bouillon cubes & seasoning",
  "肉汁浓汤": "Gravy", "芦笋": "Asparagus", "秋葵": "Okra", "西兰花": "Broccoli", "花椰菜": "Cauliflower",
  "紫甘蓝": "Red cabbage", "羽衣甘蓝": "Kale", "菠菜": "Spinach", "芹菜": "Celery", "笋": "Bamboo shoots",
  "莴笋": "Celtuce", "茼蒿": "Chrysanthemum greens", "空心菜": "Water spinach", "生菜": "Lettuce",
  "油菜": "Bok choy", "韭菜": "Chives", "冬瓜": "Winter melon", "丝瓜": "Loofah", "苦瓜": "Bitter melon",
  "南瓜": "Pumpkin", "黄瓜": "Cucumber", "胡萝卜": "Carrot", "白萝卜": "Daikon", "萝卜": "Radish",
  "西红柿": "Tomato", "番茄": "Tomato", "白菜": "Napa cabbage", "藕": "Lotus root", "芋头": "Taro",
  "山药": "Chinese yam", "土豆": "Potato", "红薯": "Sweet potato", "玉米": "Corn", "茄子": "Eggplant",
  "彩椒": "Bell pepper", "辣椒": "Chili pepper", "葱": "Scallion", "蒜": "Garlic", "瓜类": "Melons",
  "苹果": "Apple", "香蕉": "Banana", "橙子": "Orange", "橘子": "Mandarin orange", "梨": "Pear",
  "桃子": "Peach", "葡萄": "Grapes", "西瓜": "Watermelon", "哈密瓜": "Hami melon", "木瓜": "Papaya",
  "椰子": "Coconut", "草莓": "Strawberry", "蓝莓": "Blueberry", "树莓": "Raspberry", "黑莓": "Blackberry",
  "樱桃": "Cherries", "车厘子": "Cherries", "荔枝": "Lychee", "芒果": "Mango", "菠萝": "Pineapple",
  "柚子": "Pomelo", "猕猴桃": "Kiwi", "榴莲": "Durian", "山竹": "Mangosteen", "番石榴": "Guava",
  "龙眼": "Longan", "红毛丹": "Rambutan", "火龙果": "Dragon fruit", "百香果": "Passion fruit",
  "杨梅": "Waxberry", "枇杷": "Loquat", "石榴": "Pomegranate", "柿子": "Persimmon", "甘蔗": "Sugarcane",
  "山楂": "Hawthorn", "枣": "Jujube", "无花果": "Fig", "牛油果": "Avocado", "菠萝蜜": "Jackfruit",
  "柠檬": "Lemon", "果冻": "Jelly", "布丁": "Pudding", "蛋糕（奶油）": "Cream cake", "提拉米苏": "Tiramisu",
  "马卡龙": "Macaron", "月饼": "Mooncake", "绿豆糕": "Mung bean cake", "蛋黄酥": "Egg yolk pastry",
  "冰淇淋": "Ice cream", "雪糕": "Popsicle", "巧克力（黑巧 70%）": "Dark chocolate (70%)", "薯片": "Potato chips",
  "辣条": "Spicy strips (latiao)", "锅巴": "Crispy rice", "话梅": "Dried plum", "蜜饯": "Candied fruit",
  "坚果混合装": "Mixed nuts", "核桃": "Walnuts", "花生": "Peanuts", "杏仁": "Almonds", "腰果": "Cashews",
  "瓜子": "Sunflower seeds", "栗子": "Chestnuts", "凉皮": "Liangpi (cold noodles)", "酸辣粉": "Hot & sour noodles",
  "爆米花": "Popcorn", "饼干": "Cookies", "糖果": "Candy", "肉干肉脯": "Meat jerky",
  "米饭": "Rice", "米线（清汤）": "Rice noodles (clear soup)", "面条": "Noodles", "燕麦": "Oats",
  "黑麦面包": "Rye bread", "德国碱水面包（布雷结）": "Pretzel (German)", "法棍面包": "Baguette", "可颂": "Croissant",
  "全麦面包": "Whole wheat bread", "面包": "Bread", "荞麦面": "Soba noodles", "藜麦": "Quinoa",
  "馒头": "Steamed bun", "包子": "Steamed filled bun", "饺子": "Dumplings", "馄饨": "Wontons",
  "土豆泥": "Mashed potato", "土豆泥（无奶油）": "Mashed potato (no cream)", "玉米片（低糖）": "Corn flakes",
  "燕麦粥": "Oatmeal", "西班牙油条（吉拿棒）": "Churros", "千层面": "Lasagna",
  "意式肉酱面（博洛尼亚）": "Spaghetti Bolognese", "意式烩饭（海鲜）": "Seafood risotto", "意式烩饭（蘑菇）": "Mushroom risotto",
  "西班牙海鲜饭": "Paella", "法式咸派（洛林糕）": "Quiche Lorraine", "法式蜗牛（勃艮第）": "Escargots de Bourgogne",
  "法式洋葱汤": "French onion soup", "德国白香肠": "Weisswurst", "德国猪肘": "Pork knuckle (German)",
  "德国酸菜": "Sauerkraut", "俄式饺子（佩尔梅尼）": "Pelmeni", "俄式蜂蜜蛋糕": "Medovik (honey cake)",
  "蓝纹奶酪": "Blue cheese", "布里奶酪": "Brie", "帕玛森奶酪": "Parmesan", "马苏里拉奶酪": "Mozzarella",
  "瑞士芝士火锅": "Cheese fondue", "鹰嘴豆泥": "Hummus", "中东": "Middle Eastern",
  "英杰拉饼": "Injera", "希腊 yogurt": "Greek yogurt", "gyro": "Gyro",
  "白酒（中国烈酒）": "Baijiu", "红酒（干红）": "Dry red wine",
}

# sourceTag 英文映射
EN_SOURCES = {
  "ACR 2020": "ACR 2020", "Drugs.com": "Drugs.com", "NEJM 47000人研究": "NEJM 47k study",
  "NEJM 47000人研究": "NEJM 47k study", "卫健委2024": "NHHC 2024 (China)", "USDA": "USDA",
  "日本食品嘌呤表": "Japanese purine table", "德国联邦食品库": "German federal food DB",
  "俄罗斯食品表": "Russian food table", "澳新食品标准局": "FSANZ (AU/NZ)", "韩国食品成分表": "Korean food composition table",
  "东南亚食品表": "SE Asian food table", "荷兰食品表": "Dutch food table", "法国食品成分表": "French food composition table",
  "估算·复合": "Estimated (composite)", "估算·卫健委基表": "Estimated (NHHC base)",
  "估算·浓缩汤底": "Estimated (concentrated broth)", "估算·贝类": "Estimated (shellfish)",
  "估算·复合（牛肉酱）": "Estimated (beef sauce)", "估算·复合（虾贝）": "Estimated (shrimp & shellfish)",
  "干品浓缩·卫健委2024": "Dried concentrate · NHHC 2024", "干品浓缩·Drugs.com": "Dried concentrate · Drugs.com",
  "脱水浓缩·Drugs.com": "Dehydrated concentrate · Drugs.com", "脱水浓缩·卫健委2024": "Dehydrated concentrate · NHHC 2024",
  "蒸馏酒嘌呤≈0·酒精抑排泄升尿酸（ACR 2020）": "Distilled: purines ≈0 · alcohol raises UA (ACR 2020)",
  "嘌呤+酒精双通道·诱发最强（ACR 2020）": "Purines + alcohol double hit — strongest trigger (ACR 2020)",
  "嘌呤+酒精双通道（日本食品嘌呤表）": "Purines + alcohol (Japanese purine table)",
  "果糖代谢升尿酸·非嘌呤通道（ACR 2020）": "Fructose raises UA, not purines (ACR 2020)",
  "NEJM 咖啡与痛风研究": "NEJM coffee & gout study", "ACR 2020（植物嘌呤影响弱）": "ACR 2020 (plant purines: weak effect)",
  "卫健委2024（干品浓缩）": "NHHC 2024 (dried concentrate)", "估算·烧烤浓缩": "Estimated (BBQ concentrate)",
  "估算·甲壳类": "Estimated (crustaceans)", "估算·生鱼": "Estimated (raw fish)",
  "估算·烟熏浓缩": "Estimated (smoked)", "估算·腌制浓缩": "Estimated (cured)",
  "Gout Education": "Gout Education", "队列研究综述（中性偏正面证据）": "Cohort reviews (neutral-positive)",
  "现代指南共识（OTCFood 盘点）": "Modern guideline consensus (OTCFood)",
  "FSSAI 误区手册 2019 / OTCFood": "FSSAI myth handbook 2019 / OTCFood",
  "美国痛风教育学会全国调查 2026": "Gout Education Society survey 2026",
  "GBD 青年负担研究 2023 / 韩国体检数据 2024": "GBD youth study 2023 / Korea health data 2024",
  "NICE 指南 / RheumNow": "NICE guideline / RheumNow",
  "行为设计研究（Tiny Habits，Fogg 2019）/ 临床共识": "Tiny Habits (Fogg 2019) / clinical consensus",
  "ACR 2020 指南": "ACR 2020 guideline", "ACR 2020 指南 / 临床共识": "ACR 2020 / clinical consensus",
  "ACR 2020 指南食物表": "ACR 2020 food table",
  "估算·浓缩汤底": "Estimated (concentrated broth)",
  "—": "—",
}

p = r"E:\AI-Projects\个人成长\10-项目\SaaS项目\uricnote-ios\UricNote\LearnView.swift"
s = open(p, encoding='utf-8').read()
m = re.search(r'(enum PurineDatabase \{\n    static let seed: \[PurineItem\] = \[)(.*?)(\n    \]\n\})', s, re.S)
body = m.group(2)
out_lines = []
done = 0
miss = []
for line in body.split('\n'):
    mm = re.search(r'\.init\(name: "([^"]+)", uricPer100g: ([\d.]+), level: "(\w+)", sourceTag: "([^"]+)"\)', line)
    if mm:
        zh, val, lvl, src = mm.group(1), mm.group(2), mm.group(3), mm.group(4)
        en = EN_NAMES.get(zh)
        if not en:
            miss.append(zh)
        srcen = EN_SOURCES.get(src, src)
        new_line = '.init(name: "%s", uricPer100g: %s, level: "%s", sourceTag: "%s", nameEn: "%s", sourceTagEn: "%s"),' % (
            zh, val, lvl, src, en.replace('"', '\\"') if en else '', srcen.replace('"', '\\"'))
        out_lines.append('        ' + new_line)
        done += 1
    else:
        out_lines.append(line)
s = s.replace(body, '\n'.join(out_lines))
open(p, 'w', encoding='utf-8').write(s)
print('英文名写入 %d 条' % done)
print('缺英文名 %d 条:' % len(set(miss)))
for x in sorted(set(miss)):
    print('  ', x)
