import SwiftUI

/// New Word 面板 — 单词录入
struct NewWordPanel: View {
    @Binding var data: WordPanelData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 第一行：word + partsOfSpeech
            HStack {
                Text("word").frame(width: 60, alignment: .leading)
                TextField("", text: $data.word)
                    .textFieldStyle(.roundedBorder)
                Text("partsOfSpeech")
                Picker("", selection: $data.partOfSpeech) {
                    Text("").tag("")
                    ForEach(WordPanelData.partsOfSpeech, id: \.self) { pos in
                        Text(pos).tag(pos)
                    }
                }
                .frame(width: 80)
                .focusable()
            }

            // 第二行：en + am
            HStack {
                Text("en").frame(width: 60, alignment: .leading)
                TextField("", text: $data.enPhonetic)
                    .textFieldStyle(.roundedBorder)
                Text("am")
                TextField("", text: $data.amPhonetic)
                    .textFieldStyle(.roundedBorder)
            }

            // 第三行：meaning
            HStack {
                Text("meaning").frame(width: 60, alignment: .leading)
                TextField("", text: $data.meaning)
                    .textFieldStyle(.roundedBorder)
            }

            // 第四行：Sample Sentence
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
