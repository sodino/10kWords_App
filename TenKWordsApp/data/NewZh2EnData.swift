import Foundation

/// New zh2en 面板序列化结构
struct NewZh2EnData: Codable {
    let zh: String
    let en: String
    let example: String
    let time: String
    let url: String
    let version: Int
}
