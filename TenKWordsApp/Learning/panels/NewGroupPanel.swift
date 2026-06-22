import SwiftUI

/// New Group 面板 — 词组录入
struct NewGroupPanel: View {
    @Binding var data: GroupPanelData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 第一行：Groups
            HStack {
                Text("Groups").frame(width: 60, alignment: .leading)
                TextField("", text: $data.groups)
                    .textFieldStyle(.roundedBorder)
            }

            // 第二行：Sample Sentence
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
