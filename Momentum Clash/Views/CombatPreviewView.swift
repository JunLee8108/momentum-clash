import SwiftUI

/// 전투 프리뷰 오버레이 — 공격 대상 선택 시 예상 결과 표시
struct CombatPreviewView: View {
    let preview: CombatPreviewData
    var onAttack: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            // 헤더: 예상 결과
            Text(preview.predictedResult.displayText)
                .font(.system(size: 13, weight: .black))
                .foregroundColor(preview.predictedResult.color)

            HStack(spacing: 12) {
                // 공격자 (플레이어)
                cpColumn(
                    name: preview.attackerName,
                    attribute: preview.attackerAttribute,
                    baseCP: preview.attackerBaseCP,
                    effectiveCP: preview.attackerEffectiveCP,
                    terrainBonus: preview.attackerTerrainBonus,
                    multiplier: preview.attackerMultiplier,
                    shield: 0
                )

                // VS
                Text("⚔️")
                    .font(.system(size: 18))

                // 방어자 (AI)
                cpColumn(
                    name: preview.defenderName,
                    attribute: preview.defenderAttribute,
                    baseCP: preview.defenderBaseCP,
                    effectiveCP: preview.defenderEffectiveCP,
                    terrainBonus: preview.defenderTerrainBonus,
                    multiplier: preview.defenderMultiplier,
                    shield: preview.defenderShield
                )
            }

            // LP 데미지 예상
            lpDamageRow

            // 액션 버튼
            HStack(spacing: 12) {
                Button {
                    onClose()
                } label: {
                    Text("취소")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.5))
                        )
                }

                Button {
                    onAttack()
                } label: {
                    Text("공격하기")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.8))
                        )
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(preview.predictedResult.color.opacity(0.6), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 8)
    }

    // MARK: - CP Column

    @ViewBuilder
    private func cpColumn(
        name: String, attribute: Attribute,
        baseCP: Int, effectiveCP: Int,
        terrainBonus: Int, multiplier: Double, shield: Int
    ) -> some View {
        VStack(spacing: 3) {
            // 이름 + 속성
            HStack(spacing: 2) {
                Text(attribute.emoji)
                    .font(.system(size: 11))
                Text(name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            // 기본 CP
            Text("\(baseCP)")
                .font(.system(size: 9))
                .foregroundColor(.gray)

            // 보정 내역
            if terrainBonus != 0 {
                Text("지형 \(terrainBonus > 0 ? "+" : "")\(terrainBonus)")
                    .font(.system(size: 8))
                    .foregroundColor(.cyan)
            }

            if multiplier != 1.0 {
                Text("상성 x\(String(format: "%.1f", multiplier))")
                    .font(.system(size: 8))
                    .foregroundColor(multiplier > 1.0 ? .green : .red)
            }

            if shield > 0 {
                HStack(spacing: 1) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 7))
                    Text("\(shield)")
                        .font(.system(size: 8))
                }
                .foregroundColor(.cyan)
            }

            // 최종 유효 CP
            Text("\(effectiveCP)")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(.orange)
        }
        .frame(minWidth: 80)
    }

    // MARK: - LP 데미지 예상

    @ViewBuilder
    private var lpDamageRow: some View {
        let attackDamage = max(0, preview.attackerEffectiveCP - preview.defenderShield)
        let diff = attackDamage - preview.defenderEffectiveCP

        if diff > 0 {
            Text("상대 LP -\(diff)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.green)
        } else if diff < 0 {
            Text("내 LP \(diff)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.red)
        } else {
            Text("양쪽 파괴")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.yellow)
        }
    }
}
