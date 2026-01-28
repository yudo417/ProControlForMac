import SwiftUI
import AppKit

/// シンプルなキー入力ビュー（キーボード専用）
/// ⚠️ コントローラーのボタンではなく、キーボードのキーを割り当てます
struct SimpleKeyInput: View {
    @Binding var keyCode: UInt16?
    @State private var isWaitingForKey = false
    @State private var eventMonitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                startListening()
            }) {
                ZStack {
                    // TextField風の背景と枠
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(NSColor.textBackgroundColor))
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(
                            isWaitingForKey
                            ? Color.accentColor
                            : Color.secondary.opacity(0.4),
                            lineWidth: isWaitingForKey ? 1.5 : 1
                        )

                    HStack(spacing: 8) {
                        Image(systemName: "keyboard")
                            .foregroundColor(
                                isWaitingForKey ? .accentColor : .secondary
                            )

                        if isWaitingForKey {
                            Text("キーを押してください…")
                                .foregroundColor(.accentColor)

                            Spacer(minLength: 0)

                            ProgressView()
                                .controlSize(.small)
                        } else if let code = keyCode {
                            Text(KeyCodeConverter.keyCodeToString(code))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        } else {
                            Text("キーボードショートカットを追加")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(minWidth: 220, minHeight: 28)
            }
            .buttonStyle(.plain)
            .disabled(isWaitingForKey)

            if isWaitingForKey {
                Text("割り当てたいキーを押してください（修飾キー単体は無視されます）。")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onDisappear {
            stopListening()
        }
    }

    private func startListening() {
        // 既存のモニターがあれば削除
        stopListening()

        isWaitingForKey = true

        // キーイベントモニターを開始
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            if self.isWaitingForKey {
                let code = UInt16(event.keyCode)

                // 修飾キー単体は無視
                if ![55, 56, 58, 59, 60, 61, 62, 63].contains(code) {
                    DispatchQueue.main.async {
                        self.keyCode = code
                        self.stopListening()
                        print("✅ キー検出: \(KeyCodeConverter.keyCodeToString(code)) (code: \(code))")
                    }
                }
                return nil // イベントを消費
            }
            return event
        }

        // 3秒後に自動キャンセル
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.isWaitingForKey {
                self.stopListening()
                print("⏱️ キー入力タイムアウト")
            }
        }
    }

    private func stopListening() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        isWaitingForKey = false
    }
}
