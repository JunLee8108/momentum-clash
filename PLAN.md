# 데이터 기반 효과 시스템 리팩토링 계획

## 현재 문제

`GameViewModel.swift`에 **18개 카드 효과**가 `card.name` 문자열 기반 `switch/case`로 하드코딩됨.
- 4성 효과: 6곳 (lines 1301-1419)
- 5성 효과: 7곳 (lines 1497-1553)
- 주문 효과: 3곳 (lines 411-434) + 지형 주문 7곳 (lines 451-522)
- 파괴 효과: 죽음의 기사 **4곳에 중복** (lines 675, 701, 1103, 1122)
- 미구현 효과: 11개 카드 (description만 있고 실제 로직 없음)

---

## 리팩토링 전략

### Step 1: `EffectAction` / `EffectTarget` 열거형 정의 (Card.swift)

현재 `CardEffect`는 `timing + description(String)` 뿐.
**실제 동작을 데이터로 표현**하는 열거형을 추가한다.

```swift
/// 효과가 적용되는 대상
enum EffectTarget: String, Codable {
    case selfSlot       // 자기 자신 슬롯
    case allAllies      // 아군 전체
    case selectAlly     // 아군 1체 선택 (AI: 최강 아군 자동)
    case selectEnemy    // 적 1체 선택 (AI: 최강 적 자동)
    case strongestEnemy // 적 중 가장 강한 1체
    case allEnemies     // 적 전체
    case player         // 자기 플레이어 (LP/기세 등)
    case opponent       // 상대 플레이어 (LP/기세 등)
    case destroyer      // 자신을 파괴한 몬스터
}

/// 효과 행동
enum EffectAction: Codable, Equatable {
    case healLP(Int)              // LP 회복
    case damageLP(Int)            // LP 데미지
    case applyShield(Int)         // 방어막 부여
    case cpDebuff(Int)            // CP 디버프
    case cpBuff(Int)              // CP 버프
    case drawCards(Int)           // 카드 드로우
    case gainMomentum(Int)        // 기세 획득
    case loseMomentum(Int)        // 기세 감소
    case fieldOverride            // 필드 오버라이드 (카드 속성 사용)
    case removeAllShields         // 방어막 전체 제거
    case destroyIfCPBelow(Int)    // CP 이하면 파괴
    case momentumBonus(Int)       // 이번 턴 전투력 보너스
}
```

`CardEffect` 확장:

```swift
struct EffectActionEntry: Codable, Equatable {
    let action: EffectAction
    let target: EffectTarget
}

struct CardEffect: Codable, Equatable {
    let timing: EffectTiming
    let description: String        // UI 표시용 (유지)
    let actions: [EffectActionEntry] // NEW: 실제 동작 리스트
}
```

---

### Step 2: `EffectEngine.swift` 생성 (Engine/)

`GameViewModel`에서 효과 로직을 분리하여 **독립된 효과 엔진** 생성.

```swift
struct EffectContext {
    let playerIndex: Int
    let opponentIndex: Int
    let slotIndex: Int
    let isPlayer: Bool
    let cardAttribute: Attribute
    let battleInfo: BattleInfo?  // onDestroy/onAttack 시
}

struct EffectResult {
    let message: String
    let emoji: String
    let showLPFlash: Bool
    let highlightedSlot: Int?
}

class EffectEngine {
    /// 타겟 선택이 필요한지 확인
    func needsPlayerTargetSelection(_ actions: [EffectActionEntry]) -> EffectTarget?

    /// 효과 실행 (선택된 타겟 슬롯 전달)
    func resolve(
        actions: [EffectActionEntry],
        context: EffectContext,
        gameState: inout GameState,
        selectedTargetSlot: Int?
    ) -> [EffectResult]
}
```

핵심 로직 - `resolve()` 내부:

```swift
for entry in actions {
    switch entry.action {
    case .healLP(let amount):
        let idx = (entry.target == .player) ? context.playerIndex : context.opponentIndex
        gameState.players[idx].lp = min(TurnSystem.startingLP, gameState.players[idx].lp + amount)

    case .damageLP(let amount):
        let idx = (entry.target == .opponent) ? context.opponentIndex : context.playerIndex
        gameState.players[idx].lp -= amount

    case .applyShield(let amount):
        let slots = resolveTargetSlots(entry.target, context, gameState, selectedTargetSlot)
        for slot in slots { gameState.players[targetPlayerIdx].field.applyShield(amount, at: slot) }

    case .cpDebuff(let amount):
        let slots = resolveTargetSlots(entry.target, context, gameState, selectedTargetSlot)
        for slot in slots { gameState.players[targetPlayerIdx].field.applySlotCpDebuff(amount, at: slot) }

    // ... 나머지 action도 동일 패턴
    }
}
```

---

### Step 3: `SampleCards.swift` 카드 데이터 업데이트

모든 42개 카드에 `actions` 배열을 추가. 효과 없는 카드는 빈 배열.

**4성 예시:**
```swift
// 염룡: 상대 1체 CP -400 (타겟 선택)
effect: CardEffect(timing: .onSummon, description: "소환 시 상대 몬스터 1체의 전투력 -400",
    actions: [EffectActionEntry(action: .cpDebuff(-400), target: .selectEnemy)])

// 빙결 용사: LP 300 회복
effect: CardEffect(timing: .onSummon, description: "소환 시 아군 LP 300 회복",
    actions: [EffectActionEntry(action: .healLP(300), target: .player)])
```

**5성 예시:**
```swift
// 지옥 기사: 필드 오버라이드 + LP 500 데미지
effect: CardEffect(timing: .onSummon, description: "...",
    actions: [
        EffectActionEntry(action: .fieldOverride, target: .selfSlot),
        EffectActionEntry(action: .damageLP(500), target: .opponent)
    ])
```

**파괴 시 예시:**
```swift
// 죽음의 기사: 파괴한 몬스터 CP -300
effect: CardEffect(timing: .onDestroy, description: "파괴 시 자신을 파괴한 몬스터의 전투력 -300",
    actions: [EffectActionEntry(action: .cpDebuff(-300), target: .destroyer)])

// 어둠 박쥐: 상대 LP 200 데미지
effect: CardEffect(timing: .onDestroy, description: "파괴 시 상대에게 LP 200 데미지",
    actions: [EffectActionEntry(action: .damageLP(200), target: .opponent)])
```

**지형 주문 예시:**
```swift
// 화염 폭풍: 상대 전체 CP 200 이하 파괴
effect: CardEffect(timing: .onSummon, description: "...",
    actions: [EffectActionEntry(action: .destroyIfCPBelow(200), target: .allEnemies)])

// 치유의 비: LP 300 회복
effect: CardEffect(timing: .onSummon, description: "...",
    actions: [EffectActionEntry(action: .healLP(300), target: .player)])
```

---

### Step 4: `GameViewModel.swift` 리팩토링

**제거할 코드:**

| 메서드/코드 | 줄 | 대체 방식 |
|---|---|---|
| `applyFourStarSummonEffect()` | 1297-1419 | `EffectEngine.resolve()` |
| `applyFiveStarSummonEffect()` | 1486-1579 | 5성 공통 처리 + `EffectEngine.resolve()` |
| `applySpellEffect()` switch | 411-434 | `EffectEngine.resolve()` |
| `applyTerrainSpell()` 속성별 switch | 451-522 | actions 데이터로 대체 |
| 죽음의 기사 하드코딩 4곳 | 675, 701, 1103, 1122 | `onDestroy` 효과 자동 발동 |

**새 통합 호출:**
```swift
// 소환 시 효과 (4성/5성 통합)
private func handleSummonEffect(card: MonsterCard, slot: Int, playerIndex: Int) {
    guard let effect = card.effect, effect.timing == .onSummon else { return }

    // 5성: 공통 필드 오버라이드 처리 (fieldOverride action으로)
    // 타겟 선택 필요 시 UI 표시
    if let targetType = effectEngine.needsPlayerTargetSelection(effect.actions),
       playerIndex == 0 {
        uiState = .selectingEffectTarget(...)
        return
    }

    let results = effectEngine.resolve(actions: effect.actions, context: ..., gameState: &gameState)
    showEffectResults(results)
}

// 파괴 시 효과 (죽음의 기사 등 - 전투 결과 처리에서 자동 호출)
private func handleDestroyEffect(card: MonsterCard, destroyerSlot: Int, ...) {
    guard let effect = card.effect, effect.timing == .onDestroy else { return }
    let results = effectEngine.resolve(actions: effect.actions, context: ..., gameState: &gameState)
    showEffectResults(results)
}
```

**→ 플레이어 전투/AI 전투 양쪽 모두 `handleDestroyEffect()` 한 곳만 호출하면 됨 (4곳 → 1곳)**

---

### Step 5: 미구현 11개 카드 자동 활성화

actions 데이터만 추가하면 **코드 변경 없이** 자동 동작:

| 카드 | timing | actions |
|------|--------|---------|
| 바람 요정 | onDestroy | `drawCards(1), .player` |
| 어둠 박쥐 | onDestroy | `damageLP(200), .opponent` |
| 그림자 도적 | onDestroy | `loseMomentum(1), .opponent` |
| 빛의 반딧불 | onSummon | `healLP(200), .player` |
| 성광 사제 | onSummon | `applyShield(500), .selectAlly` |
| 성기사 | onSummon | `cpBuff(100), .allAllies` |
| 뇌격 여우 | onAttack | `loseMomentum(1), .opponent` |
| 뇌수 | onAttack | `cpDebuff(-200), .destroyer` |
| 화산 마도사 | onSummon | `destroyIfCPBelow(300), .selectEnemy` |
| 저주술사 | onSummon | `cpDebuff(-200), .selectEnemy` |
| 안개 정령 | onSummon | (지형 변경 - 향후 확장) |

---

## 파일 변경 요약

| 파일 | 변경 내용 |
|------|----------|
| `Models/Card.swift` | `EffectAction`, `EffectTarget`, `EffectActionEntry` 추가. `CardEffect`에 `actions` 필드 추가 |
| `Engine/EffectEngine.swift` | **신규 생성**. 효과 해석/실행 엔진 |
| `Data/SampleCards.swift` | 42개 카드에 `actions` 데이터 추가 |
| `ViewModels/GameViewModel.swift` | 하드코딩 switch/case 제거 → `EffectEngine` 호출. 죽음의 기사 4곳 → 1곳 통합 |

## 작업 순서

1. `Card.swift` - 새 타입 정의 (EffectAction, EffectTarget, EffectActionEntry)
2. `CardEffect` - actions 필드 추가 (기존 description은 유지)
3. `EffectEngine.swift` 생성 - 효과 해석/실행 로직
4. `SampleCards.swift` - 모든 카드에 actions 데이터 입력
5. `GameViewModel.swift` - 소환 효과 통합 (4성/5성 → EffectEngine)
6. `GameViewModel.swift` - 주문 효과 통합 (terrain + normal → EffectEngine)
7. `GameViewModel.swift` - 파괴/공격 효과 통합 (onDestroy/onAttack → EffectEngine)
8. 미구현 11개 카드 효과 활성화
9. 기존 동작과 동일한지 빌드 검증
