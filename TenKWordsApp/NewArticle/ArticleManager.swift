import Foundation
import CryptoKit

enum ArticleSaveError: Error, LocalizedError {
    case invalidJSON
    case serializationFailed
    case createDirectoryFailed(String)
    case writeFileFailed(String)
    case fileExists(String)

    var errorDescription: String? {
        switch self {
        case .invalidJSON: return "JSON 数据无效"
        case .serializationFailed: return "JSON 序列化失败"
        case .createDirectoryFailed(let msg): return "创建目录失败: \(msg)"
        case .writeFileFailed(let msg): return "写入文件失败: \(msg)"
        case .fileExists(let path): return "存在同名文件 (\(path))"
        }
    }
}

@MainActor
class ArticleManager: ObservableObject {
    @Published var isSaving = false
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastIsError = false

    func reset() {
        showToast = false
        toastMessage = ""
        toastIsError = false
    }

    func save(title: String, link: String, content: String,
              onSuccess: @escaping () -> Void) {
        isSaving = true
        let titleCopy = title
        Task {
            let result = await performSave(title: titleCopy, link: link, content: content)
            switch result {
            case .success:
                print("[Save] Article saved successfully")
                NotificationCenter.default.post(name: AppConstants.articleSavedNotification, object: nil)
                toastMessage = "保存成功"
                toastIsError = false
                showToast = true
                print("[Toast] Show: \(toastMessage)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showToast = false
                    print("[Toast] Hide")
                    self.isSaving = false
                    onSuccess()
                }
            case .failure(let error):
                isSaving = false
                toastMessage = error.localizedDescription
                toastIsError = true
                showToast = true
                print("[Toast] Show: \(toastMessage)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showToast = false
                    print("[Toast] Hide")
                }
            }
        }
    }

    private func performSave(title: String, link: String, content: String) async -> Result<Void, ArticleSaveError> {
        return await Task.detached(priority: .background) {
            // 1. 保存文章 JSON
            let saveResult = self.saveArticle(title: title, link: link, content: content)
            switch saveResult {
            case .failure(let error):
                return .failure(error)
            case .success(let (filePath, jsonString)):
                // 2. git add + commit
                let fileName = (filePath as NSString).lastPathComponent
                GitUtil.add(filePath: filePath)
                GitUtil.commit(message: "[dev] add article '\(fileName)'")
                // 3. 写入 currentLearning.json
                self.saveCurrentLearning(filePath: filePath, jsonString: jsonString, contentLength: content.count)
                return .success(())
            }
        }.value
    }

    // MARK: - Step 1: 保存文章 JSON

    nonisolated private func saveArticle(title: String, link: String, content: String) -> Result<(filePath: String, jsonString: String), ArticleSaveError> {
        print("[Save] Step1 saveArticle start: title=\(title)")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let time = dateFormatter.string(from: Date())

        let article = ArticleData(
            type: AppConstants.TYPE_ARTICLE,
            version: AppConstants.VERSION_ARTICLE,
            title: title,
            url: link,
            content: content,
            time: time
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let jsonData = try? encoder.encode(article),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return .failure(.serializationFailed)
        }

        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let month = calendar.component(.month, from: Date())
        let dirArticlesMonth = "\(AppConstants.dir10k_Articles)/\(year).\(String(format: "%02d", month))"

        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(atPath: dirArticlesMonth,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        } catch {
            return .failure(.createDirectoryFailed(error.localizedDescription))
        }

        let fileName = "\(title).json"
        let filePath = "\(dirArticlesMonth)/\(fileName)"

        if fileManager.fileExists(atPath: filePath) {
            print("[Save] Step1 failed: file exists \(filePath)")
            return .failure(.fileExists(filePath))
        }

        do {
            try jsonString.write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("[Save] Step1 write failed: \(error.localizedDescription)")
            return .failure(.writeFileFailed(error.localizedDescription))
        }

        print("[Save] Step1 completed: \(filePath)")
        return .success((filePath, jsonString))
    }

    // MARK: - Step 2: 写入 currentLearning.json

    nonisolated private func saveCurrentLearning(filePath: String, jsonString: String, contentLength: Int) {
        print("[Save] Step2 saveCurrentLearning start: filePath=\(filePath)")
        let md5 = Insecure.MD5.hash(data: Data(jsonString.utf8))
            .map { String(format: "%02x", $0) }.joined()

        let learning = CurrentLearningData(filePath: filePath, md5: md5, index: 0, contentLength: contentLength)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let learningData = try? encoder.encode(learning) else {
            print("[Save] Step2 failed: JSON encoding failed")
            return
        }

        let dirAppSupport = AppConstants.dirAppSupport
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(atPath: dirAppSupport,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        } catch {
            print("[currentLearning] Failed to create directory: \(error.localizedDescription)")
            return
        }

        let learningFileURL = URL(fileURLWithPath: dirAppSupport)
            .appendingPathComponent("currentLearning.json")
        do {
            try learningData.write(to: learningFileURL, options: NSData.WritingOptions.atomic)
            print("[Save] Step2 completed: \(learningFileURL.path)")
        } catch {
            print("[Save] Step2 failed: \(error.localizedDescription)")
        }
    }
}
