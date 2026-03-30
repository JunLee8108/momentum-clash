import SwiftUI

// MARK: - 필드 슬롯 좌표 수집용 PreferenceKey

struct SlotFramePreference: Equatable {
    let index: Int
    let isOpponent: Bool
    let frame: CGRect
}

struct SlotFramePreferenceKey: PreferenceKey {
    static var defaultValue: [SlotFramePreference] = []
    static func reduce(value: inout [SlotFramePreference], nextValue: () -> [SlotFramePreference]) {
        value.append(contentsOf: nextValue())
    }
}

struct HandCenterPreference: Equatable {
    let isPlayer: Bool
    let center: CGPoint
}

struct HandCenterPreferenceKey: PreferenceKey {
    static var defaultValue: [HandCenterPreference] = []
    static func reduce(value: inout [HandCenterPreference], nextValue: () -> [HandCenterPreference]) {
        value.append(contentsOf: nextValue())
    }
}

struct HandCardFramePreference: Equatable {
    let index: Int
    let frame: CGRect
}

struct HandCardFramePreferenceKey: PreferenceKey {
    static var defaultValue: [HandCardFramePreference] = []
    static func reduce(value: inout [HandCardFramePreference], nextValue: () -> [HandCardFramePreference]) {
        value.append(contentsOf: nextValue())
    }
}

/// 메인 게임 보드 뷰
struct GameBoardView: View {
    @Bindable var viewModel: GameViewModel
    var onGoHome: (() -> Void)? = nil
    @State private var showTerrainTooltip = false
    @State private var showMomentumSkillPanel = false
    @State private var isPeekingField = false
    @State private var showPlayerTooltip = false
    @State private var showAITooltip = false

    var body: some View {
        ZStack {
            // 지형 속성 배경
            terrainBackground
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: viewModel.gameState.globalTerrain)

            VStack(spacing: 8) {
                // 상대 (AI) 정보
                PlayerInfoView(
                    player: viewModel.aiPlayer,
                    isCurrentTurn: !viewModel.isPlayerTurn,
                    showTooltip: $showAITooltip
                )
                .padding(.horizontal, 8)
                .zIndex(1)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: HandCenterPreferenceKey.self,
                            value: [HandCenterPreference(
                                isPlayer: false,
                                center: CGPoint(
                                    x: geo.frame(in: .named("gameBoard")).midX,
                                    y: geo.frame(in: .named("gameBoard")).midY
                                )
                            )]
                        )
                    }
                )

                LPBarView(current: viewModel.aiPlayer.lp, max: TurnSystem.startingLP)
                    .padding(.horizontal, 12)

                // 상대 필드
                fieldView(player: viewModel.aiPlayer, isOpponent: true)

                // 구분선 + 지형 인디케이터
                HStack {
                    Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                    terrainIndicator
                    Text("턴 \(viewModel.gameState.turnNumber)")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text(viewModel.gameState.currentPhase.displayName)
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                }
                .padding(.horizontal, 8)

                // 내 필드
                fieldView(player: viewModel.player, isOpponent: false)

                LPBarView(current: viewModel.player.lp, max: TurnSystem.startingLP)
                    .padding(.horizontal, 12)

                // 내 정보
                PlayerInfoView(
                    player: viewModel.player,
                    isCurrentTurn: viewModel.isPlayerTurn,
                    showTooltip: $showPlayerTooltip
                )
                .padding(.horizontal, 8)
                .zIndex(1)

                // 로그
                GameLogView(logs: viewModel.logs)
                    .padding(.horizontal, 8)

                // 내 패
                HandView(
                    hand: viewModel.player.hand,
                    selectedIndex: isPeekingField ? nil : viewModel.selectedHandIndex,
                    canInteract: isPeekingField || (viewModel.isPlayerTurn && viewModel.gameState.currentPhase == .main)
                ) { index in
                    if isPeekingField {
                        // 전장 확인 중: 읽기 전용 상세보기
                        let card = viewModel.player.hand[index]
                        viewModel.showingFieldCardDetail = FieldCardDetail(card: card)
                    } else {
                        viewModel.selectCardFromHand(index)
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: HandCenterPreferenceKey.self,
                            value: [HandCenterPreference(
                                isPlayer: true,
                                center: CGPoint(
                                    x: geo.frame(in: .named("gameBoard")).midX,
                                    y: geo.frame(in: .named("gameBoard")).midY
                                )
                            )]
                        )
                    }
                )

                // 액션 버튼
                actionButtons
            }
            .padding(.vertical, 8)

            // 오버레이: 툴팁 닫기용 투명 배경
            if showPlayerTooltip || showAITooltip {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showPlayerTooltip = false
                            showAITooltip = false
                        }
                    }
            }

            // 오버레이: 드로우 선택
            if case .drawSelection(let c1, let c2) = viewModel.uiState, !isPeekingField {
                Color.black.opacity(0.6).ignoresSafeArea()
                DrawSelectionView(choice1: c1, choice2: c2, onSelect: { chosen, rejected in
                    viewModel.selectDrawCard(chosen, rejected: rejected)
                }, onPeek: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPeekingField = true
                    }
                })
            }

            // 플로팅 버튼: 드로우로 돌아가기
            if case .drawSelection = viewModel.uiState, isPeekingField {
                VStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isPeekingField = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 14, weight: .semibold))
                            Text("드로우로 돌아가기")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.cyan)
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 8, y: 2)
                    }
                    .padding(.bottom, 24)
                }
            }

            // 오버레이: 게임 종료
            if case .gameOver(let winner) = viewModel.uiState {
                Color.black.opacity(0.7).ignoresSafeArea()
                GameResultView(winner: winner) {
                    viewModel.restartGame()
                    viewModel.startGame()
                } onGoHome: {
                    onGoHome?()
                }
            }

            // 오버레이: 전투 배너 (AI턴 + 플레이어 공격 공용)
            if let display = viewModel.battleDisplay {
                VStack {
                    Spacer()
                    Text(display.message)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    display.attackerSlot != nil
                                    ? Color.red.opacity(0.85)
                                    : display.showLPFlash
                                    ? Color.orange.opacity(0.85)
                                    : display.isPlayerAction
                                    ? Color.blue.opacity(0.85)
                                    : Color.black.opacity(0.75)
                                )
                        )
                        .shadow(color: display.attackerSlot != nil ? .red.opacity(0.6) : .clear, radius: 8)
                        .transition(.scale.combined(with: .opacity))
                    Spacer()
                }
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.2), value: viewModel.battleDisplay)
            } else if case .aiTurn = viewModel.uiState {
                // AI 턴이지만 아직 배너가 없을 때
                VStack {
                    Spacer()
                    Text("AI 턴 진행 중...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Capsule().fill(Color.black.opacity(0.6)))
                    Spacer()
                }
                .allowsHitTesting(false)
            }

            // 오버레이: 5성 소환 풀스크린 이펙트
            if let display = viewModel.battleDisplay, let effect = display.summonEffect {
                SummonFullscreenOverlay(effectType: effect)
                    .transition(.opacity)
                    .zIndex(100)
            }

            // 오버레이: 전투 프리뷰
            if let preview = viewModel.combatPreview {
                VStack {
                    Spacer()
                    CombatPreviewView(preview: preview) {
                        viewModel.executeAttack(
                            attackerSlot: preview.attackerSlot,
                            defenderSlot: preview.defenderSlot
                        )
                    } onClose: {
                        viewModel.combatPreview = nil
                    }
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    Spacer().frame(height: 60)
                }
                .animation(.easeOut(duration: 0.2), value: viewModel.combatPreview)
            }

            // 오버레이: 기세 스킬 패널
            if showMomentumSkillPanel, case .mainPhase = viewModel.uiState {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showMomentumSkillPanel = false }

                VStack {
                    Spacer()
                    MomentumSkillPanel(
                        currentMomentum: viewModel.player.momentum
                    ) { skill in
                        viewModel.useMomentumSkill(skill)
                        showMomentumSkillPanel = false
                    } onClose: {
                        showMomentumSkillPanel = false
                    }
                    .padding(.bottom, 80)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeOut(duration: 0.25), value: showMomentumSkillPanel)
            }

            // LP 데미지 플래시
            if let display = viewModel.battleDisplay, display.showLPFlash {
                Color.red.opacity(0.15)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.3), value: display.showLPFlash)
            }

            // 오버레이: 지형 툴팁
            terrainTooltipOverlay

            // (카드 상세보기는 .sheet로 이동)

            // 오버레이: 소환 카드 이동 애니메이션
            if let anim = viewModel.summonAnimation {
                summonCardOverlay(anim: anim)
                    .allowsHitTesting(false)
            }
        }
        .coordinateSpace(name: "gameBoard")
        .onPreferenceChange(SlotFramePreferenceKey.self) { prefs in
            for pref in prefs {
                if pref.isOpponent {
                    viewModel.aiSlotFrames[pref.index] = pref.frame
                } else {
                    viewModel.playerSlotFrames[pref.index] = pref.frame
                }
            }
        }
        .onPreferenceChange(HandCenterPreferenceKey.self) { prefs in
            for pref in prefs {
                if pref.isPlayer {
                    viewModel.playerHandCenter = pref.center
                } else {
                    viewModel.aiHandCenter = pref.center
                }
            }
        }
        .onPreferenceChange(HandCardFramePreferenceKey.self) { prefs in
            var frames: [Int: CGRect] = [:]
            for pref in prefs {
                frames[pref.index] = pref.frame
            }
            viewModel.handCardFrames = frames
        }
        .sheet(item: $viewModel.showingCardDetail, onDismiss: {
            if let action = viewModel.pendingCardAction {
                viewModel.pendingCardAction = nil
                action()
            }
        }) { detail in
            CardDetailView(
                card: detail.card,
                handIndex: detail.handIndex,
                canUse: viewModel.canUseCard(detail.card),
                onUse: { viewModel.useCardFromDetail() }
            )
        }
        .sheet(item: $viewModel.showingFieldCardDetail) { detail in
            FieldCardDetailView(card: detail.card)
        }
    }

    // MARK: - 소환 카드 이동 애니메이션 오버레이

    @ViewBuilder
    private func summonCardOverlay(anim: SummonAnimation) -> some View {
        let slotFrames = anim.isPlayer ? viewModel.playerSlotFrames : viewModel.aiSlotFrames
        let targetFrame = slotFrames[anim.targetSlotIndex] ?? .zero

        let targetCenter = CGPoint(x: targetFrame.midX, y: targetFrame.midY)
        let currentPos = anim.animating ? targetCenter : anim.startPosition

        // 카드 이미지 (실제 카드 이미지 사용)
        let imageName = anim.card.imageName
        let hasImage = UIImage(named: imageName) != nil

        ZStack {
            if hasImage {
                Image(uiImage: UIImage(named: imageName)!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: anim.animating ? 75 : 70, height: anim.animating ? 90 : 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.yellow, lineWidth: 2)
                    )
            } else {
                CardView(card: anim.card, isSmall: true)
                    .scaleEffect(anim.animating ? 0.85 : 1.0)
            }
        }
        .shadow(color: .yellow.opacity(0.6), radius: anim.animating ? 15 : 5)
        .position(currentPos)
        .opacity(anim.animating ? 0.85 : 1.0)
    }

    // MARK: - 지형 배경

    @ViewBuilder
    private var terrainBackground: some View {
        let terrain = viewModel.gameState.globalTerrain
        let colors = terrainGradientColors(for: terrain)

        ZStack {
            // 폴백: 그라디언트 (항상 표시)
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)

            // 배경 이미지가 있으면 위에 오버레이
            if let uiImage = UIImage(named: terrain.terrainBackgroundImageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
                    .overlay(Color.black.opacity(0.55)) // 가독성을 위한 어둡게 처리
            }
        }
    }

    private func terrainGradientColors(for terrain: Attribute) -> [Color] {
        switch terrain {
        case .fire:
            return [Color(red: 0.25, green: 0.05, blue: 0.02), Color(red: 0.12, green: 0.02, blue: 0.0)]
        case .water:
            return [Color(red: 0.02, green: 0.08, blue: 0.25), Color(red: 0.01, green: 0.04, blue: 0.15)]
        case .wind:
            return [Color(red: 0.02, green: 0.18, blue: 0.08), Color(red: 0.01, green: 0.08, blue: 0.04)]
        case .earth:
            return [Color(red: 0.18, green: 0.12, blue: 0.05), Color(red: 0.08, green: 0.06, blue: 0.02)]
        case .thunder:
            return [Color(red: 0.2, green: 0.18, blue: 0.02), Color(red: 0.08, green: 0.06, blue: 0.12)]
        case .dark:
            return [Color(red: 0.08, green: 0.02, blue: 0.15), Color(red: 0.02, green: 0.01, blue: 0.06)]
        case .light:
            return [Color(red: 0.22, green: 0.18, blue: 0.08), Color(red: 0.1, green: 0.08, blue: 0.02)]
        }
    }

    private var terrainIndicator: some View {
        let terrain = viewModel.gameState.globalTerrain
        let isSpell = viewModel.gameState.isSpellTerrain
        let remaining = viewModel.gameState.terrainTurnsRemaining
        return HStack(spacing: 2) {
            Text(terrain.emoji)
                .font(.system(size: 11))
            Text("\(terrain.displayName)")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(isSpell ? .orange : .white.opacity(0.8))
            Text("(\(remaining))")
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(terrain.color.opacity(0.3))
                .overlay(
                    Capsule()
                        .strokeBorder(isSpell ? Color.orange.opacity(0.6) : Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showTerrainTooltip.toggle()
            }
        }
    }

    @ViewBuilder
    private var terrainTooltipOverlay: some View {
        if showTerrainTooltip {
            let terrain = viewModel.gameState.globalTerrain
            let isSpell = viewModel.gameState.isSpellTerrain
            let remaining = viewModel.gameState.terrainTurnsRemaining

            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showTerrainTooltip = false
                    }
                }

            VStack(alignment: .leading, spacing: 8) {
                // 헤더
                HStack(spacing: 6) {
                    Text(terrain.emoji)
                        .font(.system(size: 18))
                    Text("\(terrain.displayName) 지형")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(isSpell ? "마법 지형" : "자연 지형")
                        .font(.system(size: 10))
                        .foregroundColor(isSpell ? .orange : .gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                }

                Divider().background(Color.white.opacity(0.2))

                // 효과 목록
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.cyan)
                            .frame(width: 16)
                        Text("\(terrain.emoji) 속성 몬스터 전투력 +\(PlayerField.globalTerrainBonus)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                            .frame(width: 16)
                        Text("\(terrain.emoji) 속성 몬스터 보유 시 매 턴 기세 +1")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                Divider().background(Color.white.opacity(0.2))

                // 남은 라운드
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                    Text("남은 라운드: \(remaining)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("탭하여 닫기")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(terrain.color.opacity(0.4), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }

    // MARK: - 필드 뷰

    @ViewBuilder
    private func fieldView(player: Player, isOpponent: Bool) -> some View {
        VStack(spacing: 2) {
            // 필드 오버라이드 표시
            if let override = player.field.fieldOverrideAttribute {
                HStack(spacing: 4) {
                    Text(override.emoji)
                        .font(.system(size: 9))
                    Text("\(override.displayName) 오버라이드")
                        .font(.system(size: 8, weight: .bold))
                    Text("(\(player.field.fieldOverrideTurnsRemaining)턴)")
                        .font(.system(size: 8))
                }
                .foregroundColor(attributeColor(override))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(attributeColor(override).opacity(0.15)))
            }

            fieldSlotsRow(player: player, isOpponent: isOpponent)
        }
    }

    @ViewBuilder
    private func fieldSlotsRow(player: Player, isOpponent: Bool) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<PlayerField.slotCount, id: \.self) { i in
                let slot = player.field.slots[i]
                let highlighted = slotHighlighted(index: i, isOpponent: isOpponent)
                let battleHighlight = battleSlotHighlight(index: i, isOpponent: isOpponent)

                let attacked = !isOpponent
                    && viewModel.gameState.currentPhase == .battle
                    && slot.hasAttacked

                FieldSlotView(
                    slot: slot,
                    index: i,
                    globalTerrain: viewModel.gameState.globalTerrain,
                    fieldOverrideAttribute: player.field.fieldOverrideAttribute,
                    activeMomentumSkill: player.activeMomentumSkill,
                    fightingTargetSlot: player.fightingTargetSlot,
                    momentumBonus: player.momentumBonus,
                    cpDebuff: player.field.cpDebuff + slot.slotCpDebuff,
                    isHighlighted: highlighted,
                    aiHighlightColor: battleHighlight,
                    hasAttacked: attacked
                ) {
                    handleSlotTap(index: i, isOpponent: isOpponent)
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: SlotFramePreferenceKey.self,
                            value: [SlotFramePreference(
                                index: i,
                                isOpponent: isOpponent,
                                frame: geo.frame(in: .named("gameBoard"))
                            )]
                        )
                    }
                )
                .animation(.easeInOut(duration: 0.3), value: battleHighlight != nil)
            }
        }
    }

    /// 전투 연출에 따른 슬롯 하이라이트 색상 (AI + 플레이어 통합)
    private func battleSlotHighlight(index: Int, isOpponent: Bool) -> Color? {
        guard let display = viewModel.battleDisplay else { return nil }

        if display.isPlayerAction {
            // 플레이어 공격: 공격자 = 내 필드, 대상 = 상대 필드
            if !isOpponent, let atkSlot = display.attackerSlot, atkSlot == index {
                return .orange
            }
            if isOpponent, let targetSlot = display.targetSlot, targetSlot == index {
                return .red
            }
            if isOpponent, display.isDirectAttack {
                return .red.opacity(0.5)
            }
        } else {
            // AI 액션: 소환 = AI 필드, 공격자 = AI 필드, 대상 = 내 필드
            if isOpponent, let slot = display.highlightedSlot, slot == index {
                return .green
            }
            if isOpponent, let atkSlot = display.attackerSlot, atkSlot == index {
                return .red
            }
            if !isOpponent, let targetSlot = display.targetSlot, targetSlot == index {
                return .red
            }
            if !isOpponent, display.isDirectAttack {
                return .red.opacity(0.5)
            }
        }
        return nil
    }

    private func slotHighlighted(index: Int, isOpponent: Bool) -> Bool {
        if !isOpponent {
            if case .selectingFightingTarget = viewModel.uiState {
                if case .monster = viewModel.player.field.slots[index].content {
                    return true
                }
            }
            if case .selectingEffectTarget(_, _, let isAllyTarget) = viewModel.uiState {
                if isAllyTarget, case .monster = viewModel.player.field.slots[index].content {
                    return true
                }
            }
            if case .selectingSpellEffectTarget(_, let isAllyTarget) = viewModel.uiState {
                if isAllyTarget, case .monster = viewModel.player.field.slots[index].content {
                    return true
                }
            }
            if case .selectingSummonSlot = viewModel.uiState {
                return !viewModel.player.field.slots[index].content.isOccupied
            }
            if case .selectingSacrificeSlot = viewModel.uiState {
                if case .monster = viewModel.player.field.slots[index].content {
                    return !viewModel.player.summonedThisTurn.contains(index)
                }
            }
        }
        if isOpponent {
            if case .selectingAttackTarget = viewModel.uiState {
                if case .monster = viewModel.aiPlayer.field.slots[index].content {
                    return true
                }
                // 직접 공격 가능 여부
                if viewModel.aiPlayer.field.monsterCount == 0 {
                    return true
                }
            }
            if case .selectingEffectTarget(_, _, let isAllyTarget) = viewModel.uiState {
                if !isAllyTarget, case .monster = viewModel.aiPlayer.field.slots[index].content {
                    return true
                }
            }
            if case .selectingSpellEffectTarget(_, let isAllyTarget) = viewModel.uiState {
                if !isAllyTarget, case .monster = viewModel.aiPlayer.field.slots[index].content {
                    return true
                }
            }
        }
        return false
    }

    private func handleSlotTap(index: Int, isOpponent: Bool) {
        if !isOpponent {
            // 투지 타겟 선택
            if case .selectingFightingTarget = viewModel.uiState {
                viewModel.applyFightingSkill(toSlot: index)
                return
            }
            // 몬스터 효과 타겟 선택 (아군)
            if case .selectingEffectTarget(_, _, let isAllyTarget) = viewModel.uiState, isAllyTarget {
                viewModel.applyFourStarEffectOnTarget(targetSlot: index)
                return
            }
            // 마법 효과 타겟 선택 (아군)
            if case .selectingSpellEffectTarget(_, let isAllyTarget) = viewModel.uiState, isAllyTarget {
                viewModel.applySpellEffectOnTarget(targetSlot: index)
                return
            }
            // 내 필드 슬롯 탭
            if case .selectingSummonSlot = viewModel.uiState {
                viewModel.summonToSlot(index)
                return
            }
            if case .selectingSacrificeSlot = viewModel.uiState {
                viewModel.sacrificeMonster(at: index)
                return
            }
            if case .battlePhase = viewModel.uiState, viewModel.canAttack {
                if case .monster = viewModel.player.field.slots[index].content {
                    viewModel.selectAttacker(index)
                }
                return
            }
        } else {
            // 몬스터 효과 타겟 선택 (상대)
            if case .selectingEffectTarget(_, _, let isAllyTarget) = viewModel.uiState, !isAllyTarget {
                viewModel.applyFourStarEffectOnTarget(targetSlot: index)
                return
            }
            // 마법 효과 타겟 선택 (상대)
            if case .selectingSpellEffectTarget(_, let isAllyTarget) = viewModel.uiState, !isAllyTarget {
                viewModel.applySpellEffectOnTarget(targetSlot: index)
                return
            }
            // 상대 필드 슬롯 탭
            if case .selectingAttackTarget(let atkSlot) = viewModel.uiState {
                if viewModel.aiPlayer.field.monsterCount == 0 {
                    // 직접 공격
                    viewModel.executeAttack(attackerSlot: atkSlot, defenderSlot: nil)
                } else if case .monster = viewModel.aiPlayer.field.slots[index].content {
                    // 프리뷰 표시 (공격은 프리뷰의 공격하기 버튼으로)
                    viewModel.updateCombatPreview(attackerSlot: atkSlot, defenderSlot: index)
                }
                return
            }
        }

        // 게임 액션이 없으면 → 카드 상세보기
        let slot = isOpponent
            ? viewModel.aiPlayer.field.slots[index]
            : viewModel.player.field.slots[index]
        showFieldCardDetail(slot: slot)
    }

    private func showFieldCardDetail(slot: FieldSlot) {
        switch slot.content {
        case .monster(let card, _):
            viewModel.showingFieldCardDetail = FieldCardDetail(card: .monster(card))
        case .spell(let card):
            viewModel.showingFieldCardDetail = FieldCardDetail(card: .spell(card))
        case .empty:
            break
        }
    }

    // MARK: - 액션 버튼

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 4) {
            if viewModel.isPlayerTurn {
                switch viewModel.uiState {
                case .mainPhase:
                    HStack(spacing: 6) {
                        Button {
                            showMomentumSkillPanel.toggle()
                        } label: {
                            Label("기세 스킬", systemImage: "flame.fill")
                        }
                        .buttonStyle(GameButtonStyle(color: .orange))
                        .disabled(viewModel.player.momentum == 0)
                        .opacity(viewModel.player.momentum == 0 ? 0.4 : 1.0)

                        Button {
                            viewModel.enterSacrificeMode()
                        } label: {
                            Label("희생", systemImage: "arrow.uturn.down")
                        }
                        .buttonStyle(GameButtonStyle(color: .purple))
                        .disabled(!viewModel.hasSacrifiableMonster)
                        .opacity(viewModel.hasSacrifiableMonster ? 1.0 : 0.4)

                        Button {
                            viewModel.enterBattlePhase()
                        } label: {
                            Label("배틀", systemImage: "bolt.fill")
                        }
                        .buttonStyle(GameButtonStyle(color: .red))

                        Button {
                            viewModel.endTurn()
                        } label: {
                            Label("턴 종료", systemImage: "stop.circle")
                        }
                        .buttonStyle(GameButtonStyle(color: .gray))
                    }

                case .battlePhase:
                    HStack(spacing: 8) {
                        Button("턴 종료") {
                            viewModel.endTurn()
                        }
                        .buttonStyle(GameButtonStyle(color: .gray))
                    }

                case .selectingSummonSlot:
                    HStack(spacing: 8) {
                        Text("슬롯을 선택하세요")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Button("취소") {
                            viewModel.cancelSlotSelection()
                        }
                        .buttonStyle(GameButtonStyle(color: .gray))
                    }

                case .selectingSacrificeSlot:
                    HStack(spacing: 8) {
                        Text("희생할 몬스터를 선택하세요")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Button("취소") {
                            viewModel.cancelSlotSelection()
                        }
                        .buttonStyle(GameButtonStyle(color: .gray))
                    }

                case .selectingFightingTarget:
                    Text("투지를 적용할 몬스터를 선택하세요")
                        .font(.caption)
                        .foregroundColor(.orange)

                case .selectingEffectTarget(_, _, let isAllyTarget):
                    Text(isAllyTarget
                         ? "효과를 적용할 아군 몬스터를 선택하세요"
                         : "효과를 적용할 상대 몬스터를 선택하세요")
                        .font(.caption)
                        .foregroundColor(isAllyTarget ? .cyan : .red)

                case .selectingSpellEffectTarget(_, let isAllyTarget):
                    Text(isAllyTarget
                         ? "효과를 적용할 아군 몬스터를 선택하세요"
                         : "효과를 적용할 상대 몬스터를 선택하세요")
                        .font(.caption)
                        .foregroundColor(isAllyTarget ? .cyan : .red)

                case .selectingAttackTarget:
                    HStack(spacing: 8) {
                        Text("공격 대상을 선택하세요")
                            .font(.caption)
                            .foregroundColor(.red)
                        Button("취소") {
                            viewModel.cancelAttack()
                        }
                        .buttonStyle(GameButtonStyle(color: .gray))
                    }

                default:
                    EmptyView()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}

/// 게임 결과 뷰
struct GameResultView: View {
    let winner: String
    let onRestart: () -> Void
    var onGoHome: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("GAME OVER")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.yellow)

            Text("\(winner) 승리!")
                .font(.title2)
                .foregroundColor(.white)

            Button("다시 시작") {
                onRestart()
            }
            .buttonStyle(GameButtonStyle(color: .blue))

            if let onGoHome {
                Button("홈으로") {
                    onGoHome()
                }
                .buttonStyle(GameButtonStyle(color: .gray))
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.9))
        )
    }
}

/// 게임 버튼 스타일
struct GameButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(configuration.isPressed ? 0.5 : 0.8))
            )
    }
}
