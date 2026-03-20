# A안: 기력 전용 소환 시스템 구현 계획

## 핵심 변경 사항
- **카드 소환/마법 발동**: 기력(Energy)으로만 비용 지불
- **기세(Momentum)**: 기세 스킬 전용 자원으로 분리 (소환에 사용 불가)
- **기력 밸런스 조정**: 기본 기력을 1 상향 (고비용 카드 소환 가능성 확보)
- **카드 UI 개선**: 패/상세보기에서 비용 옆에 기력 아이콘 추가

## 기력 밸런스 변경

| LP 비율 | 현재 기력 | 변경 후 기력 |
|---------|----------|------------|
| 50% 초과 | 2 | **3** |
| 25~50% | 3 | **4** |
| 25% 이하 | 4 | **5** |

> 비용 5 카드는 LP 25% 이하(위기 상황)에서만 1턴에 소환 가능 → 역전 메커니즘 유지

---

## 파일별 변경 계획

### 1. `MomentumSystem.swift` — 기력 상수 조정
- `baseEnergy` 상수: `2` → `3`
- `baseEnergy(currentLP:maxLP:)` 함수:
  - LP ≤ 25%: `4` → `5`
  - LP 25~50%: `3` → `4`
  - LP > 50%: `2` → `3` (baseEnergy 반환)
- 주석 수정: "카드 소환 비용이자" → "기세 스킬 자원" (기세는 소환에 미사용)

### 2. `TurnSystem.swift` — 비용 지불 로직 변경
- **`canPayCost`**: 파라미터에서 `currentMomentum` 제거, `currentEnergy >= cost`로 변경
- **`payCost`**: 기력만 차감하도록 단순화
  - 반환 타입: `(energySpent: Int, momentumSpent: Int)?` → `Int?` (소모된 기력만 반환)
  - `player.momentum` 차감 코드 제거
- 주석 업데이트

### 3. `GameViewModel.swift` — 플레이어 비용 검사/로그 변경
- **`useCardFromDetail()`**: `player.energy + player.momentum` → `player.energy`
  - 로그: `"자원이 부족합니다!"` → `"기력이 부족합니다! (비용: X, 기력: Y)"`
- **`canUseCard()`**: `player.energy + player.momentum` → `player.energy`
- **`summonToSlot()`**: 로그 `[기력 -X, 기세 -Y]` → `[기력 -X]`, payment 타입 맞춤
- **`executeSpell()`**: 로그 `[기력 -X, 기세 -Y]` → `[기력 -X]`, payment 타입 맞춤
- **`performAITurnAnimated()`**: `TurnSystem.payCost` 반환값 타입 맞춤

### 4. `BasicAI.swift` — AI 비용 계산 변경
- **`performMainPhase()`**: `energy + momentum` → `energy`만 사용
- **`planMainPhase()`**:
  - `simulatedMomentum` 변수 제거
  - `totalResource = simulatedEnergy + simulatedMomentum` → `simulatedEnergy`
  - 비용 시뮬레이션에서 momentum 차감 코드 제거

### 5. `CardView.swift` — 패 카드 비용 표시에 기력 아이콘 추가
- 현재: 파란 원 안에 숫자만 (`Text("\(card.cost)")`)
- 변경: 번개 아이콘(⚡ `bolt.circle.fill`) + 숫자를 함께 표시
  - PlayerInfoView의 기력 아이콘과 동일한 `bolt.circle.fill` 사용 → 시각적 일관성
  - 파란 원 배경 유지, 안에 아이콘+숫자 또는 아이콘을 옆에 배치

### 6. `CardDetailView.swift` — 상세보기 비용 표시 개선
- 현재: `bolt.circle.fill` 아이콘 + "비용: X" 텍스트 (이미 아이콘 있음)
- 변경: "비용: X" → "기력: X" 으로 문구 변경 (자원 이름 명확화)

---

## 변경하지 않는 것
- **기세 스킬 시스템**: 그대로 유지 (기세로만 발동, UI 버튼은 별도 작업)
- **기세 획득/감소 메커니즘**: 그대로 유지 (공격, 지형, 자연감소 등)
- **카드 비용 범위 (1~5)**: 유지
- **PlayerInfoView UI**: 기세/기력 모두 표시 유지 (역할만 분리)
- **Player.swift의 기세 메서드** (`gainMomentum`, `loseMomentum`): 유지

---

## 수정 영향 범위 요약

| 파일 | 변경 규모 |
|------|----------|
| `MomentumSystem.swift` | 상수 3개 + 주석 |
| `TurnSystem.swift` | 함수 2개 시그니처/로직 |
| `GameViewModel.swift` | 비용 검사 2곳 + 로그 2곳 + AI소환 1곳 |
| `BasicAI.swift` | 비용 계산 2곳 (performMainPhase, planMainPhase) |
| `CardView.swift` | 비용 배지에 기력 아이콘 추가 |
| `CardDetailView.swift` | "비용" → "기력" 문구 변경 |
