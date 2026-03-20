import SwiftUI

/// 프리셋 덱 선택 시트
struct PresetDeckSheet: View {
    let onSelect: (SampleCards.PresetDeck) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text("프리셋 덱")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.gray, Color.white.opacity(0.15))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // 프리셋 목록
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(SampleCards.presetDecks) { preset in
                        presetRow(preset)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    private func presetRow(_ preset: SampleCards.PresetDeck) -> some View {
        Button {
            onSelect(preset)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(preset.emoji + " " + preset.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Text("30장")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }

                Text(preset.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // 속성 뱃지
                HStack(spacing: 6) {
                    ForEach(mainAttributes(preset), id: \.self) { attr in
                        Text(attr.emoji)
                            .font(.system(size: 12))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(attr.color.opacity(0.25))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(14)
            .liquidGlass(cornerRadius: 14, opacity: 0.5)
        }
    }

    /// 프리셋에 포함된 주요 속성 추출 (몬스터 기준, 중복 제거)
    private func mainAttributes(_ preset: SampleCards.PresetDeck) -> [Attribute] {
        var seen = Set<Attribute>()
        var result: [Attribute] = []
        for (card, _) in preset.monsters {
            if seen.insert(card.attribute).inserted {
                result.append(card.attribute)
            }
        }
        return result
    }
}
