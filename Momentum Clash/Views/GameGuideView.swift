import SwiftUI

/// 게임 가이드 (스와이프 페이지)
struct GameGuideView: View {
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss

    private let totalPages = 8

    var body: some View {
        VStack(spacing: 0) {
            // 상단 바
            HStack {
                Text("게임 가이드")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(currentPage + 1) / \(totalPages)")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // 페이지 콘텐츠
            TabView(selection: $currentPage) {
                overviewPage.tag(0)
                turnStructurePage.tag(1)
                resourcePage.tag(2)
                attributePage.tag(3)
                terrainPage.tag(4)
                momentumPage.tag(5)
                combatPage.tag(6)
                deckBuildingPage.tag(7)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            // 하단 페이지 인디케이터 + 버튼
            HStack {
                if currentPage > 0 {
                    Button {
                        withAnimation { currentPage -= 1 }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("이전")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.cyan)
                    }
                } else {
                    Spacer().frame(width: 60)
                }

                Spacer()

                // 도트 인디케이터
                HStack(spacing: 6) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? Color.cyan : Color.gray.opacity(0.4))
                            .frame(width: 6, height: 6)
                    }
                }

                Spacer()

                if currentPage < totalPages - 1 {
                    Button {
                        withAnimation { currentPage += 1 }
                    } label: {
                        HStack(spacing: 4) {
                            Text("다음")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.cyan)
                    }
                } else {
                    Button("닫기") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.black.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 1. 게임 개요

    private var overviewPage: some View {
        guidePage(
            icon: "gamecontroller.fill",
            iconColor: .cyan,
            title: "게임 개요"
        ) {
            guideText("Momentum Clash는 속성 지형을 장악하고 기세를 활용하는 전략 카드 배틀 게임입니다.")

            guideSection("승리 조건") {
                guideBullet("상대의 LP(라이프 포인트)를 0으로 만들면 승리")
                guideBullet("시작 LP: 8,000")
            }

            guideSection("기본 흐름") {
                guideBullet("매 턴 카드를 드로우하고 몬스터를 소환")
                guideBullet("필드에 배치된 몬스터로 상대를 공격")
                guideBullet("속성 상성과 지형을 활용해 유리하게 싸움")
                guideBullet("기세를 모아 강력한 스킬을 발동")
            }
        }
    }

    // MARK: - 2. 턴 구조

    private var turnStructurePage: some View {
        guidePage(
            icon: "arrow.triangle.2.circlepath",
            iconColor: .orange,
            title: "턴 구조"
        ) {
            guideText("매 턴은 5개의 페이즈로 진행됩니다.")

            phaseRow("1", "드로우", "2장 중 1장을 선택하여 패에 추가", .blue)
            phaseRow("2", "스탠바이", "기력 충전, 기세 +1, 지속효과 처리", .green)
            phaseRow("3", "메인", "몬스터 소환, 마법 발동, 기세 스킬 사용", .yellow)
            phaseRow("4", "배틀", "필드 몬스터로 상대를 공격", .red)
            phaseRow("5", "엔드", "턴 종료, 패 8장 초과 시 버림", .gray)

            guideNote("첫 턴 플레이어는 공격할 수 없습니다.")
        }
    }

    // MARK: - 3. 자원 시스템

    private var resourcePage: some View {
        guidePage(
            icon: "chart.bar.fill",
            iconColor: .green,
            title: "자원 시스템"
        ) {
            resourceRow(icon: "heart.fill", color: .red, name: "LP (라이프)", desc: "체력. 8,000에서 시작. 0이 되면 패배.")

            resourceRow(icon: "bolt.circle.fill", color: .cyan, name: "기력 (Energy)", desc: "카드를 소환/사용하는 비용. 매 턴 충전.")

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("  ")
                    Text("LP 100%~51%").font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("기력 3").font(.system(size: 12, weight: .bold)).foregroundColor(.cyan)
                }
                HStack(spacing: 4) {
                    Text("  ")
                    Text("LP 50%~26%").font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("기력 4").font(.system(size: 12, weight: .bold)).foregroundColor(.orange)
                }
                HStack(spacing: 4) {
                    Text("  ")
                    Text("LP 25% 이하").font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("기력 5").font(.system(size: 12, weight: .bold)).foregroundColor(.red)
                }
            }
            .padding(.bottom, 4)

            resourceRow(icon: "flame.fill", color: .orange, name: "기세 (Momentum)", desc: "매 턴 +1 축적 (최대 10). 강력한 스킬에 사용.")
        }
    }

    // MARK: - 4. 속성 상성

    private var attributePage: some View {
        guidePage(
            icon: "shield.lefthalf.filled",
            iconColor: .purple,
            title: "속성 상성"
        ) {
            guideText("7가지 속성이 있으며, 상성에 따라 전투력이 변합니다.")

            guideSection("순환 상성 (5속성)") {
                HStack(spacing: 0) {
                    Text("🔥화").font(.system(size: 12, weight: .bold))
                    Text(" → ").font(.system(size: 11)).foregroundColor(.gray)
                    Text("🌿풍").font(.system(size: 12, weight: .bold))
                    Text(" → ").font(.system(size: 11)).foregroundColor(.gray)
                    Text("⛰️지").font(.system(size: 12, weight: .bold))
                    Text(" → ").font(.system(size: 11)).foregroundColor(.gray)
                    Text("⚡뇌").font(.system(size: 12, weight: .bold))
                    Text(" → ").font(.system(size: 11)).foregroundColor(.gray)
                    Text("💧수").font(.system(size: 12, weight: .bold))
                    Text(" → ").font(.system(size: 11)).foregroundColor(.gray)
                    Text("🔥화").font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
            }

            guideSection("상호 강화") {
                HStack {
                    Text("🌑암").font(.system(size: 12, weight: .bold))
                    Text(" ↔ ").foregroundColor(.gray)
                    Text("✨광").font(.system(size: 12, weight: .bold))
                    Text("  서로에게 1.5배").font(.system(size: 12)).foregroundColor(.orange)
                }
                .foregroundColor(.white)
            }

            guideSection("배율") {
                matchupRow("유리한 상대", "x1.3", .green)
                matchupRow("불리한 상대", "x0.7", .red)
                matchupRow("암 ↔ 광", "x1.5", .orange)
                matchupRow("동일/무관", "x1.0", .gray)
            }
        }
    }

    // MARK: - 5. 지형 시스템

    private var terrainPage: some View {
        guidePage(
            icon: "map.fill",
            iconColor: .brown,
            title: "지형 시스템"
        ) {
            guideText("필드에는 지형 속성이 존재하며, 해당 속성 몬스터에게 보너스를 줍니다.")

            guideSection("지형 보너스") {
                guideBullet("지형과 같은 속성 몬스터: 전투력 +300")
                guideBullet("지형은 매 라운드 랜덤으로 변경")
            }

            guideSection("필드 오버라이드") {
                guideBullet("5성 몬스터 소환 시 지형을 강제 변경 (2턴)")
                guideBullet("지형 마법 카드로도 변경 가능")
                guideBullet("오버라이드는 글로벌 지형보다 우선")
            }

            guideNote("지형을 장악하면 아군 전체에 +300 CP 보너스!")
        }
    }

    // MARK: - 6. 기세 스킬

    private var momentumPage: some View {
        guidePage(
            icon: "flame.fill",
            iconColor: .orange,
            title: "기세 스킬"
        ) {
            guideText("기세를 소모하여 강력한 스킬을 발동할 수 있습니다. 메인 페이즈에 사용합니다.")

            skillRow("투지", 3, "아군 몬스터 1체 전투력 +500 (이번 턴)")
            skillRow("지형 장악", 4, "지형 보너스 2배 (+600) (이번 턴)")
            skillRow("연속 공격", 5, "아군 1체가 이번 턴 2회 공격")
            skillRow("전선 돌파", 6, "아군 전체 전투력 +300 (이번 턴)")
            skillRow("기세 폭발", 8, "상대 최강 몬스터 1체 파괴")
            skillRow("완전 각성", 10, "아군 1체를 5단계로 변신")
        }
    }

    // MARK: - 7. 전투 시스템

    private var combatPage: some View {
        guidePage(
            icon: "bolt.shield.fill",
            iconColor: .red,
            title: "전투 시스템"
        ) {
            guideSection("전투력 (CP) 계산") {
                guideBullet("기본 CP (카드 스탯)")
                guideBullet("+ 지형 보너스 (+300)")
                guideBullet("× 속성 배율 (0.7~1.5)")
                guideBullet("+ 기세 스킬 보너스")
                guideBullet("+ CP 버프/디버프")
            }

            guideSection("전투 결과") {
                guideBullet("공격자 승리: 상대 몬스터 파괴 + 초과 데미지 → LP")
                guideBullet("방어자 승리: 공격 몬스터 파괴 + 초과분 → 공격자 LP")
                guideBullet("무승부: 양쪽 모두 파괴")
            }

            guideSection("방어막 & 직접 공격") {
                guideBullet("방어막은 데미지를 먼저 흡수")
                guideBullet("상대 필드에 몬스터가 없으면 직접 공격 (LP에 직접 데미지)")
            }
        }
    }

    // MARK: - 8. 덱 빌딩

    private var deckBuildingPage: some View {
        guidePage(
            icon: "square.stack.3d.up.fill",
            iconColor: .yellow,
            title: "덱 빌딩"
        ) {
            guideSection("덱 구성 규칙") {
                deckRuleRow("총 카드", "30장")
                deckRuleRow("몬스터", "20장")
                deckRuleRow("마법", "10장")
                deckRuleRow("동일 카드", "최대 3장")
                deckRuleRow("5성 몬스터", "최대 2장")
            }

            guideSection("덱 빌딩 팁") {
                guideBullet("속성을 1~2개로 집중하면 지형 보너스 활용 극대화")
                guideBullet("저코스트(1~2성)와 고코스트(4~5성)를 균형있게 배치")
                guideBullet("5성 몬스터는 필드 오버라이드로 지형을 장악")
                guideBullet("지형 마법으로 추가 지형 변경 가능")
            }

            guideSection("프리셋 덱") {
                guideBullet("6가지 프리셋 덱이 준비되어 있습니다")
                guideBullet("덱 빌딩 탭에서 선택하여 바로 사용 가능")
            }
        }
    }

    // MARK: - 공통 컴포넌트

    private func guidePage<Content: View>(
        icon: String,
        iconColor: Color,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                    Text(title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 4)

                content()
            }
            .padding(20)
        }
    }

    private func guideText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func guideSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.cyan)
                .padding(.top, 4)
            content()
        }
    }

    private func guideBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 13))
                .foregroundColor(.cyan)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func guideNote(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 11))
                .foregroundColor(.yellow)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.yellow.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.yellow.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow.opacity(0.2), lineWidth: 1))
        )
        .padding(.top, 4)
    }

    private func phaseRow(_ num: String, _ name: String, _ desc: String, _ color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(num)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .frame(width: 22, height: 22)
                .background(Circle().fill(color))
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    private func resourceRow(icon: String, color: Color, name: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 4)
    }

    private func matchupRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
    }

    private func skillRow(_ name: String, _ cost: Int, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(cost)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.orange))
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 2)
    }

    private func deckRuleRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}
