# -*- coding: utf-8 -*-
# 括号平衡自检（去字符串/注释后粗查）
import re, glob

issues = 0
for f in sorted(glob.glob('UricNote/*.swift') + glob.glob('Shared/*.swift')):
    s = open(f, encoding='utf-8').read()
    body = re.sub(r'"(?:[^"\\]|\\.)*"', '""', s)
    body = re.sub(r'//.*', '', body)
    bal = body.count('{') - body.count('}')
    par = body.count('(') - body.count(')')
    if bal != 0 or par != 0:
        print(u'⚠️ %s 大括号差%d 小括号差%d' % (f, bal, par))
        issues += 1
print(u'共 %d 个文件不平衡' % issues)
