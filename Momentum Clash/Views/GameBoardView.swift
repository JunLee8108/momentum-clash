import SwiftUI

/// 메인 게임 보드 뷰
struct GameBoardView: View {
    var viewModel: GameViewModel
    @State private var showTerrainTooltip = false

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
                    isCurrentTurn: !viewModel.isPlayerTurn
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
                    isCurrentTurn: viewModel.isPlayerTurn
                )

                // 로그
                GameLogView(logs: viewModel.logs)
                    .padding(.horizontal, 8)

                // 내 패
                HandView(
                    hand: viewModel.player.hand,
                    selectedIndex: viewModel.selectedHandIndex,
                    canInteract: viewModel.isPlayerTurn && viewModel.gameState.currentPhase == .main
                ) { index in
                    viewModel.selectCardFromHand(index)
                }

                // 액션 버튼
                actionButtons
            }
            .padding(.vertical, 8)

            // 오버레이: 드로우 선택
            if case .drawSelection(let c1, let c2) = viewModel.uiState {
                Color.black.opacity(0.6).ignoresSafeArea()
                DrawSelectionView(choice1: c1, choice2: c2) { chosen, rejected in
                    viewModel.selectDrawCard(chosen, rejected: rejected)
                }
            }

            // 오버레이: 게임 종료
            if case .gameOver(let winner) = viewModel.uiState {
                Color.black.opacity(0.7).ignoresSafeArea()
                GameResultView(winner: winner) {
                    viewModel.restartGame()
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

            // 오버레이: 전투 프리뷰
            if let preview = viewModel.combatPreview {
                VStack {
                    Spacer()
                    CombatPreviewView(preview: preview) {
                        viewModel.combatPreview = nil
                    }
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    Spacer().frame(height: 60)
                }
                .animation(.easeOut(duration: 0.2), value: viewModel.combatPreview)
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

            // 오버레이: 카드 상세보기 (패에서)
            if let detail = viewModel.showingCardDetail {
                CardDetailView(
                    card: detail.card,
                    handIndex: detail.handIndex,
                    canUse: viewModel.canUseCard(detail.card),
                    onClose: { viewModel.closeCardDetail() },
                    onUse: { viewModel.useCardFromDetail() }
                )
                .transition(.opacity)
            }

            // 오버레이: 필드 카드 상세보기
            if let fieldCard = viewModel.showingFieldCardDetail {
                FieldCardDetailView(
                    card: fieldCard,
                    onClose: { viewModel.showingFieldCardDetail = nil }
                )
                .transition(.opacity)
            }
        }
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
                    isHighlighted: highlighted,
                    aiHighlightColor: battleHighlight,
                    hasAttacked: attacked
                ) {
                    handleSlotTap(index: i, isOpponent: isOpponent)
                }
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
            if case .selectingSummonSlot = viewModel.uiState {
                return !viewModel.player.field.slots[index].content.isOccupied
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
        }
        return false
    }

    private func handleSlotTap(index: Int, isOpponent: Bool) {
        if !isOpponent {
            // 내 필드 슬롯 탭
            if case .selectingSummonSlot = viewModel.uiState {
                viewModel.summonToSlot(index)
                return
            }
            if case .battlePhase = viewModel.uiState, viewModel.canAttack {
                if case .monster = viewModel.player.field.slots[index].content {
                    viewModel.selectAttacker(index)
                }
                return
            }
        } else {
            // 상대 필드 슬롯 탭
            if case .selectingAttackTarget(let atkSlot) = viewModel.uiState {
                if viewModel.aiPlayer.field.monsterCount == 0 {
                    // 직접 공격
                    viewModel.executeAttack(attackerSlot: atkSlot, defenderSlot: nil)
                } else if case .monster = viewModel.aiPlayer.field.slots[index].content {
                    if let existing = viewModel.combatPreview,
                       case .monster(let m, _) = viewModel.aiPlayer.field.slots[index].content,
                       existing.defenderName == m.name {
                        // 프리뷰가 이미 표시된 상태에서 같은 대상 재탭 → 공격 실행
                        viewModel.executeAttack(attackerSlot: atkSlot, defenderSlot: index)
                    } else {
                        // 첫 탭 → 프리뷰 표시
                        viewModel.updateCombatPreview(attackerSlot: atkSlot, defenderSlot: index)
                    }
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
            viewModel.showingFieldCardDetail = .monster(card)
        case .spell(let card):
            viewModel.showingFieldCardDetail = .spell(card)
        case .empty:
            break
        }
    }

    // MARK: - 액션 버튼

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 8) {
            if viewModel.isPlayerTurn {
                switch viewModel.uiState {
                case .mainPhase:
                    Button("배틀 페이즈") {
                        viewModel.enterBattlePhase()
                    }
                    .buttonStyle(GameButtonStyle(color: .red))

                    Button("턴 종료") {
                        viewModel.endTurn()
                    }
                    .buttonStyle(GameButtonStyle(color: .gray))

                case .battlePhase:
                    Button("턴 종료") {
                        viewModel.endTurn()
                    }
                    .buttonStyle(GameButtonStyle(color: .gray))

                case .selectingSummonSlot:
                    Text("슬롯을 선택하세요")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Button("취소") {
                        viewModel.cancelSlotSelection()
                    }
                    .buttonStyle(GameButtonStyle(color: .gray))

                case .selectingAttackTarget:
                    Text("공격 대상을 선택하세요")
                        .font(.caption)
                        .foregroundColor(.red)
                    Button("취소") {
                        viewModel.cancelAttack()
                    }
                    .buttonStyle(GameButtonStyle(color: .gray))

                default:
                    EmptyView()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
        .frame(height: 36)
    }
}

/// 게임 결과 뷰
struct GameResultView: View {
    let winner: String
    let onRestart: () -> Void

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
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(configuration.isPressed ? 0.5 : 0.8))
            )
    }
}
