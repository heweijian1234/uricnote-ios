# -*- coding: utf-8 -*-
# 双层L嵌套全库扫修
import re, glob

pat = re.compile(u'L\\("((?:[^"\\\\]|\\\\.)*)",\\s*L\\("\\((?:[^"\\\\]|\\\\.)*\\",\\s*"((?:[^"\\\\]|\\\\.)*)"\\)')
simple = re.compile(u'L\\("([^"]*)",\\s*L\\("[^"]*",\\s*"([^"]*)"\\)')
n = 0
for f in glob.glob('UricNote/*.swift') + glob.glob('Shared/*.swift'):
    s = open(f, encoding='utf-8').read()
    hits = simple.findall(s)
    if hits:
        print(f, u'双层L:', len(hits))
        n += len(hits)
        s2 = simple.sub(r'L("\1", "\2")', s)
        open(f, 'w', encoding='utf-8').write(s2)
print(u'双层L总数 %d —— 已修' % n)
