import Foundation

/// New Group 面板序列化结构
struct NewGroupData: Codable {
    let groups: String
    let example: String
    let time: String
    let url: String
    let version: Int
}
