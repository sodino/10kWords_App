import Foundation

/// New zh2en 面板序列化结构
struct NewZh2EnData: Codable {
    let zh: String
    let en: String
    let exampleSentence: String
    let time: String
    let url: String
    let version: Int

    enum CodingKeys: String, CodingKey {
        case zh, en, exampleSentence, time, url, version
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(zh, forKey: .zh)
        try container.encode(en, forKey: .en)
        try container.encode(exampleSentence, forKey: .exampleSentence)
        try container.encode(time, forKey: .time)
        try container.encode(url, forKey: .url)
        try container.encode(version, forKey: .version)
    }
}
