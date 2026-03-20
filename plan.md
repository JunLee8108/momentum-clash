# 기세스킬 UI 구현 계획

## 목표
메인 페이즈에서 플레이어가 기세스킬 4종(투지/지형장악/전선돌파/기세폭발)을 선택·발동할 수 있는 UI 구현

> doubleAttack, fullAwakening은 이번 작업에서 제외

---

## UI 동작 흐름

```
메인 페이즈 → [기세 스킬] 버튼 탭
  → 스킬 선택 패널 표시 (하단 오버레이)
    → 스킬 카드 4개 가로 나열
    → 기세 부족한 스킬은 비활성(회색)
    → 스킬 탭 → useMomentumSkill() 호출 → 패널 닫힘
    → 바깥 탭 or 닫기 → 패널 닫힘
```

---

## 파일별 변경 계획

### 1. `GameBoardView.swift` — 액션 버튼에 "기세 스킬" 추가 + 패널 토글

**변경 위치**: `actionButtons` → `.mainPhase` 케이스

```
현재: [배틀 페이즈] [턴 종료]
변경: [기세 스킬] [배틀 페이즈] [턴 종료]
```

- `@State private var showMomentumSkillPanel = false` 추가
- "기세 스킬" 버튼: 오렌지색, `flame.fill` 아이콘 + "기세 스킬" 텍스트
  - 기세 0이면 비활성 (disabled)
- 버튼 탭 시 `showMomentumSkillPanel.toggle()`

**오버레이 추가**: ZStack 내에 `MomentumSkillPanel` 표시
- `showMomentumSkillPanel == true`일 때 표시
- 반투명 배경 + 하단에서 슬라이드업
- 패널 바깥 탭 시 닫기

### 2. `MomentumSkillPanel.swift` — 새 파일 생성

스킬 선택 패널 View:

```
┌──────────────────────────────────────┐
│          ✕ 기세 스킬 (🔥 5)          │
├──────────────────────────────────────┤
│ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ │
│ │ 🔥 3   │ │ 🔥 4   │ │ 🔥 6   │ │ 🔥 8   │ │
│ │  투지  │ │지형장악│ │전선돌파│ │기세폭발│ │
│ │ +500CP │ │지형2배 │ │전체+300│ │전체DMG │ │
│ └────────┘ └────────┘ └────────┘ └────────┘ │
└──────────────────────────────────────┘
```

**구성 요소**:
- 헤더: "기세 스킬" 타이틀 + 현재 기세 표시 + 닫기(✕) 버튼
- 스킬 카드 4개: `LazyVGrid` 또는 `HStack`으로 가로 배치
  - 각 카드: 비용(🔥 숫자), 스킬 이름, 한 줄 설명
  - 사용 가능: 오렌지 테두리 + 탭 가능
  - 기세 부족: 회색 + opacity 0.4 + disabled
- 탭 시: `viewModel.useMomentumSkill(skill)` 호출 → `showPanel = false`

**표시할 스킬 배열** (하드코딩):
```swift
let availableSkills: [MomentumSkill] = [.fighting, .terrainMastery, .breakthrough, .explosion]
```

**스킬 카드 색상 테마**: 전부 오렌지/불꽃 계열 (기세의 시각적 아이덴티티)

### 3. `GameViewModel.swift` — 변경 없음

`useMomentumSkill()` 함수가 이미 4개 스킬 로직 완성됨. UI에서 호출만 하면 됨.

---

## 변경 파일 요약

| 파일 | 작업 | 규모 |
|------|------|------|
| `GameBoardView.swift` | 기세 스킬 버튼 + 패널 오버레이 토글 | 소 |
| `MomentumSkillPanel.swift` | **새 파일** — 스킬 선택 패널 | 중 |

---

## 미포함 (향후)
- `doubleAttack` (연속 공격) — 타겟 선택 UI 필요
- `fullAwakening` (완전 각성) — 타겟 선택 + 각성 데이터 필요
