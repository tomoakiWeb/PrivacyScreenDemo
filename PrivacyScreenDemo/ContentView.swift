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
                    LabeledContent("Balance") {
                        Text("$1,234.56")
                    }
                    .privacySensitive()
                    LabeledContent("Card Number") {
                        Text(verbatim: "1234 1234 1234 1234")
                            .privacySensitive()
                    }
                    LabeledContent("Name") {
                        Text("John Appleseed")
                    }
                }
                .font(.body.monospacedDigit())
                
                Section {
                    TextField("Enter text", text: $inputText)
                }
                
                Section {
                    Toggle("Disable Privacy Screen", isOn: $isSuppressing)
                        .onChange(of: isSuppressing) { _, newValue in
                            PrivacyScreenSuppression.setSuppressed(newValue)
                        }
                } footer: {
                    Text("When enabled, the privacy screen will not be shown when the app moves to the background.")
                }
                
                Section {
                    Button("Allow Camera Access") {
                        Task {
                            await PrivacyScreenSuppression.suppress(during: {
                                _ = await AVCaptureDevice.requestAccess(for: .video)
                            })
                        }
                    }
                    Button("Show Alert") {
                        showAlert = true
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Sample")
            .alert("Confirmation", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This is an alert message.")
            }
        }
    }
}

#Preview {
    ContentView()
}
