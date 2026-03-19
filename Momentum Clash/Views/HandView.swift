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
    let onSelect: (AnyCard, AnyCard) -> Void

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
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
        )
    }
}
