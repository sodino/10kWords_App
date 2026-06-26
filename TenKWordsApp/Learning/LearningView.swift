import SwiftUI

struct LearningView: View {
    @Environment(\.openWindow) private var openWindow
    @StateObject private var manager = LearningManager()

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if let _ = manager.currentSentence, !(manager.currentSentence?.isEmpty ?? true) {
                    learningContentView
                } else {
                    emptyContentView
                }
            }

            // 保存 Toast
            if let msg = manager.saveToastMessage {
                VStack {
                    Spacer()
                    Toast(message: msg, isError: manager.saveToastIsError)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            if let data = CurrentLearningData.loadFromAppSupport() {
                if !manager.load(learningData: data) {
                    print("[Startup] Article completed or failed to load, opening Add Article window")
                    openWindow(id: "add-article")
                }
            } else {
                print("[Startup] currentLearning.json not found, opening Add Article window")
                openWindow(id: "add-article")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppConstants.articleSavedNotification)) { _ in
            print("[Learning] Received article saved notification, reloading")
            if let data = CurrentLearningData.loadFromAppSupport() {
                _ = manager.load(learningData: data)
            }
        }
    }

    // MARK: - 空状态

    private var emptyContentView: some View {
        VStack {
            Spacer()
            Text("10000 Words")
                .font(.largeTitle)
                .foregroundColor(.black)
            Spacer()
        }
    }

    // MARK: - 学习内容

    private var learningContentView: some View {
        VStack(spacing: 0) {
            // 文章标题（可点击跳转）
            if let title = manager.article?.title {
                titleView(title)
            }

            Divider().padding(.horizontal)

            // 当前句子
            if let sentence = manager.currentSentence {
                HStack(alignment: .center, spacing: 8) {
                    Text(sentence)
                        .font(.body)
                        .foregroundColor(.black)
                        .textSelection(.enabled)

                    Spacer()

                    Button {
                        manager.nextSentence()
                        manager.saveCurrentProgress()
                    } label: {
                        Text("→")
                            .font(.title2)
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Divider().padding(.horizontal)

            // 单词学习区（可滚动）
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(manager.panels) { panel in
                        panelView(for: panel)
                            .disabled(manager.isSaving)
                    }
                }
                .padding()
            }

            Divider()

            // 底部按钮栏（固定）
            bottomActionBar
        }
    }

    // MARK: - 标题

    private func titleView(_ title: String) -> some View {
        Group {
            if let urlString = manager.article?.url, let url = URL(string: urlString) {
                Link(title, destination: url)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
            } else {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
            }
        }
    }

    // MARK: - 面板

    @ViewBuilder
    private func panelView(for panel: PanelType) -> some View {
        switch panel {
        case .word(let data):
            NewWordPanel(data: wordBinding(for: panel, fallback: data))
        case .zh2en(let data):
            NewZh2EnPanel(data: zh2enBinding(for: panel, fallback: data))
        case .group(let data):
            NewGroupPanel(data: groupBinding(for: panel, fallback: data))
        }
    }

    private func wordBinding(for panel: PanelType, fallback: WordPanelData) -> Binding<WordPanelData> {
        Binding<WordPanelData>(
            get: {
                guard let index = self.manager.panels.firstIndex(where: { $0.id == panel.id }),
                      case .word(let d) = self.manager.panels[index] else { return fallback }
                return d
            },
            set: {
                guard let index = self.manager.panels.firstIndex(where: { $0.id == panel.id }) else { return }
                self.manager.panels[index] = .word($0)
            }
        )
    }

    private func zh2enBinding(for panel: PanelType, fallback: Zh2EnPanelData) -> Binding<Zh2EnPanelData> {
        Binding<Zh2EnPanelData>(
            get: {
                guard let index = self.manager.panels.firstIndex(where: { $0.id == panel.id }),
                      case .zh2en(let d) = self.manager.panels[index] else { return fallback }
                return d
            },
            set: {
                guard let index = self.manager.panels.firstIndex(where: { $0.id == panel.id }) else { return }
                self.manager.panels[index] = .zh2en($0)
            }
        )
    }

    private func groupBinding(for panel: PanelType, fallback: GroupPanelData) -> Binding<GroupPanelData> {
        Binding<GroupPanelData>(
            get: {
                guard let index = self.manager.panels.firstIndex(where: { $0.id == panel.id }),
                      case .group(let d) = self.manager.panels[index] else { return fallback }
                return d
            },
            set: {
                guard let index = self.manager.panels.firstIndex(where: { $0.id == panel.id }) else { return }
                self.manager.panels[index] = .group($0)
            }
        )
    }

    // MARK: - 底部按钮栏

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            if manager.isSaving {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Saving...")
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                HStack(spacing: 0) {
                    Spacer()
                    Button("New Word") { manager.addWordPanel() }
                    Spacer()
                    Button("New zh2en") { manager.addZh2EnPanel() }
                    Spacer()
                    Button("New Group") { manager.addGroupPanel() }
                    Spacer()
                }
                .padding(.vertical, 6)

                Divider()

                Button {
                    manager.saveAllPanels()
                } label: {
                    Text("Save All")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!manager.isSavable)
                .padding(.vertical, 6)
            }
        }
        .background(Color.white)
    }
}
