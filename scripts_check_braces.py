# -*- coding: utf-8 -*-
"""剥离字符串/注释后的 Swift 括号配平检查（一次性验证脚本，2026-11-27）"""
import re

def strip(src):
    out = []
    i = 0
    n = len(src)
    state = 'code'   # code | line_comment | block_comment | string
    while i < n:
        c = src[i]
        nxt = src[i+1] if i+1 < n else ''
        if state == 'code':
            if c == '/' and nxt == '/':
                state = 'line_comment'; i += 2; continue
            if c == '/' and nxt == '*':
                state = 'block_comment'; i += 2; continue
            if c == '"':
                state = 'string'; i += 1; continue
            out.append(c); i += 1
        elif state == 'line_comment':
            if c == '\n':
                state = 'code'; out.append('\n')
            i += 1
        elif state == 'block_comment':
            if c == '*' and nxt == '/':
                state = 'code'; i += 2; continue
            i += 1
        else:  # string
            if c == '\\':
                i += 2; continue
            if c == '"':
                state = 'code'
            i += 1
    return ''.join(out)

files = [
    'Shared/Store.swift',
    'UricNote/TrendView.swift',
    'UricNote/Components.swift',
    'UricNote/RecordListView.swift',
    'UricNote/ClinicReportPDF.swift',
    'UricNote/Dashboard.swift',
    'UricNote/TestDataView.swift',
    'UricNote/Onboarding.swift',
    'UricNote/ProStore.swift',
    'UricNote/UricNoteApp.swift',
    'UricNote/PhotoCompare.swift',
]

ok = True
for f in files:
    s = strip(open(f, encoding='utf-8').read())
    b = s.count('{') - s.count('}')
    p = s.count('(') - s.count(')')
    bk = s.count('[') - s.count(']')
    status = 'OK' if (b == 0 and p == 0 and bk == 0) else 'MISMATCH'
    if status != 'OK':
        ok = False
    print(f, 'brace:', b, 'paren:', p, 'bracket:', bk, status)

print('ALL OK' if ok else 'HAS MISMATCH')
