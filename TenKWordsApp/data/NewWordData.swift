import Foundation

/// New Word 面板保存时的例句条目
struct WordSample: Codable {
    let partsOfSpeech: String
    let meaning: String
    let exampleSentence: String
    let time: String
    let url: String

    enum CodingKeys: String, CodingKey {
        case partsOfSpeech, meaning, exampleSentence, time, url
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(partsOfSpeech, forKey: .partsOfSpeech)
        try container.encode(meaning, forKey: .meaning)
        try container.encode(exampleSentence, forKey: .exampleSentence)
        try container.encode(time, forKey: .time)
        try container.encode(url, forKey: .url)
    }
}

/// New Word 面板序列化结构
struct NewWordData: Codable {
    let word: String
    let phoneticSymbolEn: String
    let phoneticSymbolAm: String
    var sample: [WordSample]
    let version: Int

    enum CodingKeys: String, CodingKey {
        case word, phoneticSymbolEn, phoneticSymbolAm, sample, version
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(word, forKey: .word)
        try container.encode(phoneticSymbolEn, forKey: .phoneticSymbolEn)
        try container.encode(phoneticSymbolAm, forKey: .phoneticSymbolAm)
        try container.encode(sample, forKey: .sample)
        try container.encode(version, forKey: .version)
    }
}
