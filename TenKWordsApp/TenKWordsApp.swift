import SwiftUI

@main
struct TenKWordsApp: App {
    init() {
        print("[App] dirAppSupport = \(AppConstants.dirAppSupport)")
    }

    var body: some Scene {
        Window("10k Words", id: "main") {
            LearningView()
                .frame(minWidth: 600, maxWidth: 600, minHeight: 800, maxHeight: 800)
        }
        .defaultSize(width: 600, height: 800)
        .windowResizability(.contentSize)
        .commands {
            CommandMenu("Article") {
                ArticleMenuButtons()
            }
        }

        Window("New Article", id: "add-article") {
            AddArticleView()
        }
    }
}

struct ArticleMenuButtons: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("New Article") {
            openWindow(id: "add-article")
        }
        Button("Article List") {
            print("Article List clicked")
        }
    }
}
