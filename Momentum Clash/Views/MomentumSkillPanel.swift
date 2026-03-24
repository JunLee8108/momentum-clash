import SwiftUI

/// 기세 스킬 선택 패널
struct MomentumSkillPanel: View {
    let currentMomentum: Int
    let onSelect: (MomentumSkill) -> Void
    let onClose: () -> Void

    @State private var selectedSkill: MomentumSkill?

    private let availableSkills: [MomentumSkill] = [
        .fighting, .terrainMastery, .breakthrough, .explosion
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Label("기세 스킬", systemImage: "flame.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.orange)

                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("\(currentMomentum)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.orange)

                Spacer()

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // 스킬 카드 그리드 또는 상세 뷰
            if let skill = selectedSkill {
                skillDetailView(skill)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                HStack(spacing: 8) {
                    ForEach(availableSkills, id: \.self) { skill in
                        skillCard(skill)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
                .transition(.opacity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                )
        )
        .padding(.horizontal, 8)
        .animation(.easeInOut(duration: 0.2), value: selectedSkill)
    }

    // MARK: - 스킬 카드 (목록)

    @ViewBuilder
    private func skillCard(_ skill: MomentumSkill) -> some View {
        let canUse = currentMomentum >= skill.cost
        let isSelected = selectedSkill == skill

        Button {
            selectedSkill = skill
        } label: {
            VStack(spacing: 4) {
                // 비용
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                    Text("\(skill.cost)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .foregroundColor(canUse ? .orange : .gray)

                // 이름
                Text(skill.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(canUse ? .white : .gray)

                // 설명
                Text(skillShortDesc(skill))
                    .font(.system(size: 9))
                    .foregroundColor(canUse ? .white.opacity(0.7) : .gray.opacity(0.5))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(canUse
                          ? (isSelected ? Color.orange.opacity(0.3) : Color.orange.opacity(0.15))
                          : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(canUse
                                    ? (isSelected ? Color.orange : Color.orange.opacity(0.5))
                                    : Color.gray.opacity(0.2),
                                    lineWidth: isSelected ? 2 : 1)
                    )
            )
            .opacity(canUse ? 1.0 : 0.45)
        }
        .disabled(!canUse)
    }

    // MARK: - 상세 확인 뷰

    @ViewBuilder
    private func skillDetailView(_ skill: MomentumSkill) -> some View {
        let canUse = currentMomentum >= skill.cost
        let remainingMomentum = currentMomentum - skill.cost

        VStack(spacing: 10) {
            // 스킬 이름 + 코스트
            HStack(spacing: 6) {
                Text(skillIcon(skill))
                    .font(.system(size: 18))
                Text(skill.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                    Text("코스트 \(skill.cost)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.orange)
            }

            // 효과 설명
            Text(skill.description)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)

            // 기세 변화 미리보기
            HStack(spacing: 4) {
                Text("기세")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)

                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("\(currentMomentum)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.orange)

                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)

                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("\(max(0, remainingMomentum))")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                }
                .foregroundColor(canUse ? .orange : .red)

                if !canUse {
                    Text("(부족)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                }

                Spacer()
            }

            // 버튼
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedSkill = nil
                    }
                } label: {
                    Text("취소")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }

                Button {
                    onSelect(skill)
                } label: {
                    Text("발동")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(canUse ? .black : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(canUse
                                      ? Color.orange
                                      : Color.gray.opacity(0.3))
                        )
                }
                .disabled(!canUse)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    // MARK: - 헬퍼

    private func skillShortDesc(_ skill: MomentumSkill) -> String {
        switch skill {
        case .fighting:       return "1체 전투력\n+500"
        case .terrainMastery: return "지형 보너스\n2배"
        case .breakthrough:   return "전체 몬스터\n+300"
        case .explosion:      return "상대 최강\n1체 제거"
        default:              return ""
        }
    }

    private func skillIcon(_ skill: MomentumSkill) -> String {
        switch skill {
        case .fighting:       return "👊"
        case .terrainMastery: return "🌍"
        case .breakthrough:   return "⚔️"
        case .explosion:      return "💥"
        default:              return "🔥"
        }
    }
}
