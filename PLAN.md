# 덱 빌더 UI 개선 계획

## 1. 상단 패딩 겹침 수정

### 문제
- `DeckBuilderView`가 `TabView` 내부에 직접 배치됨 (NavigationStack 없음)
- `deckStatusBar`의 상단 패딩이 `8pt`로 너무 작아 상단 safe area와 겹침

### 해결
- `DeckBuilderView.swift`의 VStack 콘텐츠 영역에 `.safeAreaInset` 또는 상단 패딩 증가
- `deckStatusBar`의 `.padding(.top, 8)` → `.padding(.top, 16)` 이상으로 조정
- 또는 VStack 전체에 `.padding(.top)` 추가하여 safe area 확보

### 변경 파일
- `Momentum Clash/Views/DeckBuilderView.swift` — deckStatusBar 상단 패딩 조정

---

## 2. 프리셋 덱 선택 기능

### 개요
사용자가 빠르게 덱을 구성할 수 있도록 미리 정의된 덱 프리셋을 제공하는 기능 추가.

### UI 흐름
1. 덱 현황 바 영역에 **"프리셋"** 버튼 추가 (초기화 버튼 옆)
2. 버튼 탭 → `.sheet`로 프리셋 목록 표시
3. 프리셋 선택 시 기존 덱을 해당 프리셋으로 교체 (확인 다이얼로그)
4. sheet 닫힘

### 프리셋 덱 구성 (기존 SampleCards 데이터 활용)

이미 코드베이스에 `SampleDecks.fireRush`와 `SampleDecks.earthFortress`가 정의되어 있음. 추가로 1~2개 더 만들어 총 4개 프리셋 제공:

| 프리셋 이름 | 컨셉 | 주요 속성 |
|------------|------|----------|
| 화염 러시 (기존) | 공격적 저코스트 러시 | 화/풍/뇌 |
| 대지 요새 (기존) | 방어적 고체력 지구전 | 지/수/광 |
| 뇌광 폭풍 (신규) | 뇌+광 시너지, 테라인 장악 | 뇌/광/수 |
| 암흑 지배 (신규) | 암+화 공격, 실드 제거 | 암/화/지 |

### 구현 파일

#### `Momentum Clash/Data/SampleCards.swift` (또는 별도 파일)
- 신규 프리셋 2개 추가 (`thunderStorm`, `darkDomination`)
- 프리셋 메타데이터 (이름, 설명, 아이콘/컬러) 추가

#### `Momentum Clash/ViewModels/DeckViewModel.swift`
- `loadPreset(_ preset: [AnyCard])` 메서드 추가
- 기존 덱 교체 로직

#### `Momentum Clash/Views/DeckBuilderView.swift`
- `@State private var showPresetSheet = false` 추가
- deckStatusBar에 "프리셋" 버튼 추가
- `.sheet` modifier로 프리셋 선택 UI 연결

#### `Momentum Clash/Views/PresetDeckSheet.swift` (신규)
- 프리셋 목록 표시 (이름, 설명, 속성 아이콘, 카드 수)
- 선택 시 콜백으로 프리셋 반환

---

## 변경 요약

| 파일 | 변경 내용 |
|------|----------|
| `DeckBuilderView.swift` | 상단 패딩 증가 + 프리셋 버튼 + sheet 연결 |
| `DeckViewModel.swift` | `loadPreset()` 메서드 추가 |
| `SampleCards.swift` | 신규 프리셋 2개 + 프리셋 메타데이터 |
| `PresetDeckSheet.swift` (신규) | 프리셋 선택 UI |
