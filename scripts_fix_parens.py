# -*- coding: utf-8 -*-
# Section族右括号补全（文件版避heredoc）
import re, glob

total = 0
PAT = re.compile(u'(\\w+\\()\\s*L\\("((?:[^"\\\\]|\\\\.)*)",\\s*"((?:[^"\\\\]|\\\\.)*)"\\)\\s*\\{')
for f in glob.glob('UricNote/*.swift'):
    s = open(f, encoding='utf-8').read()
    lines = s.split('\n')
    out = []
    for line in lines:
        m = PAT.search(line)
        if m and m.group(1) != 'L(':
            line2 = PAT.sub(lambda mm: '%sL("%s", "%s")) {' % (mm.group(1), mm.group(2), mm.group(3)), line)
            if line2 != line:
                total += 1
            out.append(line2)
        else:
            out.append(line)
    open(f, 'w', encoding='utf-8').write('\n'.join(out))
print(u'补括号 %d 行' % total)
