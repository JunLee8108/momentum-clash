import SwiftUI

/// 플레이어 정보 표시 (LP, 기세, 기력)
struct PlayerInfoView: View {
    let player: Player
    let isCurrentTurn: Bool

    var body: some View {
        HStack(spacing: 12) {
            // 이름
            Text(player.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isCurrentTurn ? .yellow : .white)

            Spacer()

            // LP
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.red)
                Text("\(player.lp)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(lpColor)
            }

            // 기세
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
                Text("\(player.momentum)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
            }

            // 기력
            HStack(spacing: 4) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.cyan)
                Text("\(player.energy)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
            }

            // 덱 잔량
            HStack(spacing: 2) {
                Image(systemName: "square.stack.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                Text("\(player.deck.count)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
        )
    }

    private var lpColor: Color {
        let ratio = Double(player.lp) / Double(TurnSystem.startingLP)
        if ratio <= 0.25 { return .red }
        if ratio <= 0.5 { return .orange }
        return .white
    }
}

/// LP 바
struct LPBarView: View {
    let current: Int
    let max: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.3))

                RoundedRectangle(cornerRadius: 3)
                    .fill(barColor)
                    .frame(width: geo.size.width * ratio)
            }
        }
        .frame(height: 6)
    }

    private var ratio: CGFloat {
        CGFloat(current) / CGFloat(max)
    }

    private var barColor: Color {
        if ratio <= 0.25 { return .red }
        if ratio <= 0.5 { return .orange }
        return .green
    }
}
