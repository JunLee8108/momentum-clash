import SwiftUI

/// 메인 게임 보드 뷰
struct GameBoardView: View {
    var viewModel: GameViewModel

    var body: some View {
        ZStack {
            // 배경
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.15)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

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

                // 구분선
                HStack {
                    Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
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

            // 오버레이: AI 턴 액션 배너
            if case .aiTurn = viewModel.uiState {
                VStack {
                    Spacer()
                    if let display = viewModel.aiActionDisplay {
                        Text(display.message)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(
                                        display.attackingSlot != nil
                                        ? Color.red.opacity(0.85)
                                        : display.showLPFlash
                                        ? Color.orange.opacity(0.85)
                                        : Color.black.opacity(0.75)
                                    )
                            )
                            .shadow(color: display.attackingSlot != nil ? .red.opacity(0.6) : .clear, radius: 8)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("AI 턴 진행 중...")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Capsule().fill(Color.black.opacity(0.6)))
                    }
                    Spacer()
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.aiActionDisplay)
            }

            // LP 데미지 플래시
            if let display = viewModel.aiActionDisplay, display.showLPFlash {
                Color.red.opacity(0.15)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.3), value: display.showLPFlash)
            }

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

    // MARK: - 필드 뷰

    @ViewBuilder
    private func fieldView(player: Player, isOpponent: Bool) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<PlayerField.slotCount, id: \.self) { i in
                let slot = player.field.slots[i]
                let highlighted = slotHighlighted(index: i, isOpponent: isOpponent)
                let aiHighlight = aiSlotHighlight(index: i, isOpponent: isOpponent)

                FieldSlotView(
                    slot: slot,
                    index: i,
                    isHighlighted: highlighted,
                    aiHighlightColor: aiHighlight
                ) {
                    handleSlotTap(index: i, isOpponent: isOpponent)
                }
                .animation(.easeInOut(duration: 0.3), value: aiHighlight != nil)
            }
        }
    }

    /// AI 액션에 따른 슬롯 하이라이트 색상
    private func aiSlotHighlight(index: Int, isOpponent: Bool) -> Color? {
        guard let display = viewModel.aiActionDisplay else { return nil }

        // 소환 하이라이트 (AI 필드)
        if isOpponent, let slot = display.highlightedSlot, slot == index {
            return .green
        }
        // 공격자 하이라이트 (AI 필드)
        if isOpponent, let atkSlot = display.attackingSlot, atkSlot == index {
            return .red
        }
        // 공격 대상 하이라이트 (플레이어 필드)
        if !isOpponent, let targetSlot = display.targetSlot, targetSlot == index {
            return .red
        }
        // 직접 공격 시 플레이어 전체 필드 깜빡임
        if !isOpponent, display.isDirectAttack {
            return .red.opacity(0.5)
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
                    viewModel.executeAttack(attackerSlot: atkSlot, defenderSlot: index)
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
