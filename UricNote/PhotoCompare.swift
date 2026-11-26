import SwiftUI
import PhotosUI

// MARK: - 照片对比（Pro 权益补齐 · 2026-11-27）
//
// 用途：痛风/高尿酸最直观的可见变化在关节外观（红肿→消退）——拍照留档+两张并排对比。
// 设计纪律（与全 App 一致）：
// - 隐私最小化：照片只存本机 Documents/photos/，不进 iCloud 备份开关可控（默认跟系统），
//   元数据（拍摄时间）另存 JSON，照片文件名=UUID 无任何个人信息。
// - 记录归属：每张照片带 bodyPart（部位）+ takenAt（拍摄时间），对比时同部位并排。
// - Pro 门控：记录免费无限量（记录本体永远免费——本项目铁律），**对比视图是 Pro**。
//   与「免费无限记录 / Pro 看长弧」的既有分层同构：记录是入口，回看长历史要 Pro。

// MARK: 数据层

struct PhotoEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var bodyPart: String          // 部位（与 Flare.joints 同一份部位词表）
    var takenAt: Date
    var fileName: String          // Documents/photos/ 下的文件名（UUID.jpg）
    var note: String? = nil       // 备注（如"消了一半"）

    // 2026-11-27：与 provenance 族同一纪律——合成 Codable 不认默认值，缺 key 不整条失败
    init(id: UUID = UUID(), bodyPart: String, takenAt: Date, fileName: String, note: String? = nil) {
        self.id = id
        self.bodyPart = bodyPart
        self.takenAt = takenAt
        self.fileName = fileName
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        bodyPart = try c.decode(String.self, forKey: .bodyPart)
        takenAt = try c.decode(Date.self, forKey: .takenAt)
        fileName = try c.decode(String.self, forKey: .fileName)
        note = try c.decodeIfPresent(String.self, forKey: .note)
    }
}

// MARK: Store 扩展（照片元数据走同一 UserDefaults key 体系，照片文件走 Documents）

extension Store {
    static let photoEntriesKey = "ur.photoEntries"
    static let photosDirName = "photos"

    /// Documents/photos/ 目录（不存在则建）
    static var photosDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(photosDirName)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func loadPhotoEntries() -> [PhotoEntry] {
        guard let d = defaults.data(forKey: Self.photoEntriesKey) else { return [] }
        do {
            return try JSONDecoder().decode([PhotoEntry].self, from: d)
        } catch {
            NSLog("🔴 UricNote load FAILED ur.photoEntries: \(error.localizedDescription)")
            return []
        }
    }

    func savePhotoEntries(_ entries: [PhotoEntry]) {
        encodeLog(entries, forKey: Self.photoEntriesKey)
    }

    /// 删除条目时连照片文件一起删（否则 Documents 越积越大）
    func deletePhotoEntry(_ entry: PhotoEntry, from entries: inout [PhotoEntry]) {
        let url = Self.photosDirectory.appendingPathComponent(entry.fileName)
        try? FileManager.default.removeItem(at: url)
        entries.removeAll { $0.id == entry.id }
        savePhotoEntries(entries)
    }
}

// MARK: 部位词表（与发作记录同一份——对比时按部位配对）

enum PhotoBodyParts {
    static let all = [L("Big toe", "脚趾"), L("Ankle", "脚踝"), L("Knee", "膝盖"),
                      L("Finger", "手指"), L("Wrist", "手腕"), L("Elbow", "手肘"),
                      L("Heel", "脚跟"), L("Instep", "脚背")]
}

// MARK: 页面：照片记录 + 对比

struct PhotosPage: View {
    @ObservedObject var store = Store.shared
    @EnvironmentObject private var pro: ProStore
    @State private var entries: [PhotoEntry] = []
    @State private var pickerPart: String = PhotoBodyParts.all.first ?? ""
    @State private var showPicker = false
    @State private var pendingImage: UIImage? = nil
    @State private var showNoteEditor = false
    @State private var noteText = ""
    @State private var compareSelection: [UUID] = []   // 选中的两张（对比模式）
    @State private var compareMode = false
    @State private var paywall = false

    /// 有照片的部位（对比按部位配对）
    private var partsWithPhotos: [String] {
        Array(Set(entries.map(\.bodyPart))).sorted()
    }

    var body: some View {
        List {
            // ── 拍照/选照片 ──
            Section {
                HStack {
                    Picker(L("Body part", "部位"), selection: $pickerPart) {
                        ForEach(PhotoBodyParts.all, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    Spacer()
                    Button {
                        showPicker = true
                    } label: {
                        Label(L("Add photo", "拍照/选照片"), systemImage: "camera.fill")
                            .font(.body.weight(.semibold))
                    }
                }
            } footer: {
                Text(L("Photos stay on this phone only (Documents folder). Record freely — comparing two photos side by side is a Pro feature.",
                       "照片只存在本机（Documents 目录）。拍照记录免费不限量——两张并排对比是 Pro 功能。"))
            }

            // ── 对比模式 ──
            if entries.count >= 2 {
                Section {
                    Toggle(L("Compare mode (Pro)", "对比模式（Pro）"), isOn: Binding(
                        get: { compareMode },
                        set: { on in
                            if on && !pro.isPro {
                                paywall = true
                                compareMode = false
                            } else {
                                compareMode = on
                                if !on { compareSelection = [] }
                            }
                        }
                    ))
                    if compareMode {
                        Text(L("Pick two photos of the same body part — they open side by side.",
                               "选同一部位的两张照片——并排打开对比。"))
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }

            // ── 列表（按部位分组，组内最新在前）──
            ForEach(partsWithPhotos, id: \.self) { part in
                Section(part) {
                    let partEntries = entries.filter { $0.bodyPart == part }
                        .sorted { $0.takenAt > $1.takenAt }
                    ForEach(partEntries) { e in
                        photoRow(e, selectable: compareMode)
                    }
                }
            }

            if entries.isEmpty {
                Section {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.largeTitle).foregroundColor(.secondary)
                        Text(L("No photos yet", "还没有照片"))
                            .font(.body.weight(.medium))
                        Text(L("Photograph the affected joint today — in a few weeks, compare and see the change with your own eyes.",
                               "今天给发作的关节拍一张——过几周再拍一张，对比肉眼可见的变化。"))
                            .font(.caption).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle(L("Photo compare", "照片对比"))
        .onAppear { entries = store.loadPhotoEntries() }
        .sheet(isPresented: $showPicker) {
            PhotoLibPicker { img in
                if let img {
                    pendingImage = img
                    noteText = ""
                    showNoteEditor = true
                }
            }
        }
        .sheet(isPresented: $paywall) { ProPaywallView().environmentObject(pro) }
        .sheet(item: $comparePair) { pair in
            PhotoCompareView(photos: pair.photos)
        }
        .sheet(item: $fullPhoto) { e in
            PhotoCompareView(photos: [e])
        }
        .alert(L("Add a note (optional)", "加备注（可选）"), isPresented: $showNoteEditor) {
            TextField(L("e.g. swelling down a lot", "如：消肿了不少"), text: $noteText)
            Button(L("Save", "保存")) { savePending() }
            Button(L("Cancel", "取消"), role: .cancel) { pendingImage = nil }
        }
    }

    private func photoRow(_ e: PhotoEntry, selectable: Bool) -> some View {
        Button {
            if selectable {
                toggleCompare(e.id)
            } else {
                showFull(e)
            }
        } label: {
            HStack(spacing: 12) {
                if let img = loadImage(e) {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cardBG)
                        .frame(width: 56, height: 56)
                        .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(e.takenAt.formatted(.dateTime.month().day()))
                        .font(.body.weight(.medium))
                    if let n = e.note, !n.isEmpty {
                        Text(n).font(.caption).foregroundColor(.secondary).lineLimit(1)
                    }
                }
                Spacer()
                if selectable {
                    Image(systemName: compareSelection.contains(e.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(compareSelection.contains(e.id) ? .brand : .secondary)
                }
            }
            .contentShape(Rectangle())   // 整行可点（Spacer 死区教训）
        }
        .buttonStyle(.plain)
    }

    private func toggleCompare(_ id: UUID) {
        if compareSelection.contains(id) {
            compareSelection.removeAll { $0 == id }
        } else {
            compareSelection.append(id)
            if compareSelection.count > 2 { compareSelection.removeFirst() }
        }
        if compareSelection.count == 2 {
            // 两张齐了：进对比页（部位已在选择时天然一致——列表按部位分组）
            let a = entries.first { $0.id == compareSelection[0] }
            let b = entries.first { $0.id == compareSelection[1] }
            if let a, let b {
                comparePair = PhotoPair(a, b)
            }
        }
    }

    @State private var comparePair: PhotoPair? = nil
    @State private var fullPhoto: PhotoEntry? = nil

    private func showFull(_ e: PhotoEntry) {
        fullPhoto = e
    }

    private func loadImage(_ e: PhotoEntry) -> UIImage? {
        let url = Store.photosDirectory.appendingPathComponent(e.fileName)
        guard let d = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: d)
    }

    private func savePending() {
        guard let img = pendingImage else { return }
        let fileName = "\(UUID().uuidString).jpg"
        let url = Store.photosDirectory.appendingPathComponent(fileName)
        // 压到最长边 1600px 再存（关节对比不需要原分辨率，Documents 省空间）
        let maxSide: CGFloat = 1600
        let scale = min(1, maxSide / max(img.size.width, img.size.height))
        let scaled = scale < 1 ? UIImage(data: img.jpegData(compressionQuality: 1) ?? Data())?
            .resized(to: CGSize(width: img.size.width * scale, height: img.size.height * scale)) ?? img : img
        if let data = scaled.jpegData(compressionQuality: 0.85) {
            try? data.write(to: url, options: .atomic)
            var list = store.loadPhotoEntries()
            list.append(PhotoEntry(bodyPart: pickerPart,
                                   takenAt: Date(),
                                   fileName: fileName,
                                   note: noteText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : noteText))
            entries = list
            store.savePhotoEntries(list)
            UricCelebrate.show(L("Photo saved ✓", "照片已保存 ✓"))
        }
        pendingImage = nil
        noteText = ""
    }
}

// MARK: 对比对容器（sheet(item:) 要求 Identifiable——数组本身不是）

struct PhotoPair: Identifiable {
    let id: String
    let photos: [PhotoEntry]
    init(_ a: PhotoEntry, _ b: PhotoEntry) {
        self.id = [a.id.uuidString, b.id.uuidString].sorted().joined(separator: "-")
        self.photos = [a, b]
    }
}

// MARK: 全屏看图 + 并排对比页

struct PhotoCompareView: View {
    let photos: [PhotoEntry]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            if photos.count == 2 {
                // 并排对比（Pro 核心交付）
                HStack(alignment: .top, spacing: 10) {
                    ForEach(photos) { p in
                        VStack(spacing: 6) {
                            if let img = UIImage(contentsOfFile: Store.photosDirectory.appendingPathComponent(p.fileName).path) {
                                Image(uiImage: img)
                                    .resizable().scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            Text(p.takenAt.formatted(.dateTime.year().month().day()))
                                .font(.caption.weight(.semibold))
                            if let n = p.note, !n.isEmpty {
                                Text(n).font(.caption2).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                let days = Calendar.current.dateComponents([.day],
                    from: min(photos[0].takenAt, photos[1].takenAt),
                    to: max(photos[0].takenAt, photos[1].takenAt)).day ?? 0
                Text(L("\(photos[0].bodyPart) · \(days) days apart", "\(photos[0].bodyPart) · 相隔 \(days) 天"))
                    .font(.callout.weight(.medium))
                    .foregroundColor(.secondary)
            } else {
                // 单张全屏
                if let p = photos.first,
                   let img = UIImage(contentsOfFile: Store.photosDirectory.appendingPathComponent(p.fileName).path) {
                    Image(uiImage: img)
                        .resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                    Text(p.takenAt.formatted(.dateTime.year().month().day()))
                        .font(.caption).foregroundColor(.secondary)
                    if let n = p.note, !n.isEmpty {
                        Text(n).font(.caption).foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(L("Compare", "对比"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: PhotosPicker 包装（iOS16 API）

struct PhotoLibPicker: UIViewControllerRepresentable {
    let onPicked: (UIImage?) -> Void
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ vc: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibPicker
        init(_ parent: PhotoLibPicker) { self.parent = parent }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            guard let item = results.first else { parent.onPicked(nil); return }
            item.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                DispatchQueue.main.async {
                    self.parent.onPicked(obj as? UIImage)
                }
            }
        }
    }
}

// MARK: UIImage 缩放助手

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
