# AI 전투/마법 로직 개선 계획

## 변경 1: 전투 타겟팅 — 약한 적 우선 공격

**파일:** `Momentum Clash/Engine/BasicAI.swift` → `chooseBestTarget()`

현재 Priority 1: 이길 수 있는 적 중 **가장 강한 적** 공격
변경 Priority 1: 이길 수 있는 적 중 **가장 약한 적** 공격

```swift
// 변경 전
if let best = winnable.max(by: { $0.defCP < $1.defCP }) {

// 변경 후
if let best = winnable.min(by: { $0.defCP < $1.defCP }) {
```

**효과:** 확실한 킬부터 처리 → 필드 빠르게 정리 → 직접 공격(기세+2) 기회 증가

---

## 변경 2: 마법 카드 유용성 판단

**파일:** `Momentum Clash/Engine/BasicAI.swift` → `planMainPhase()` + 새 헬퍼 함수

### 2-1. `shouldPlaySpell()` 헬퍼 함수 추가

마법 타입별 조건 체크:
| 마법 | 조건 | 불필요한 경우 |
|------|------|-------------|
| earthBarrier (방어막) | 필드에 몬스터 있어야 | 몬스터 0마리 |
| fireStorm (전체 데미지) | 상대 필드에 몬스터 있어야 | 상대 몬스터 0마리 |
| healingRain (LP회복) | LP가 최대의 70% 미만일 때 | LP가 충분할 때 |
| eternalFurnace (화속성 버프) | 화속성 몬스터가 있거나 핸드에 있을 때 | 관련 몬스터 없음 |
| earthEcho (지형 변경) | 해당 속성 몬스터가 있을 때 | 관련 몬스터 없음 |
| windBlade (장착) | 필드에 몬스터 있어야 | 몬스터 0마리 |
| thunderStrike (단일 데미지) | 상대 필드에 몬스터 있어야 | 상대 몬스터 0마리 |

### 2-2. 범용 판단 기준 (효과 키워드 기반)

카드가 계속 추가될 수 있으므로, description 키워드 + 게임 상태로 범용 판단:
- "방어막/shield" 효과 → 아군 몬스터 필요
- "데미지/damage" + 적 대상 → 상대 몬스터 필요
- "회복/heal" → LP < 70%
- "장착/equip" → 아군 몬스터 필요
- 지속 마법 → 관련 속성 몬스터가 아군 필드/핸드에 있어야
- 지형 마법 → 관련 속성 몬스터가 있어야

### 2-3. 우선순위 변경

몬스터 소환을 마법보다 우선:
```swift
// 변경 전: 마법 priority = cost * 200, 몬스터 = cost * 100
// 변경 후: 몬스터 priority = combatPower (기존 유지), 마법은 조건 충족 시에만 포함
```

조건 미충족 마법은 candidates에서 제외.
