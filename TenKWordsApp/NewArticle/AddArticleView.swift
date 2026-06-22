import SwiftUI

// MARK: - View

struct AddArticleView: View {
    @State private var title: String = ""
    @State private var link: String = ""
    @State private var content: String = ""
    @StateObject private var manager = ArticleManager()
    @Environment(\.dismiss) private var dismiss
    @State private var shakeOffset: CGFloat = 0

    private var linkIsValid: Bool {
        let trimmed = link.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ||
               trimmed.hasPrefix("http://") ||
               trimmed.hasPrefix("https://")
    }

    private var showLinkHint: Bool {
        !link.trimmingCharacters(in: .whitespaces).isEmpty && !linkIsValid
    }

    private var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespaces).isEmpty ||
        link.trimmingCharacters(in: .whitespaces).isEmpty ||
        content.trimmingCharacters(in: .whitespaces).isEmpty ||
        !linkIsValid
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("文章标题")
                    .font(.headline)
                TextField("输入标题", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .disabled(manager.isSaving)

                HStack {
                    Text("链接来源")
                        .font(.headline)
                    if showLinkHint && !manager.isSaving {
                        Text("Start with http:// https://")
                            .foregroundColor(.red)
                            .font(.caption)
                            .offset(x: shakeOffset)
                    }
                    Spacer()
                }
                TextField("输入链接", text: $link)
                    .textFieldStyle(.roundedBorder)
                    .disabled(manager.isSaving)
                    .onChange(of: link) { _, _ in
                        if showLinkHint {
                            let offsets: [CGFloat] = [-8, 8, -6, 6, -3, 3, 0]
                            for (i, offset) in offsets.enumerated() {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                                    withAnimation(.linear(duration: 0.05)) {
                                        shakeOffset = offset
                                    }
                                }
                            }
                        }
                    }

                Text("文章内容")
                    .font(.headline)
                TextEditor(text: $content)
                    .font(.body)
                    .border(Color.gray.opacity(0.3))
                    .disabled(manager.isSaving)

                if manager.isSaving {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Saving...")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Button("保存") {
                        print("[AddArticle] Save button clicked")
                        manager.save(title: title, link: link, content: content) {
                            dismiss()
                        }
                    }
                    .disabled(isSaveDisabled)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .frame(minWidth: 500, minHeight: 600)

            if manager.isSaving {
                Color.white.opacity(0.6)
                    .ignoresSafeArea()
            }

            if manager.showToast {
                VStack {
                    Spacer()
                    Toast(message: manager.toastMessage, isError: manager.toastIsError)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: manager.showToast)
        .onAppear {
            print("[AddArticle] Window opened")
            title = ""
            link = ""
            content = ""
            manager.reset()
        }
        .onDisappear {
            print("[AddArticle] Window closed")
        }
    }
}
