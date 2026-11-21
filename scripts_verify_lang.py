# -*- coding: utf-8 -*-
# U UI层终扫 v2（扣数据种子区+L参数+注释）——heredoc转义地狱改文件
import re, glob, os

CN = u'[一-鿿]'
L_PAT = re.compile(u'L\\("((?:[^"\\\\]|\\\\.)*)"\\s*,\\s*"((?:[^"\\\\]|\\\\.))*"\\)')

for f in sorted(glob.glob('UricNote/*.swift') + glob.glob('Shared/*.swift')):
    if 'L10n' in f or 'FoodLibraryData' in f:
        continue
    s = open(f, encoding='utf-8').read()
    if 'LearnView' in f:
        s = re.sub(r'enum PurineDatabase \{.*?\n\}', '', s, flags=re.S)
    if 'Store' in f:
        s = re.sub(r'let rules: \[\(String, String\)\] = \[.*?\]', '', s, flags=re.S)
    for i, line in enumerate(s.split('\n'), 1):
        st = line.strip()
        if st.startswith('//') or st.startswith('*') or st.startswith('/*'):
            continue
        if not re.search(CN, line):
            continue
        cleaned = L_PAT.sub('', line)
        if re.search(CN, cleaned):
            strs = re.findall(u'"([^"]*' + CN + u'[^"]*)"', cleaned)
            if strs:
                print(u'%s:%d: %s' % (os.path.basename(f), i, st[:95]))
print('---UI终扫完---')
