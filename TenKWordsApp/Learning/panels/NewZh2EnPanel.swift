import SwiftUI

/// New zh2en 面板 — 中译英录入
struct NewZh2EnPanel: View {
    @Binding var data: Zh2EnPanelData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 第一行：zh
            HStack {
                Text("zh").frame(width: 60, alignment: .leading)
                TextField("", text: $data.zh)
                    .textFieldStyle(.roundedBorder)
            }

            // 第二行：en
            HStack {
                Text("en").frame(width: 60, alignment: .leading)
                TextField("", text: $data.en)
                    .textFieldStyle(.roundedBorder)
            }

            // 第三行：Sample Sentence
            TextEditor(text: $data.sampleSentence)
                .font(.body)
                .frame(minHeight: 80)
                .overlay(alignment: .topLeading) {
                    if data.sampleSentence.isEmpty {
                        Text("Sample Sentence")
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}
