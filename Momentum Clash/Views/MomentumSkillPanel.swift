import SwiftUI

/// 기세 스킬 선택 패널
struct MomentumSkillPanel: View {
    let currentMomentum: Int
    let onSelect: (MomentumSkill) -> Void
    let onClose: () -> Void

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

            // 스킬 카드 그리드
            HStack(spacing: 8) {
                ForEach(availableSkills, id: \.self) { skill in
                    skillCard(skill)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
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
    }

    @ViewBuilder
    private func skillCard(_ skill: MomentumSkill) -> some View {
        let canUse = currentMomentum >= skill.cost

        Button {
            if canUse { onSelect(skill) }
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
                          ? Color.orange.opacity(0.15)
                          : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(canUse
                                    ? Color.orange.opacity(0.5)
                                    : Color.gray.opacity(0.2),
                                    lineWidth: 1)
                    )
            )
            .opacity(canUse ? 1.0 : 0.45)
        }
        .disabled(!canUse)
    }

    private func skillShortDesc(_ skill: MomentumSkill) -> String {
        switch skill {
        case .fighting:       return "1체 전투력\n+500"
        case .terrainMastery: return "지형 보너스\n2배"
        case .breakthrough:   return "전체 몬스터\n+300"
        case .explosion:      return "상대 전체\nCP×100 DMG"
        default:              return ""
        }
    }
}
