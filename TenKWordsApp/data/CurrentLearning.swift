import Foundation

/// 当前学习状态模型。
/// 序列化为 currentLearning.json，存储在 Application Support 目录下，
/// 用于 App 重启后恢复学习进度。
struct CurrentLearningData: Codable {
    /// 当前学习文章的 JSON 文件绝对路径
    let filePath: String

    /// 文章 JSON 内容的 MD5 哈希值（32位小写十六进制）。
    /// 读取时用于校验文件是否被外部修改。
    let md5: String

    /// 当前学习进度：已处理的 content 字符数。
    /// 新建文章时初始化为 0。
    let index: Int

    /// 文章 content 的字符串总长度。
    /// 当 index == contentLength 时，表示文章已学习完毕。
    let contentLength: Int

    /// 从 Application Support 目录读取并解析 currentLearning.json。
    /// 文件不存在或解析失败时返回 nil。
    static func loadFromAppSupport() -> CurrentLearningData? {
        let url = URL(fileURLWithPath: AppConstants.dirAppSupport)
            .appendingPathComponent("currentLearning.json")
        guard let data = try? Data(contentsOf: url),
              let learning = try? JSONDecoder().decode(CurrentLearningData.self, from: data) else {
            return nil
        }
        return learning
    }
}
