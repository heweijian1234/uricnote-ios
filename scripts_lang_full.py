# -*- coding: utf-8 -*-
# U 英文化批量转换器 v2（任意位置裸中文字符串→L；保护种子/枚举/tag）
import re, json, glob, os

D = json.load(open('scripts_lang_dict.json', encoding='utf-8'))

for f in sorted(glob.glob('UricNote/*.swift') + glob.glob('Shared/*.swift')):
    if 'L10n' in f or 'FoodLibraryData' in f:
        continue
    s = open(f, encoding='utf-8').read()
    protected = []
    def protect(m):
        protected.append(m.group(0))
        return '@@PROTECTED%d@@' % (len(protected) - 1)
    s = re.sub(r'enum PurineDatabase \{.*?\n\}', protect, s, flags=re.S)
    s = re.sub(r'let rules: \[\(String, String\)\] = \[.*?\]', protect, s, flags=re.S)
    s = re.sub(r'case \w+ = "[^"]*"', protect, s)
    s = re.sub(r'\.tag\("[^"]*"\)', protect, s)

    replaced = [0]
    def conv(m):
        zh = m.group(1)
        if zh in D:
            replaced[0] += 1
            en = D[zh].replace('"', '\\"')
            zhs = zh.replace('"', '\\"')
            return 'L("%s", "%s")' % (en, zhs)
        return m.group(0)

    out = []
    L_DONE = re.compile(u'L\\("((?:[^"\\\\]|\\\\.)*)"\\s*,\\s*"((?:[^"\\\\]|\\\\.))*"\\)')
    CN_STR = re.compile(u'"([^"\\n]*[一-鿿][^"\\n]*)"')
    for line in s.split('\n'):
        st = line.strip()
        if st.startswith('//') or st.startswith('*') or st.startswith('/*'):
            out.append(line)
            continue
        noL = L_DONE.sub('@@LDONE@@', line)
        if CN_STR.search(noL):
            out.append(CN_STR.sub(conv, line))
        else:
            out.append(line)
    s2 = '\n'.join(out)
    for i, p in enumerate(protected):
        s2 = s2.replace('@@PROTECTED%d@@' % i, p)
    if s2 != s:
        open(f, 'w', encoding='utf-8').write(s2)
        print(u'✅ %s 替换%d处' % (os.path.basename(f), replaced[0]))
print('--- 批量v2完 ---')
