import SwiftUI

/// 덱 빌딩 화면
struct DeckBuilderView: View {
    @Bindable var deckVM: DeckViewModel
    @State private var showDeckList = false
    @State private var selectedCard: AnyCard? = nil
    @State private var showPresetSheet = false
    @State private var showSavedDeckSheet = false

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
                    .padding(.top, 20)

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
                    .padding(.bottom, 4)

                // 하단: 내 덱 목록 (접기/펼치기)
                deckListSection
            }
        }
        .sheet(isPresented: $showPresetSheet) {
            PresetDeckSheet { preset in
                deckVM.loadPreset(preset)
            }
            .presentationDetents([.medium])
            .presentationBackground(Color(red: 0.06, green: 0.06, blue: 0.14))
        }
        .sheet(isPresented: $showSavedDeckSheet) {
            SavedDeckSheet(
                currentDeck: deckVM.deck,
                isDeckValid: deckVM.isDeckValid
            ) { cards in
                deckVM.deck = cards
            }
            .presentationDetents([.medium, .large])
            .presentationBackground(Color(red: 0.06, green: 0.06, blue: 0.14))
        }
        .fullScreenCover(item: $selectedCard) { card in
            DeckCardDetailView(
                card: card,
                currentCount: deckVM.countInDeck(name: card.name),
                canAdd: deckVM.canAdd(card: card)
            ) {
                selectedCard = nil
            } onAdd: {
                switch card {
                case .monster(let m): deckVM.addMonster(m)
                case .spell(let s): deckVM.addSpell(s)
                }
                selectedCard = nil
            }
        }
    }

    // MARK: - 덱 현황 바

    private var deckStatusBar: some View {
        HStack {
            Text("덱 빌딩")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            // 프리셋 버튼
            Button {
                showPresetSheet = true
            } label: {
                Text("프리셋")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().stroke(Color.orange.opacity(0.5), lineWidth: 1)
                    )
            }

            // 나의 덱 버튼
            Button {
                showSavedDeckSheet = true
            } label: {
                Text("나의 덱")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                    )
            }

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
                let isSelected = deckVM.selectedCardType == filter
                let count = filter == .monster ? deckVM.monsterCount : deckVM.spellCount
                let limit = filter == .monster ? DeckConstants.monsterLimit : DeckConstants.spellLimit
                let isFull = count == limit

                Button {
                    deckVM.selectedCardType = filter
                    deckVM.selectedAttribute = nil
                } label: {
                    HStack(spacing: 4) {
                        Text(filter.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isSelected ? .white : .gray)
                        Text("\(count)/\(limit)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(isFull ? .green : (isSelected ? .white.opacity(0.7) : .gray.opacity(0.6)))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        isSelected
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
                            selectedCard = .monster(monster)
                        }
                    }
                } else {
                    ForEach(deckVM.filteredSpells, id: \.name) { spell in
                        cardPoolItem(
                            card: .spell(spell),
                            count: deckVM.countInDeck(name: spell.name)
                        ) {
                            selectedCard = .spell(spell)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
    }

    private func cardPoolItem(card: AnyCard, count: Int, onTap: @escaping () -> Void) -> some View {
        // 5성 몬스터는 per-card 제한도 2장
        let effectiveLimit: Int = {
            if case .monster(let m) = card, m.cost >= DeckConstants.highCostThreshold {
                return DeckConstants.highCostLimit
            }
            return DeckConstants.sameCardLimit
        }()
        let maxed = count >= effectiveLimit
        let typeMaxed = card.isSpell
            ? deckVM.spellCount >= DeckConstants.spellLimit
            : deckVM.monsterCount >= DeckConstants.monsterLimit
        // ★5 몬스터 총량 제한 체크
        let highCostMaxed: Bool = {
            if case .monster(let m) = card,
               m.cost >= DeckConstants.highCostThreshold,
               deckVM.highCostCount >= DeckConstants.highCostLimit {
                return true
            }
            return false
        }()
        let canAdd = !maxed && !typeMaxed && !highCostMaxed && deckVM.deck.count < DeckConstants.deckSize

        return VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                CardView(card: card, isSelected: count > 0, onTap: onTap)
                    .opacity(canAdd ? 1.0 : 0.5)

                // 장수 뱃지
                Text("\(count)/\(effectiveLimit)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(maxed ? Color.red.opacity(0.8) : Color.blue.opacity(0.8))
                    )
                    .offset(x: 4, y: -4)
            }

            // 인라인 수량 조절 컨트롤
            HStack(spacing: 6) {
                // 마이너스 버튼
                Button {
                    deckVM.removeCard(name: card.name)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(count > 0 ? .red : .gray.opacity(0.3))
                }
                .disabled(count == 0)

                // 현재 수량
                Text("\(count)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(count > 0 ? .cyan : .gray)
                    .frame(minWidth: 16)

                // 플러스 버튼
                Button {
                    switch card {
                    case .monster(let m): deckVM.addMonster(m)
                    case .spell(let s): deckVM.addSpell(s)
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(canAdd ? .green : .gray.opacity(0.3))
                }
                .disabled(!canAdd)
            }
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
