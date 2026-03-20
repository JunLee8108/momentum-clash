import SwiftUI

/// 나의 덱 관리 시트
struct SavedDeckSheet: View {
    let currentDeck: [AnyCard]
    let isDeckValid: Bool
    let onLoad: ([AnyCard]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var savedDecks: [SavedDeck] = []
    @State private var showSaveAlert = false
    @State private var deckName = ""
    @State private var editingDeckId: UUID? = nil
    @State private var showDeleteConfirm = false
    @State private var deletingDeck: SavedDeck? = nil
    @State private var showOverwriteConfirm = false
    @State private var overwriteTarget: SavedDeck? = nil

    var body: some View {
        VStack(spacing: 0) {
            headerView
            contentView
        }
        .onAppear { savedDecks = SavedDeckStore.loadAll() }
        .alert("덱 이름 입력", isPresented: $showSaveAlert) {
            TextField("예: 나의 화염덱", text: $deckName)
            Button("저장") { saveCurrentDeck() }
            Button("취소", role: .cancel) { deckName = "" }
        } message: {
            Text("저장할 덱의 이름을 입력하세요")
        }
        .alert("덱 삭제", isPresented: $showDeleteConfirm) {
            Button("삭제", role: .destructive) { confirmDelete() }
            Button("취소", role: .cancel) { }
        } message: {
            if let deck = deletingDeck {
                Text("'\(deck.name)' 덱을 삭제하시겠습니까?")
            }
        }
        .alert("덮어쓰기", isPresented: $showOverwriteConfirm) {
            Button("덮어쓰기", role: .destructive) { confirmOverwrite() }
            Button("취소", role: .cancel) { overwriteTarget = nil }
        } message: {
            if let deck = overwriteTarget {
                Text("'\(deck.name)' 덱을 현재 덱으로 덮어쓰시겠습니까?")
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("나의 덱")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Text("\(savedDecks.count)/\(SavedDeckStore.maxSlots)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

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
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 10) {
                // 현재 덱 저장 버튼
                saveButton

                if savedDecks.isEmpty {
                    emptyStateView
                } else {
                    ForEach(savedDecks) { deck in
                        savedDeckRow(deck)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            if savedDecks.count >= SavedDeckStore.maxSlots {
                // 슬롯이 없으면 아무것도 안 함
            } else {
                deckName = ""
                showSaveAlert = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 14))
                Text("현재 덱 저장")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(canSave ? .cyan : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .liquidGlass(cornerRadius: 14, opacity: 0.5)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(canSave ? Color.cyan.opacity(0.4) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(!canSave)
        .opacity(canSave ? 1.0 : 0.5)
    }

    private var canSave: Bool {
        isDeckValid && savedDecks.count < SavedDeckStore.maxSlots
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundColor(.gray)
            Text("저장된 덱이 없습니다")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Text("덱을 완성하고 저장해보세요!")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding(.top, 30)
    }

    // MARK: - Saved Deck Row

    private func savedDeckRow(_ deck: SavedDeck) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(deck.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                Text("몬스터 \(deck.monsterCount) / 마법 \(deck.spellCount)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            // 속성 뱃지
            HStack(spacing: 6) {
                ForEach(deck.mainAttributes, id: \.self) { attr in
                    Text(attr.emoji)
                        .font(.system(size: 12))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(attr.color.opacity(0.25))
                        .clipShape(Capsule())
                }

                Spacer()

                // 날짜
                Text(formatDate(deck.createdAt))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
            }

            // 액션 버튼
            HStack(spacing: 8) {
                // 불러오기
                Button {
                    onLoad(deck.cards)
                    dismiss()
                } label: {
                    Label("불러오기", systemImage: "arrow.down.doc.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.cyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.cyan.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // 덮어쓰기
                Button {
                    overwriteTarget = deck
                    showOverwriteConfirm = true
                } label: {
                    Label("덮어쓰기", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(!isDeckValid)
                .opacity(isDeckValid ? 1.0 : 0.5)

                // 삭제
                Button {
                    deletingDeck = deck
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(14)
        .liquidGlass(cornerRadius: 14, opacity: 0.5)
    }

    // MARK: - Actions

    private func saveCurrentDeck() {
        let trimmed = deckName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newDeck = SavedDeck(
            id: UUID(),
            name: trimmed,
            cards: currentDeck,
            createdAt: Date()
        )
        SavedDeckStore.save(newDeck)
        savedDecks = SavedDeckStore.loadAll()
        deckName = ""
    }

    private func confirmDelete() {
        guard let deck = deletingDeck else { return }
        SavedDeckStore.delete(id: deck.id)
        savedDecks = SavedDeckStore.loadAll()
        deletingDeck = nil
    }

    private func confirmOverwrite() {
        guard let target = overwriteTarget else { return }
        let updated = SavedDeck(
            id: target.id,
            name: target.name,
            cards: currentDeck,
            createdAt: Date()
        )
        SavedDeckStore.save(updated)
        savedDecks = SavedDeckStore.loadAll()
        overwriteTarget = nil
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}
