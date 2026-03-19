//
//  ContentView.swift
//  Momentum Clash
//
//  Created by Jun Lee on 3/19/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            if case .notStarted = viewModel.uiState {
                // 타이틀 화면
                titleScreen
            } else {
                // 게임 보드
                GameBoardView(viewModel: viewModel)
            }
        }
    }

    private var titleScreen: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.18), Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
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

                Button("게임 시작") {
                    viewModel.startGame()
                }
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                )

                Text("화염 러시 vs 대지 요새")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.6))

                Spacer()
                    .frame(height: 60)
            }
        }
    }
}

#Preview {
    ContentView()
}
