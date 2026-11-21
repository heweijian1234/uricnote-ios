# -*- coding: utf-8 -*-
# RecordListView 三处：管理页chip borderless+行plain / 日常小字三色 / 场景小字三色
p = r"E:\AI-Projects\个人成长\10-项目\SaaS项目\uricnote-ios\UricNote\RecordListView.swift"
s = open(p, encoding='utf-8').read()

# ①管理页chip borderless
old1 = '''                                .background(category == c ? Color.brand : Color.gray.opacity(0.12))
                                .foregroundColor(category == c ? .white : .primary)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text("管理日常食物（勾选=在表里）")'''
new1 = '''                                .background(category == c ? Color.brand : Color.gray.opacity(0.12))
                                .foregroundColor(category == c ? .white : .primary)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.borderless)   // 🔴同库页根因：List行内多Button必须borderless
                        }
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text("管理日常食物（勾选=在表里）")'''
assert old1 in s, '管理页chip未匹配'
s = s.replace(old1, new1)

# ②管理日常行：小字三色（适量黄/注意红）+行Button保整行可点用plain
old2 = '''                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).foregroundColor(.primary)
                                Text("嘌呤约 \\(Int(item.uricPer100g)) mg/100g · \\(item.sourceTag)")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            if store.meta.dailyFoods.contains(item.name) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.brand)
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "搜食物")
            .navigationTitle("管理日常食物")'''
new2 = '''                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).foregroundColor(.primary)
                                // 健哥11-22令2：小字三色——注意=红 适量=黄
                                Text("嘌呤约 \\(Int(item.uricPer100g)) mg/100g · \\(item.level == "red" ? "注意" : "适量") · \\(item.sourceTag)")
                                    .font(.caption2)
                                    .foregroundColor(item.level == "red" ? .danger : .warn)
                            }
                            Spacer()
                            if store.meta.dailyFoods.contains(item.name) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.brand)
                            }
                        }
                    }
                    .buttonStyle(.plain)   // 整行可点
                }
            }
            .searchable(text: $query, prompt: "搜食物")
            .navigationTitle("管理日常食物")'''
assert old2 in s, '管理日常行未匹配'
s = s.replace(old2, new2)

# ③管理场景行小字三色（能吃绿/适量黄/注意红）
old3 = '''                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).foregroundColor(.primary)
                                    Text("嘌呤约 \\(Int(item.uricPer100g)) mg/100g · \\(levelName(item.level))")
                                        .font(.caption2).foregroundColor(.secondary)
                                }'''
new3 = '''                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).foregroundColor(.primary)
                                    // 健哥11-22令4：小字三色——能吃=绿 适量=黄 注意=红
                                    Text("嘌呤约 \\(Int(item.uricPer100g)) mg/100g · \\(levelName(item.level))")
                                        .font(.caption2)
                                        .foregroundColor(item.level == "red" ? .danger : item.level == "yellow" ? .warn : .success)
                                }'''
assert old3 in s, '场景行未匹配'
s = s.replace(old3, new3)

open(p, 'w', encoding='utf-8').write(s)
print('①管理chip ②日常三色 ③场景三色 完成')
