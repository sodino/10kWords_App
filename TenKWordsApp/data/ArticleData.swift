import Foundation

/// 文章数据模型。
/// 序列化为文章 JSON 文件，存储在 articles/YYYY.MM/ 目录下。
struct ArticleData: Codable {
    /// 文章类型标识
    let type: String

    /// 数据格式版本号
    let version: Int

    /// 文章标题
    let title: String

    /// 文章来源链接，要求以 http:// 或 https:// 开头
    let url: String

    /// 文章正文内容
    let content: String

    /// 创建时间，格式 yyyy-MM-dd HH:mm:ss
    let time: String
}
