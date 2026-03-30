import SwiftUI

/// 플레이어 패 표시
struct HandView: View {
    let hand: [AnyCard]
    let selectedIndex: Int?
    let canInteract: Bool
    var animatingCardIndex: Int? = nil
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
                    .opacity(animatingCardIndex == index ? 0 : 1)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: HandCardFramePreferenceKey.self,
                                value: [HandCardFramePreference(
                                    index: index,
                                    frame: geo.frame(in: .named("gameBoard"))
                                )]
                            )
                        }
                    )
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
    let onPeek: () -> Void

    @State private var detailCard: FieldCardDetail? = nil

    var body: some View {
        VStack(spacing: 16) {
            Text("카드를 선택하세요")
                .font(.headline)
                .foregroundColor(.white)

            Text("2장 중 1장을 골라 패에 추가합니다")
                .font(.caption)
                .foregroundColor(.gray)

            HStack(spacing: 30) {
                // 카드 1
                VStack(spacing: 6) {
                    CardView(card: choice1) {
                        onSelect(choice1, choice2)
                    }
                    Button {
                        detailCard = FieldCardDetail(card: choice1)
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }

                Text("OR")
                    .font(.title3)
                    .foregroundColor(.gray)

                // 카드 2
                VStack(spacing: 6) {
                    CardView(card: choice2) {
                        onSelect(choice2, choice1)
                    }
                    Button {
                        detailCard = FieldCardDetail(card: choice2)
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
            }

            Button {
                onPeek()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "eye")
                        .font(.system(size: 13))
                    Text("전장 확인")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
        )
        .sheet(item: $detailCard) { detail in
            FieldCardDetailView(card: detail.card)
        }
    }
}
