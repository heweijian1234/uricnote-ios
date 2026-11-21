# -*- coding: utf-8 -*-
# 收集词典缺口（文件版，避heredoc转义）
import re, json, glob

D = json.load(open('scripts_lang_dict.json', encoding='utf-8'))
missing = set()
L_DONE = re.compile(u'L\\("((?:[^"\\\\]|\\\\.)*)"\\s*,\\s*"((?:[^"\\\\]|\\\\.))*"\\)')
CN_STR = re.compile(u'"([^"\\n]*[一-鿿][^"\\n]*)"')
for f in glob.glob('UricNote/*.swift') + glob.glob('Shared/*.swift'):
    if 'L10n' in f or 'FoodLibraryData' in f:
        continue
    s = open(f, encoding='utf-8').read()
    s = re.sub(r'enum PurineDatabase \{.*?\n\}', '', s, flags=re.S)
    s = re.sub(r'let rules: \[\(String, String\)\] = \[.*?\]', '', s, flags=re.S)
    s = re.sub(r'case \w+ = "[^"]*"', '', s)
    s = re.sub(r'\.tag\("[^"]*"\)', '', s)
    for line in s.split('\n'):
        st = line.strip()
        if st.startswith('//') or st.startswith('*'):
            continue
        noL = L_DONE.sub('', line)
        for m in CN_STR.finditer(noL):
            zh = m.group(1)
            if zh not in D:
                missing.add(zh)
print(u'词典缺口 %d 条:' % len(missing))
json.dump(sorted(missing), open('scripts_lang_missing.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
for m in sorted(missing):
    print(' ', m[:78])
