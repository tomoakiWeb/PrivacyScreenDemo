import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var showAlert = false
    @State private var inputText = ""
    @State private var isSuppressing = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("残高", value: "¥123,456")
                    LabeledContent("カード番号") {
                        Text("1234 1234 1234 1234")
                            .privacySensitive()
                    }
                    LabeledContent("氏名", value: "山田 太郎")
                }
                .font(.body.monospacedDigit())
                
                Section {
                    TextField("テキストを入力", text: $inputText)
                }
                
                Section {
                    Toggle("プライバシー画面を表示しない", isOn: $isSuppressing)
                        .onChange(of: isSuppressing) { _, newValue in
                            PrivacyScreenSuppression.setSuppressed(newValue)
                        }
                } footer: {
                    Text("ONにするとバックグラウンド遷移時にプライバシー画面が表示されません。")
                }
                
                Section {
                    Button("カメラへのアクセスを許可") {
                        Task {
                            await PrivacyScreenSuppression.suppress(during: {
                                _ = await AVCaptureDevice.requestAccess(for: .video)
                            })
                        }
                    }
                    Button("アラートを表示") {
                        showAlert = true
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("サンプル")
            .alert("確認", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("アラートのメッセージです。")
            }
        }
    }
}

#Preview {
    ContentView()
}
