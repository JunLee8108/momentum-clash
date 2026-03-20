import SwiftUI

/// 프리셋 덱 선택 시트
struct PresetDeckSheet: View {
    let onSelect: (SampleCards.PresetDeck) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.14)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(SampleCards.presetDecks) { preset in
                            presetRow(preset)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("프리셋 덱")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func presetRow(_ preset: SampleCards.PresetDeck) -> some View {
        Button {
            onSelect(preset)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Text(preset.emoji)
                    .font(.system(size: 32))
                    .frame(width: 50, height: 50)
                    .background(accentColor(preset).opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text(preset.description)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(accentColor(preset).opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func accentColor(_ preset: SampleCards.PresetDeck) -> Color {
        switch preset.accentColorName {
        case "red": return .red
        case "brown": return .brown
        case "yellow": return .yellow
        case "purple": return .purple
        default: return .white
        }
    }
}
