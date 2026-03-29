import SwiftUI

/// 플레이어 정보 표시 (LP, 기세, 기력)
struct PlayerInfoView: View {
    let player: Player
    let isCurrentTurn: Bool
    var isTopPlayer: Bool = false

    @State private var showTooltip = false

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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.3))
        )
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.2)) {
                showTooltip.toggle()
            }
        }
        .overlay(alignment: isTopPlayer ? .bottom : .top) {
            if showTooltip {
                tooltipView
                    .offset(y: isTopPlayer ? 8 : -8)
                    .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: isTopPlayer ? .top : .bottom)))
            }
        }
    }

    // MARK: - 툴팁

    private var tooltipView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(player.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Divider().background(Color.white.opacity(0.3))

            tooltipRow(icon: "heart.fill", color: .red, label: "LP", value: "\(player.lp) / \(TurnSystem.startingLP)")
            tooltipRow(icon: "flame.fill", color: .orange, label: "기세", value: "\(player.momentum)")
            tooltipRow(icon: "bolt.circle.fill", color: .cyan, label: "기력", value: "\(player.energy)")
            tooltipRow(icon: "hand.raised.fill", color: .green, label: "패", value: "\(player.hand.count)장")
            tooltipRow(icon: "square.stack.fill", color: .gray, label: "덱", value: "\(player.deck.count)장")
            tooltipRow(icon: "xmark.bin.fill", color: .purple, label: "묘지", value: "\(player.graveyard.count)장")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    private func tooltipRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
                .frame(width: 16)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 30, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
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
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))

                RoundedRectangle(cornerRadius: 6)
                    .fill(barColor)
                    .frame(width: geo.size.width * ratio)
            }
        }
        .frame(height: 12)
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
