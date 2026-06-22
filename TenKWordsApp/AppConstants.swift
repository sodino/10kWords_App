import Foundation

enum AppConstants {
    // 10000Words 远端git项目在本地的clone路径。
    static let dir_Git10000Words = "/Users/sodino/AndroidProject/10000Words"
    static let dir10k_Articles = "\(dir_Git10000Words)/articles"
    static let dir10k_InGroup = "\(dir_Git10000Words)/inGroup"
    static let dir10k_Words = "\(dir_Git10000Words)/words"
    static let dir10k_Zh2En = "\(dir_Git10000Words)/zh2en"


    static let TYPE_ARTICLE = "10k MacOS App Article"
    static let VERSION_ARTICLE = 2

    static let dirAppSupport: String = {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("TenKWordsApp").path
    }()

    static let articleSavedNotification = Notification.Name("ArticleSaved")
}
