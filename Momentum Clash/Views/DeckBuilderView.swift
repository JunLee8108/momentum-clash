import SwiftUI

/// 덱 빌딩 화면
struct DeckBuilderView: View {
    @Bindable var deckVM: DeckViewModel
    @State private var showDeckList = false

    var body: some View {
        ZStack {
            // 배경
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.14), Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 상단: 덱 현황
                deckStatusBar
                    .padding(.horizontal)
                    .padding(.top, 8)

                // 카드 타입 탭 (몬스터/마법)
                cardTypePicker
                    .padding(.horizontal)
                    .padding(.top, 10)

                // 속성 필터
                attributeFilter
                    .padding(.top, 8)

                // 카드 풀 그리드
                cardPoolGrid
                    .padding(.top, 8)

                Spacer(minLength: 0)

                // 하단: 내 덱 목록 (접기/펼치기)
                deckListSection
            }
        }
    }

    // MARK: - 덱 현황 바

    private var deckStatusBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("덱 빌딩")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("\(deckVM.deck.count)/\(DeckConstants.deckSize)장")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(deckVM.isDeckValid ? .green : .orange)
            }

            Spacer()

            // 몬스터/마법 카운트
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("몬스터")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text("\(deckVM.monsterCount)/\(DeckConstants.monsterLimit)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(deckVM.monsterCount == DeckConstants.monsterLimit ? .green : .white)
                }

                VStack(spacing: 2) {
                    Text("마법")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text("\(deckVM.spellCount)/\(DeckConstants.spellLimit)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(deckVM.spellCount == DeckConstants.spellLimit ? .green : .white)
                }
            }

            Spacer()

            // 초기화 버튼
            Button {
                deckVM.clearDeck()
            } label: {
                Text("초기화")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().stroke(Color.red.opacity(0.5), lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - 카드 타입 피커

    private var cardTypePicker: some View {
        HStack(spacing: 0) {
            ForEach(CardTypeFilter.allCases, id: \.self) { filter in
                Button {
                    deckVM.selectedCardType = filter
                    deckVM.selectedAttribute = nil
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(deckVM.selectedCardType == filter ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            deckVM.selectedCardType == filter
                                ? Color.white.opacity(0.15)
                                : Color.clear
                        )
                }
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - 속성 필터

    private var attributeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // 전체 버튼
                attributeFilterButton(attribute: nil, label: "전체")

                ForEach(Attribute.allCases, id: \.self) { attr in
                    attributeFilterButton(attribute: attr, label: attr.emoji)
                }
            }
            .padding(.horizontal)
        }
    }

    private func attributeFilterButton(attribute: Attribute?, label: String) -> some View {
        let isSelected = deckVM.selectedAttribute == attribute
        return Button {
            deckVM.selectedAttribute = attribute
        } label: {
            Text(label)
                .font(.system(size: 14))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    isSelected
                        ? (attribute?.color ?? Color.white).opacity(0.3)
                        : Color.white.opacity(0.08)
                )
                .foregroundColor(isSelected ? .white : .gray)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        isSelected ? (attribute?.color ?? Color.white).opacity(0.6) : Color.clear,
                        lineWidth: 1
                    )
                )
        }
    }

    // MARK: - 카드 풀 그리드

    private var cardPoolGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 8)
            ], spacing: 8) {
                if deckVM.selectedCardType == .monster {
                    ForEach(deckVM.filteredMonsters, id: \.name) { monster in
                        cardPoolItem(
                            card: .monster(monster),
                            count: deckVM.countInDeck(name: monster.name)
                        ) {
                            deckVM.addMonster(monster)
                        }
                    }
                } else {
                    ForEach(deckVM.filteredSpells, id: \.name) { spell in
                        cardPoolItem(
                            card: .spell(spell),
                            count: deckVM.countInDeck(name: spell.name)
                        ) {
                            deckVM.addSpell(spell)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func cardPoolItem(card: AnyCard, count: Int, onTap: @escaping () -> Void) -> some View {
        let maxed = count >= DeckConstants.sameCardLimit
        let typeMaxed = card.isSpell
            ? deckVM.spellCount >= DeckConstants.spellLimit
            : deckVM.monsterCount >= DeckConstants.monsterLimit

        return ZStack(alignment: .topTrailing) {
            CardView(card: card, isSelected: count > 0)
                .opacity(maxed || typeMaxed ? 0.5 : 1.0)
                .onTapGesture { onTap() }

            // 장수 뱃지
            Text("\(count)/\(DeckConstants.sameCardLimit)")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    Capsule().fill(maxed ? Color.red.opacity(0.8) : Color.blue.opacity(0.8))
                )
                .offset(x: 4, y: -4)
        }
    }

    // MARK: - 내 덱 목록

    private var deckListSection: some View {
        VStack(spacing: 0) {
            // 헤더 (탭하여 접기/펼치기)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDeckList.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showDeckList ? "chevron.down" : "chevron.up")
                        .font(.system(size: 12))
                    Text("내 덱 (\(deckVM.deck.count)장)")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()

                    if deckVM.isDeckValid {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
            }

            if showDeckList {
                deckListContent
            }
        }
    }

    private var deckListContent: some View {
        ScrollView {
            VStack(spacing: 4) {
                if deckVM.deck.isEmpty {
                    Text("카드를 탭하여 덱에 추가하세요")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .padding(.vertical, 20)
                } else {
                    ForEach(deckVM.deckSummary, id: \.name) { entry in
                        deckListRow(entry: entry)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 200)
        .background(Color.black.opacity(0.3))
    }

    private func deckListRow(entry: (name: String, card: AnyCard, count: Int)) -> some View {
        Button {
            deckVM.removeCard(name: entry.name)
        } label: {
            HStack {
                Text(entry.card.attribute.emoji)
                    .font(.system(size: 14))

                Text(entry.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                // 몬스터 CP 표시
                if case .monster(let m) = entry.card {
                    Text("CP:\(m.combatPower)")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                }

                Text("x\(entry.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.cyan)

                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.7))
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
