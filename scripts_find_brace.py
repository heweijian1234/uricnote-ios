# -*- coding: utf-8 -*-
"""逐行跟踪括号深度，定位不平衡点（一次性验证脚本 2026-11-27）"""
import sys

path = sys.argv[1] if len(sys.argv) > 1 else 'UricNote/TestDataView.swift'
src = open(path, encoding='utf-8').read()

# 用 scripts_check_braces.py 同款状态机剥离字符串/注释
def strip(src):
    out = []
    i = 0
    n = len(src)
    state = 'code'
    line = 1
    marks = []   # (output_index, line_number)
    while i < n:
        c = src[i]
        nxt = src[i+1] if i+1 < n else ''
        if c == '\n':
            line += 1
        if state == 'code':
            if c == '/' and nxt == '/':
                state = 'line_comment'; i += 2; continue
            if c == '/' and nxt == '*':
                state = 'block_comment'; i += 2; continue
            if c == '"':
                state = 'string'; i += 1; continue
            out.append(c)
            marks.append((len(out)-1, line))
            i += 1
        elif state == 'line_comment':
            if c == '\n':
                state = 'code'; out.append('\n')
            i += 1
        elif state == 'block_comment':
            if c == '*' and nxt == '/':
                state = 'code'; i += 2; continue
            i += 1
        else:
            if c == '\\':
                i += 2; continue
            if c == '"':
                state = 'code'
            i += 1
    return ''.join(out), marks

s, marks = strip(src)
depth = 0
neg_line = None
events = []
mi = 0
for idx, ch in enumerate(s):
    while mi < len(marks) - 1 and marks[mi+1][0] <= idx:
        mi += 1
    ln = marks[mi][1]
    if ch == '{':
        depth += 1
        events.append((ln, depth, '{'))
    elif ch == '}':
        depth -= 1
        events.append((ln, depth, '}'))
        if depth < 0 and neg_line is None:
            neg_line = ln
print('最终深度:', depth)
if neg_line:
    ln = neg_line
    print(f'首个负深度出现在第 {ln} 行:')
    lines = src.split(chr(10))
    for j in range(max(0, ln-4), min(len(lines), ln+2)):
        print(f'  {j+1}: {lines[j][:70]}')
# 最后10个事件
print('最后10个括号事件:')
for ln, d, ch in events[-10:]:
    print(f'  行{ln} 深度{d} {ch}')
