import SwiftUI

/// 플레이어 패 표시
struct HandView: View {
    let hand: [AnyCard]
    let selectedIndex: Int?
    let canInteract: Bool
    var onCardTap: ((Int) -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(hand.enumerated()), id: \.element.id) { index, card in
                    CardView(
                        card: card,
                        isSelected: selectedIndex == index,
                        isSmall: true
                    ) {
                        if canInteract {
                            onCardTap?(index)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 110)
    }
}

/// 선택 드로우 뷰
struct DrawSelectionView: View {
    let choice1: AnyCard
    let choice2: AnyCard
    let hand: [AnyCard]
    let onSelect: (AnyCard, AnyCard) -> Void

    @State private var showHand = false
    @State private var detailCard: AnyCard?

    var body: some View {
        VStack(spacing: 16) {
            Text("카드를 선택하세요")
                .font(.headline)
                .foregroundColor(.white)

            Text("2장 중 1장을 골라 패에 추가합니다")
                .font(.caption)
                .foregroundColor(.gray)

            HStack(spacing: 30) {
                CardView(card: choice1) {
                    onSelect(choice1, choice2)
                }

                Text("OR")
                    .font(.title3)
                    .foregroundColor(.gray)

                CardView(card: choice2) {
                    onSelect(choice2, choice1)
                }
            }

            // 내 패 보기 버튼
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showHand.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showHand ? "chevron.up" : "hand.raised")
                        .font(.system(size: 12))
                    Text("내 패 보기 (\(hand.count)장)")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                )
            }

            // 현재 패 목록
            if showHand {
                if hand.isEmpty {
                    Text("패에 카드가 없습니다")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Array(hand.enumerated()), id: \.element.id) { _, card in
                                CardView(card: card, isSmall: true) {
                                    detailCard = card
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .frame(height: 110)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
        )
        .fullScreenCover(item: $detailCard) { card in
            FieldCardDetailView(card: card) {
                detailCard = nil
            }
        }
    }
}
