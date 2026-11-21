# -*- coding: utf-8 -*-
# 分类chip点击失效修复（健哥令3）：List 行内多 Button 必须 borderless——三处（库页/管理日常/其他同族）
# + 小字三色（健哥令2后半/4）：管理日常食物适量黄注意红；管理场景能吃绿适量黄注意红
p = r"E:\AI-Projects\个人成长\10-项目\SaaS项目\uricnote-ios\UricNote\LearnView.swift"
s = open(p, encoding='utf-8').read()

# ①库页chip加borderless
old1 = '''                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                        ForEach(Self.categories, id: \\.self) { c in
                            Button {
                                category = c
                            } label: {
                                Text(c)
                                    .font(.caption.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(category == c ? Color.brand : Color.gray.opacity(0.12))
                                    .foregroundColor(category == c ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 2)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                } header: {
                    Text("嘌呤食物库")'''
new1 = '''                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                        ForEach(Self.categories, id: \\.self) { c in
                            Button {
                                category = c
                            } label: {
                                Text(c)
                                    .font(.caption.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(category == c ? Color.brand : Color.gray.opacity(0.12))
                                    .foregroundColor(category == c ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.borderless)   // 🔴健哥11-22实锤修复：List行内多Button无borderless=整行tap只给一个按钮（"其他"能点其余不能）
                        }
                    }
                    .padding(.vertical, 2)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                } header: {
                    Text("嘌呤食物库")'''
assert old1 in s, '库页chip未匹配'
s = s.replace(old1, new1)

# ②库页"添加"按钮同族风险——它也在List行内（旁边还有levelName文本）——加borderless
old2 = '''                        if tab != 0 {
                            if store.meta.dailyFoods.contains(item.name) {
                                Button("已添加") {
                                    store.meta.dailyFoods.removeAll { $0 == item.name }
                                    store.save()
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.bordered)
                                .tint(.brand)
                            } else {
                                Button("添加") {
                                    store.meta.dailyFoods.append(item.name)
                                    store.save()
                                    UricCelebrate.show("已加到日常饮食表")
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.borderedProminent)
                                .tint(.brand)
                            }
                        }'''
new2 = '''                        if tab != 0 {
                            if store.meta.dailyFoods.contains(item.name) {
                                Button("已添加") {
                                    store.meta.dailyFoods.removeAll { $0 == item.name }
                                    store.save()
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.bordered)
                                .tint(.brand)
                            } else {
                                Button("添加") {
                                    store.meta.dailyFoods.append(item.name)
                                    store.save()
                                    UricCelebrate.show("已加到日常饮食表")
                                }
                                .font(.caption.weight(.semibold))
                                .buttonStyle(.borderedProminent)
                                .tint(.brand)
                            }
                        }
                        // List行内多Button统一borderless纪律（同chip根因）
                        .buttonStyle(.borderless)'''
# 注意：.borderless 与 .bordered 组合会覆盖——改用外层HStack整体处理更稳
# 实际上 bordered/borderedProminent 本身有独立样式不受行吞——chip问题只在无样式Button
# 上面②其实不必要，撤回（不加）

s = s  # no-op

open(p, 'w', encoding='utf-8').write(s)
print('①库页chip borderless 完成（bordered系按钮本就独立响应，无需处理）')

# ③管理日常食物页chip同样修（RecordListView.swift）+小字三色
p2 = r"E:\AI-Projects\个人成长\10-项目\SaaS项目\uricnote-ios\UricNote\RecordListView.swift"
s2 = open(p2, encoding='utf-8').read()

old3 = '''                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                        ForEach(Self.categories, id: \\.self) { c in
                            Button {
                                category = c
                            } label: {
                                Text(c)
                                    .font(.caption.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(category == c ? Color.brand : Color.gray.opacity(0.12))
                                    .foregroundColor(category == c ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text("管理日常食物（勾选=在表里）")'''
new3 = '''                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                        ForEach(Self.categories, id: \\.self) { c in
                            Button {
                                category = c
                            } label: {
                                Text(c)
                                    .font(.caption.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(category == c ? Color.brand : Color.gray.opacity(0.12))
                                    .foregroundColor(category == c ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.borderless)   // 🔴同库页根因修复
                        }
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text("管理日常食物（勾选=在表里）")'''
assert old3 in s2, '管理页chip未匹配'
s2 = s2.replace(old3, new3)

# ④管理日常食物行小字三色（适量黄/注意红）
old4 = '''                ForEach(candidates) { item in
                    Button {
                        if store.meta.dailyFoods.contains(item.name) {
                            store.meta.dailyFoods.removeAll { $0 == item.name }
                        } else {
                            store.meta.dailyFoods.append(item.name)
                        }
                        store.save()
                    } label: {
                        HStack {
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
                }'''
new4 = '''                ForEach(candidates) { item in
                    Button {
                        if store.meta.dailyFoods.contains(item.name) {
                            store.meta.dailyFoods.removeAll { $0 == item.name }
                        } else {
                            store.meta.dailyFoods.append(item.name)
                        }
                        store.save()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).foregroundColor(.primary)
                                // 健哥11-22令2：小字三色——注意=红 适量=黄（本页只有这两档）
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
                    .buttonStyle(.plain)   // 行Button用plain保整行可点
                }'''
assert old4 in s2, '管理页行未匹配'
s2 = s2.replace(old4, new4)

# ⑤管理场景行小字三色（能吃绿/适量黄/注意红）——它用levelName函数文字，改带色
old5 = '''                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).foregroundColor(.primary)
                                    Text("嘌呤约 \\(Int(item.uricPer100g)) mg/100g · \\(levelName(item.level))")
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer()
                                if store.meta.customScenes.contains(item.name) {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.brand)
                                }
                            }
                        }'''
new5 = '''                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).foregroundColor(.primary)
                                    // 健哥11-22令4：小字三色——能吃=绿 适量=黄 注意=红
                                    Text("嘌呤约 \\(Int(item.uricPer100g)) mg/100g · \\(levelName(item.level))")
                                        .font(.caption2)
                                        .foregroundColor(item.level == "red" ? .danger : item.level == "yellow" ? .warn : .success)
                                }
                                Spacer()
                                if store.meta.customScenes.contains(item.name) {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.brand)
                                }
                            }
                        }'''
assert old5 in s2, '场景页行未匹配'
s2 = s2.replace(old5, new5)

open(p2, 'w', encoding='utf-8').write(s2)
print('③管理页chip ④日常小字三色 ⑤场景小字三色 完成')
