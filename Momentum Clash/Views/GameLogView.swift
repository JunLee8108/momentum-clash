import SwiftUI

/// 게임 로그 표시 뷰
struct GameLogView: View {
    let logs: [GameLog]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(logs) { log in
                        if log.message.isEmpty {
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .id(log.id)
                        } else {
                            Text(log.message)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(logColor(log.message))
                                .id(log.id)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .onChange(of: logs.count) { _, _ in
                if let lastLog = logs.last {
                    withAnimation {
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
        }
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.5))
        )
    }

    private func logColor(_ message: String) -> Color {
        if message.contains("파괴") { return .red }
        if message.contains("승리") { return .yellow }
        if message.contains("LP 데미지") { return .orange }
        if message.contains("소환") { return .green }
        if message.contains("드로우") { return .cyan }
        if message.contains("기세 스킬") { return .purple }
        if message.contains("턴") { return .yellow.opacity(0.8) }
        return .white.opacity(0.8)
    }
}
