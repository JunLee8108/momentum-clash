//
//  ContentView.swift
//  Momentum Clash
//
//  Created by Jun Lee on 3/19/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()
    @State private var deckVM = DeckViewModel()
    @State private var selectedTab = 0
    @State private var isGameActive = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // 탭 1: 홈
            homeScreen
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
                .tag(0)

            // 탭 2: 덱 빌딩
            DeckBuilderView(deckVM: deckVM)
                .tabItem {
                    Image(systemName: "rectangle.stack.fill")
                    Text("덱 빌딩")
                }
                .tag(1)

            // 탭 3: 게임
            gameTab
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text("게임")
                }
                .tag(2)
        }
        .tint(.orange)
    }

    // MARK: - 홈 화면

    private var homeScreen: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.18), Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("MOMENTUM")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("CLASH")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)

                Text("속성 지형 쟁탈 + 기세 전략 카드 배틀")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Spacer()

                // 덱 상태 요약
                deckStatusSummary

                // 게임 시작 버튼
                Button {
                    startGameWithCustomDeck()
                } label: {
                    Text("게임 시작")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: deckVM.isDeckValid ? [.orange, .red] : [.gray, .gray.opacity(0.5)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                        )
                }
                .disabled(!deckVM.isDeckValid)

                if !deckVM.isDeckValid {
                    Text("덱을 먼저 완성하세요 (몬스터 20 + 마법 10)")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                }

                // 덱 빌딩 바로가기
                Button {
                    selectedTab = 1
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 14))
                        Text("덱 빌딩으로 이동")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.cyan)
                }

                Spacer()
                    .frame(height: 40)
            }
        }
    }

    private var deckStatusSummary: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("내 덱")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text("\(deckVM.deck.count)/\(DeckConstants.deckSize)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(deckVM.isDeckValid ? .green : .orange)
            }

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1, height: 30)

            VStack(spacing: 4) {
                Text("몬스터")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text("\(deckVM.monsterCount)/\(DeckConstants.monsterLimit)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text("마법")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text("\(deckVM.spellCount)/\(DeckConstants.spellLimit)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1, height: 30)

            VStack(spacing: 4) {
                Text("★5")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text("\(deckVM.highCostCount)/\(DeckConstants.highCostLimit)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(deckVM.highCostCount >= DeckConstants.highCostLimit ? .yellow : .white)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - 게임 탭

    @ViewBuilder
    private var gameTab: some View {
        if isGameActive {
            GameBoardView(viewModel: viewModel) {
                // 홈으로 돌아가기
                isGameActive = false
                selectedTab = 0
            }
        } else {
            // 게임 미진행 시 안내 화면
            gameInactiveView
        }
    }

    // MARK: - 게임 미진행 안내

    private var gameInactiveView: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.14), Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "gamecontroller")
                    .font(.system(size: 48))
                    .foregroundColor(.gray.opacity(0.4))

                Text("진행 중인 게임이 없습니다")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.gray)

                if deckVM.isDeckValid {
                    Button {
                        startGameWithCustomDeck()
                    } label: {
                        Text("게임 시작")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 160, height: 44)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                            )
                    }
                } else {
                    Text("덱을 먼저 완성하세요")
                        .font(.system(size: 14))
                        .foregroundColor(.orange.opacity(0.8))

                    Button {
                        selectedTab = 1
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 13))
                            Text("덱 빌딩으로 이동")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.cyan)
                    }
                }
            }
        }
    }

    // MARK: - 게임 시작

    private func startGameWithCustomDeck() {
        guard deckVM.isDeckValid else { return }

        let playerDeck = deckVM.buildDeck()
        let aiDeckInfo = AIDeckTemplates.randomDeck()

        viewModel.startGameWithDeck(playerDeck: playerDeck, aiDeck: aiDeckInfo.deck, aiDeckName: aiDeckInfo.name)
        isGameActive = true
        selectedTab = 2
    }
}

#Preview {
    ContentView()
}
