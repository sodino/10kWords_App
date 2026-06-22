import Foundation

/// 面板保存错误
struct PanelSaveError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// LearningView 的业务管理器。
/// 负责读取文章 JSON、提取当前学习句子。
@MainActor
class LearningManager: ObservableObject {
    /// 当前学习状态（来自 currentLearning.json）
    @Published private(set) var learningData: CurrentLearningData?
    /// 当前学习的文章内容
    @Published private(set) var article: ArticleData?
    /// 当前句子（从 article.content 中以 currentIndex 为起始提取）
    @Published private(set) var currentSentence: String?
    /// 当前句子起始位置
    @Published private var currentIndex: Int = 0
    /// 单词学习区面板列表
    @Published var panels: [PanelType] = []

    /// 是否正在执行批量保存
    @Published var isSaving = false
    /// 保存结果提示
    @Published var saveToastMessage: String?
    @Published var saveToastIsError = false

    // MARK: - 面板操作

    /// 所有面板均可保存，且至少有一个面板非空时返回 true
    var isSavable: Bool {
        // 1. 没有面板 → 不可保存
        guard !panels.isEmpty else { return false }
        // 2. 有面板但存在部分填写的非法面板 → 不可保存
        guard panels.allSatisfy({ $0.isSaveable }) else { return false }
        // 3. 全部都是空面板 → 不可保存（至少有一个面板有内容）
        guard !panels.allSatisfy({ $0.isAllEmpty }) else { return false }
        return true
    }

    func addWordPanel() {
        panels.append(.word(WordPanelData()))
        print("[Learning] Added New Word panel, count: \(panels.count)")
    }

    func addZh2EnPanel() {
        panels.append(.zh2en(Zh2EnPanelData()))
        print("[Learning] Added New zh2en panel, count: \(panels.count)")
    }

    func addGroupPanel() {
        panels.append(.group(GroupPanelData()))
        print("[Learning] Added New Group panel, count: \(panels.count)")
    }

    func saveAllPanels() {
        guard !isSaving else { return }
        guard !panels.isEmpty else {
            showSaveToast("没有可保存的面板", isError: true)
            return
        }
        guard let article else {
            showSaveToast("文章数据缺失", isError: true)
            return
        }

        isSaving = true
        print("[Learning] Save All started, panel count: \(panels.count)")

        Task {
            let snapshots = panels
            let url = article.url
            let time = Self.currentTimeString()

            for (i, panel) in snapshots.enumerated() {
                // 全部为空 → 静默跳过，从界面移除该面板
                if panel.isAllEmpty {
                    await MainActor.run {
                        if let idx = self.panels.firstIndex(where: { $0.id == panel.id }) {
                            self.panels.remove(at: idx)
                        }
                    }
                    print("[Learning] Panel \(i + 1) is empty, skipped")
                    continue
                }

                let result = await Self.savePanel(panel, url: url, time: time)
                switch result {
                case .failure(let error):
                    await MainActor.run {
                        self.showSaveToast("第 \(i + 1) 个面板保存失败: \(error.localizedDescription)", isError: true)
                        self.isSaving = false
                    }
                    return
                case .success(let (filePath, isAppend)):
                    GitUtil.add(filePath: filePath)
                    let fileName = (filePath as NSString).lastPathComponent
                    let action = isAppend ? "append" : "add"
                    let gitMessage: String = {
                        switch panel {
                        case .word:   return "[dev] \(action) word(s): '\(fileName)'"
                        case .zh2en:  return "[dev] \(action) zh2en(s): '\(fileName)'"
                        case .group:  return "[dev] \(action) group: '\(fileName)'"
                        }
                    }()
                    GitUtil.commit(message: gitMessage)
                    await MainActor.run {
                        if let idx = self.panels.firstIndex(where: { $0.id == panel.id }) {
                            self.panels.remove(at: idx)
                        }
                        print("[Learning] Panel \(i + 1) saved successfully")
                    }
                }
            }

            await MainActor.run {
                self.panels = [.word(WordPanelData()), .zh2en(Zh2EnPanelData())]
                self.isSaving = false
                self.showSaveToast("全部保存成功", isError: false)
                print("[Learning] Save All completed")
            }
        }
    }

    private func showSaveToast(_ message: String, isError: Bool) {
        saveToastMessage = message
        saveToastIsError = isError
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.saveToastMessage = nil
        }
    }

    // MARK: - 静态保存逻辑

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    private static func currentTimeString() -> String {
        dateFormatter.string(from: Date())
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return e
    }()

    nonisolated private static func savePanel(_ panel: PanelType, url: String, time: String) -> Result<(filePath: String, isAppend: Bool), PanelSaveError> {
        switch panel {
        case .word(let data):
            return saveNewWord(data, url: url, time: time)
        case .zh2en(let data):
            return saveNewZh2En(data, url: url, time: time)
        case .group(let data):
            return saveNewGroup(data, url: url, time: time)
        }
    }

    // MARK: New Word

    nonisolated private static func saveNewWord(_ data: WordPanelData, url: String, time: String) -> Result<(filePath: String, isAppend: Bool), PanelSaveError> {
        let word = data.word.trimmingCharacters(in: .whitespaces)
        let en = data.enPhonetic.trimmingCharacters(in: .whitespaces)
        let am = data.amPhonetic.trimmingCharacters(in: .whitespaces)
        let pos = data.partOfSpeech.trimmingCharacters(in: .whitespaces)
        let meaning = data.meaning.trimmingCharacters(in: .whitespaces)
        let example = data.sampleSentence.trimmingCharacters(in: .whitespaces)

        guard !word.isEmpty, !en.isEmpty, !am.isEmpty, !pos.isEmpty, !meaning.isEmpty, !example.isEmpty else {
            return .failure(PanelSaveError(message: "word/en/am/partsOfSpeech/meaning/exampleSentence 不能为空"))
        }

        let sample = WordSample(
            partsOfSpeech: pos,
            meaning: meaning,
            exampleSentence: example,
            time: time,
            url: url,
            version: 2
        )

        // 检查是否存在已有文件（append 模式）
        if let existing = findExistingWordFile(pos: pos, word: word) {
            return appendToExistingWord(existing, sample: sample, pos: pos, word: word)
        }

        // 新建文件
        let newWord = NewWordData(word: word, phoneticSymbolEn: en, phoneticSymbolAm: am, sample: [sample])

        guard let jsonData = try? encoder.encode(newWord) else {
            return .failure(PanelSaveError(message: "JSON 编码失败"))
        }

        let fileNumber = nextFileNumber(in: AppConstants.dir10k_Words)
        let fileName = "\(fileNumber)\(pos)_\(word).json"
        let filePath = "\(AppConstants.dir10k_Words)/\(fileName)"

        return writeJSON(jsonData, to: filePath, fileName: fileName).map { ($0, false) }
    }

    // MARK: New zh2en

    /// 在 dir10k_Words 中查找匹配 {数字}{pos}_{word}.json 的文件
    nonisolated private static func findExistingWordFile(pos: String, word: String) -> (filePath: String, fileName: String)? {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: AppConstants.dir10k_Words) else { return nil }
        let suffix = "\(pos)_\(word).json"
        for name in contents {
            if name.hasSuffix(suffix), let firstChar = name.first, firstChar.isNumber {
                return ("\(AppConstants.dir10k_Words)/\(name)", name)
            }
        }
        return nil
    }

    /// 向已有 word 文件追加 sample
    nonisolated private static func appendToExistingWord(_ existing: (filePath: String, fileName: String), sample: WordSample, pos: String, word: String) -> Result<(filePath: String, isAppend: Bool), PanelSaveError> {
        let url = URL(fileURLWithPath: existing.filePath)
        guard let data = try? Data(contentsOf: url),
              var model = try? JSONDecoder().decode(NewWordData.self, from: data) else {
            return .failure(PanelSaveError(message: "读取已有文件失败: \(existing.fileName)"))
        }
        model.sample.append(sample)
        guard let jsonData = try? encoder.encode(model) else {
            return .failure(PanelSaveError(message: "JSON 编码失败"))
        }
        let fm = FileManager.default
        do {
            try jsonData.write(to: url, options: .atomic)
            print("[Save] append: \(existing.filePath)")
            return .success((existing.filePath, true))
        } catch {
            return .failure(PanelSaveError(message: "追加写入失败: \(error.localizedDescription)"))
        }
    }

    nonisolated private static func saveNewZh2En(_ data: Zh2EnPanelData, url: String, time: String) -> Result<(filePath: String, isAppend: Bool), PanelSaveError> {
        let zh = data.zh.trimmingCharacters(in: .whitespaces)
        let en = data.en.trimmingCharacters(in: .whitespaces)
        let example = data.sampleSentence.trimmingCharacters(in: .whitespaces)

        guard !zh.isEmpty, !en.isEmpty, !example.isEmpty else {
            return .failure(PanelSaveError(message: "zh/en/example 不能为空"))
        }

        let model = NewZh2EnData(zh: zh, en: en, example: example, time: time, url: url, version: 1)

        guard let jsonData = try? encoder.encode(model) else {
            return .failure(PanelSaveError(message: "JSON 编码失败"))
        }

        let fileNumber = nextFileNumber(in: AppConstants.dir10k_Zh2En)
        let fileName = "\(fileNumber)_\(zh).json"
        let filePath = "\(AppConstants.dir10k_Zh2En)/\(fileName)"

        return writeJSON(jsonData, to: filePath, fileName: fileName).map { ($0, false) }
    }

    // MARK: New Group

    nonisolated private static func saveNewGroup(_ data: GroupPanelData, url: String, time: String) -> Result<(filePath: String, isAppend: Bool), PanelSaveError> {
        let groups = data.groups.trimmingCharacters(in: .whitespaces)
        let example = data.sampleSentence.trimmingCharacters(in: .whitespaces)

        guard !groups.isEmpty, !example.isEmpty else {
            return .failure(PanelSaveError(message: "groups/example 不能为空"))
        }

        let model = NewGroupData(groups: groups, example: example, time: time, url: url, version: 1)

        guard let jsonData = try? encoder.encode(model) else {
            return .failure(PanelSaveError(message: "JSON 编码失败"))
        }

        let fileNumber = nextFileNumber(in: AppConstants.dir10k_InGroup)
        let fileName = "\(fileNumber)_\(groups).json"
        let filePath = "\(AppConstants.dir10k_InGroup)/\(fileName)"

        return writeJSON(jsonData, to: filePath, fileName: fileName).map { ($0, false) }
    }

    // MARK: 文件工具

    nonisolated private static func nextFileNumber(in dir: String) -> Int {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: dir) else { return 1 }
        return contents.count + 1
    }

    nonisolated private static func writeJSON(_ data: Data, to filePath: String, fileName: String) -> Result<String, PanelSaveError> {
        let fm = FileManager.default
        let dir = (filePath as NSString).deletingLastPathComponent
        do {
            try fm.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return .failure(PanelSaveError(message: "创建目录失败: \(error.localizedDescription)"))
        }
        if fm.fileExists(atPath: filePath) {
            return .failure(PanelSaveError(message: "已存在文件: \(fileName)"))
        }
        do {
            try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
            print("[Save] Write succeeded: \(filePath)")
            return .success(filePath)
        } catch {
            return .failure(PanelSaveError(message: "写入失败: \(error.localizedDescription)"))
        }
    }

    /// 加载学习数据，读取文章 JSON 并提取当前句子。
    /// 返回 false 表示加载失败（文章 JSON 不存在/解析失败，或已学习完毕）。
    func load(learningData: CurrentLearningData) -> Bool {
        self.learningData = learningData
        self.currentIndex = learningData.index
        guard let article = Self.loadArticle(at: learningData.filePath) else {
            print("[LearningManager] Failed to load article: \(learningData.filePath)")
            return false
        }
        self.article = article
        self.currentSentence = Self.extractSentence(
            from: article.content,
            startIndex: currentIndex
        )
        // 单词学习区，默认添加一个  NeewWordPanel 和一个 NewZh2EnPanel
        self.panels = [.word(WordPanelData()), .zh2en(Zh2EnPanelData())]
        return true
    }

    /// 保存当前学习进度（index）到 currentLearning.json。
    func saveCurrentProgress() {
        guard var data = learningData else { return }
        data = CurrentLearningData(
            filePath: data.filePath,
            md5: data.md5,
            index: currentIndex,
            contentLength: data.contentLength
        )
        let snapshot = data
        Task.detached(priority: .background) {
            Self.writeCurrentLearning(snapshot)
        }
    }

    /// 推进到下一句。跳过纯换行/空白句，直到找到真正内容或到达末尾。
    func nextSentence() {
        guard let article else { return }
        guard let current = currentSentence, !current.isEmpty else { return }

        currentIndex += current.count

        var sentence: String
        repeat {
            sentence = Self.extractSentence(from: article.content, startIndex: currentIndex)
            if sentence.isEmpty { break }
            if sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                currentIndex += sentence.count
            } else {
                break
            }
        } while true

        currentSentence = sentence.isEmpty ? nil : sentence
        print("[Learning] Next sentence, index=\(currentIndex), sentence=<\(currentSentence?.prefix(30) ?? "(empty)")>")
    }

    /// 写入 CurrentLearningData 到磁盘（非隔离，可安全在后台线程调用）。
    nonisolated private static func writeCurrentLearning(_ data: CurrentLearningData) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let learningData = try? encoder.encode(data) else {
            print("[Learning] Failed to encode currentLearning.json")
            return
        }
        let fileManager = FileManager.default
        let dirAppSupport = AppConstants.dirAppSupport
        do {
            try fileManager.createDirectory(atPath: dirAppSupport,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        } catch {
            print("[Learning] Failed to create directory: \(error.localizedDescription)")
            return
        }
        let url = URL(fileURLWithPath: dirAppSupport)
            .appendingPathComponent("currentLearning.json")
        do {
            try learningData.write(to: url, options: NSData.WritingOptions.atomic)
        } catch {
            print("[Learning] Failed to write currentLearning.json: \(error.localizedDescription)")
        }
    }

    // MARK: - 静态工具方法

    /// 读取并解析指定路径的文章 JSON 文件。
    static func loadArticle(at filePath: String) -> ArticleData? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
              let article = try? JSONDecoder().decode(ArticleData.self, from: data) else {
            return nil
        }
        return article
    }

    /// 从 text 中以 startIndex 为起点，提取第一个完整句子。
    /// 分隔符：中文 。！？； / 英文 !?; + 句号 .（非小数上下文）/ 换行 \\n
    /// 连续多个分隔符（如 ...  !!  ??）会一并纳入当前句子。
    ///
    /// ## 测试用例
    ///
    /// 基本：
    ///   "Hello. World"                                    → "Hello."
    ///   "你好。世界"                                       → "你好。"
    ///   "What?? Really"                                   → "What??"
    ///
    /// 小数 vs 句号：
    ///   "32.72 million. Next"                             → "32.72 million."
    ///   "3.14 is pi. Right?"                              → "3.14 is pi."
    ///   "v2.0 released! Now"                              → "v2.0 released!"
    ///   "GDP grew 5.2%. China"                            → "GDP grew 5.2%."   (% 非数字，. 是句号)
    ///
    /// 换行：
    ///   "Line one.\nLine two"                             → "Line one.\n"
    ///
    /// 省略号：
    ///   "Wait... what?"                                   → "Wait..."
    ///
    /// 中文标点：
    ///   "真的吗？不会吧"                                    → "真的吗？"
    ///   "太好了！！真的"                                    → "太好了！！"
    ///
    /// 边缘：
    ///   ""                                                → ""
    ///   "No punctuation at all"                           → "No punctuation at all"
    ///   ".leading dot"                                    → "."
    static func extractSentence(from text: String, startIndex: Int) -> String {
        guard startIndex < text.count else { return "" }

        let start = text.index(text.startIndex, offsetBy: startIndex)
        let remainder = text[start...]

        let digits = CharacterSet.decimalDigits
        let delimiters = CharacterSet(charactersIn: "!?;。！？；\n")
        // "." 单独处理，不放入 delimiters

        var idx = remainder.startIndex
        while idx < remainder.endIndex {
            let ch = remainder[idx]

            if ch == "." {
                // 前后都是数字 → 小数，跳过；否则 → 句子结束
                let isDecimal: Bool = {
                    guard idx > remainder.startIndex else { return false }
                    let prev = remainder[remainder.index(before: idx)]
                    let hasNext = remainder.index(after: idx) < remainder.endIndex
                    let next = hasNext ? remainder[remainder.index(after: idx)] : nil
                    return prev.unicodeScalars.allSatisfy({ digits.contains($0) })
                        && next?.unicodeScalars.allSatisfy({ digits.contains($0) }) == true
                }()
                if isDecimal {
                    idx = remainder.index(after: idx)
                    continue
                }
                break
            }

            if ch.unicodeScalars.allSatisfy({ delimiters.contains($0) }) {
                break
            }

            idx = remainder.index(after: idx)
        }

        if idx >= remainder.endIndex {
            return String(remainder)
        }

        // 吞入当前分隔符
        idx = remainder.index(after: idx)

        // 继续吞入连续分隔符（如 ...  !!  ??）
        let allDelimiters = CharacterSet(charactersIn: ".!?;。！？；\n")
        while idx < remainder.endIndex {
            let nextChar = remainder[idx]
            if nextChar.unicodeScalars.allSatisfy({ allDelimiters.contains($0) }) {
                idx = remainder.index(after: idx)
            } else {
                break
            }
        }

        return String(remainder[..<idx])
    }
}
