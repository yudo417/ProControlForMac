import SwiftUI
import AppKit

/// シンプルなキー入力ビュー（キーボード専用）
/// ⚠️ コントローラーのボタンではなく、キーボードのキーを割り当てます
struct SimpleKeyInput: View {
    @Binding var keyCode: UInt16?
    @State private var isWaitingForKey = false
    @State private var eventMonitor: Any?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                startListening()
            }) {
                HStack {
                    if isWaitingForKey {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.6)
                                .controlSize(.small)
                            Text("⌨️ 登録するキーを押してください")
                                .foregroundColor(.orange)
                        }
                    } else if let code = keyCode {
                        HStack(spacing: 8) {
                            Image(systemName: "keyboard")
                                .foregroundColor(.green)
                            Text(KeyCodeConverter.keyCodeToString(code))
                                .foregroundColor(.primary)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.secondary)
                            Text("キーボードショートカットを追加")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(minWidth: 200, minHeight: 36)
            }
            .buttonStyle(.bordered)
            .disabled(isWaitingForKey)
            
            // ヘルプテキスト
            if isWaitingForKey {
                Text("💡 矢印キー、文字キー、数字キーなど、キーボードのキーを押してください")
                    .font(.caption)
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
