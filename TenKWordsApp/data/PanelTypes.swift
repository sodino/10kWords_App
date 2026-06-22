import Foundation

// MARK: - 面板数据模型

/// 单词面板数据
struct WordPanelData: Identifiable {
    let id = UUID()
    var word: String = ""
    var partOfSpeech: String = ""
    var enPhonetic: String = ""
    var amPhonetic: String = ""
    var meaning: String = ""
    var sampleSentence: String = ""

    static let partsOfSpeech = ["n", "v", "adj", "adv", "prep", "pron", "conj"]
}

/// 中译英面板数据
struct Zh2EnPanelData: Identifiable {
    let id = UUID()
    var zh: String = ""
    var en: String = ""
    var sampleSentence: String = ""
}

/// 词组面板数据
struct GroupPanelData: Identifiable {
    let id = UUID()
    var groups: String = ""
    var sampleSentence: String = ""
}

// MARK: - 面板类型枚举

enum PanelType: Identifiable {
    case word(WordPanelData)
    case zh2en(Zh2EnPanelData)
    case group(GroupPanelData)

    var id: UUID {
        switch self {
        case .word(let d):   return d.id
        case .zh2en(let d):  return d.id
        case .group(let d):  return d.id
        }
    }

    /// 所有字段 trim 后均为空字符串则为 true
    var isAllEmpty: Bool {
        switch self {
        case .word(let d):
            return d.word.trimmingCharacters(in: .whitespaces).isEmpty
                && d.partOfSpeech.trimmingCharacters(in: .whitespaces).isEmpty
                && d.enPhonetic.trimmingCharacters(in: .whitespaces).isEmpty
                && d.amPhonetic.trimmingCharacters(in: .whitespaces).isEmpty
                && d.meaning.trimmingCharacters(in: .whitespaces).isEmpty
                && d.sampleSentence.trimmingCharacters(in: .whitespaces).isEmpty
        case .zh2en(let d):
            return d.zh.trimmingCharacters(in: .whitespaces).isEmpty
                && d.en.trimmingCharacters(in: .whitespaces).isEmpty
                && d.sampleSentence.trimmingCharacters(in: .whitespaces).isEmpty
        case .group(let d):
            return d.groups.trimmingCharacters(in: .whitespaces).isEmpty
                && d.sampleSentence.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    /// 全空（可忽略）或所有必填字段均已填写时返回 true
    var isSaveable: Bool {
        if isAllEmpty { return true }
        switch self {
        case .word(let d):
            return !d.word.trimmingCharacters(in: .whitespaces).isEmpty
                && !d.enPhonetic.trimmingCharacters(in: .whitespaces).isEmpty
                && !d.amPhonetic.trimmingCharacters(in: .whitespaces).isEmpty
                && !d.partOfSpeech.trimmingCharacters(in: .whitespaces).isEmpty
                && !d.meaning.trimmingCharacters(in: .whitespaces).isEmpty
                && !d.sampleSentence.trimmingCharacters(in: .whitespaces).isEmpty
        case .zh2en(let d):
            return !d.zh.trimmingCharacters(in: .whitespaces).isEmpty
                && !d.en.trimmingCharacters(in: .whitespaces).isEmpty
                && !d.sampleSentence.trimmingCharacters(in: .whitespaces).isEmpty
        case .group(let d):
            return !d.groups.trimmingCharacters(in: .whitespaces).isEmpty
                && !d.sampleSentence.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
}
