# -*- coding: utf-8 -*-
# 终极残扫 v3（文件版）
import re, glob, os

L_PAT = re.compile(u'L\\("((?:[^"\\\\]|\\\\.)*)"\\s*,\\s*"((?:[^"\\\\]|\\\\.))*"\\)')
CN_STR = re.compile(u'"([^"\\n]*[一-鿿][^"\\n]*)"')
found = set()
for f in glob.glob('UricNote/*.swift') + glob.glob('Shared/*.swift'):
    if 'L10n' in f:
        continue
    s = open(f, encoding='utf-8').read()
    s = re.sub(r'enum PurineDatabase \{.*?\n\}', '', s, flags=re.S)
    s = re.sub(r'let rules: \[\(String, String\)\] = \[.*?\]', '', s, flags=re.S)
    s = re.sub(r'case \w+ = "[^"]*"', '', s)
    s = re.sub(r'\.tag\("[^"]*"\)', '', s)
    s = re.sub(r'nameEn: "[^"]*"', '', s)
    s = re.sub(r'sourceTagEn: "[^"]*"', '', s)
    for i, line in enumerate(s.split('\n'), 1):
        st = line.strip()
        if st.startswith('//') or st.startswith('*') or st.startswith('/*'):
            continue
        if '.init(name:' in line:
            continue
        noL = L_PAT.sub('', line)
        for mm in CN_STR.finditer(noL):
            found.add((os.path.basename(f), i, mm.group(1)[:65]))
print(u'疑似残留 %d 处:' % len(found))
for f, i, zh in sorted(found):
    print(u'  %s:%d: %s' % (f, i, zh))
