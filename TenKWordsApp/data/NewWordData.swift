import Foundation

/// New Word 面板保存时的例句条目
struct WordSample: Codable {
    let partsOfSpeech: String
    let meaning: String
    let exampleSentence: String
    let time: String
    let url: String
}

/// New Word 面板序列化结构
struct NewWordData: Codable {
    let word: String
    let phoneticSymbolEn: String
    let phoneticSymbolAm: String
    var sample: [WordSample]
    let version: Int
}
