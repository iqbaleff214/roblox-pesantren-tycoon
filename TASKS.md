# TASKS — Pesantren Tycoon

All tasks derived from `PRD.md`. Work in phase order — each phase's foundation is required before the next.

**Status legend:** `- [ ]` todo · `- [x]` done · `- [~]` in progress · `- [!]` blocked

---

## Phase 0 — Project Scaffolding

Create all source files and directories so subsequent tasks have a place to land. No logic yet — just stubs.

- [x] **T01 · Create src/ directory structure**

  Create every folder and stub file matching the layout in PRD §17.

  **Directories to create:**
  ```
  src/Server/Services/
  src/Server/Managers/
  src/Client/Controllers/
  src/Client/Components/
  src/Character/
  src/Shared/Modules/
  src/Shared/Data/
  src/Shared/Net/
  tests/
  ```

  **Stub files to create** (each file: `--!strict` header + empty module return):
  ```
  src/Server/init.server.luau
  src/Server/Services/DataService.luau
  src/Server/Services/EconomyService.luau
  src/Server/Services/EventService.luau
  src/Server/Services/ReplicationService.luau
  src/Server/Managers/SantriManager.luau
  src/Server/Managers/BuildingManager.luau
  src/Server/Managers/UstadzManager.luau
  src/Server/Managers/ReputationManager.luau
  src/Client/init.client.luau
  src/Client/Controllers/InputController.luau
  src/Client/Controllers/UIController.luau
  src/Client/Controllers/BuildController.luau
  src/Client/Controllers/NotifController.luau
  src/Client/Components/HUD.luau
  src/Client/Components/BuildMenu.luau
  src/Client/Components/SantriPanel.luau
  src/Client/Components/EventBanner.luau
  src/Character/init.client.luau
  src/Shared/Modules/Types.luau
  src/Shared/Modules/Constants.luau
  src/Shared/Modules/Utils.luau
  src/Shared/Modules/Network.luau
  src/Shared/Data/BuildingData.luau
  src/Shared/Data/SantriData.luau
  src/Shared/Data/UstadzData.luau
  src/Shared/Data/EventData.luau
  src/Shared/Net/Events.luau
  src/Shared/Net/Functions.luau
  ```

  **Done when:** `rojo build` runs without path errors.

- [x] **T02 · Define all Luau types in `Types.luau`**

  **File:** `src/Shared/Modules/Types.luau`

  Define strict types for every domain object the game uses. All other modules import from here — no inline type definitions elsewhere.

  **Required types:**

  ```luau
  --!strict

  export type Currency = "Rupiah" | "Barakah" | "Ilmu" | "Sanad"

  export type PlayerData = {
      rupiah: number,
      barakah: number,
      ilmu: number,
      sanad: number,
      reputation: number,
      prestigeCount: number,
      santriList: { [string]: SantriData },
      buildingList: { [string]: BuildingData },
      ustadzList: { [string]: UstadzData },
      alumniCount: number,
      sedekahJariyahPerMin: number,
      lastSaved: number,       -- Unix timestamp
  }

  export type SantriData = {
      id: string,
      program: SantriProgram,
      needMakan: number,       -- 0–100
      needIlmu: number,        -- 0–100
      needIbadah: number,      -- 0–100
      needIstirahat: number,   -- 0–100
      studyProgress: number,   -- 0–100 (toward ujian)
      enrollTime: number,
  }

  export type SantriProgram = "Tahfidz" | "KitabKuning" | "Bahasa" | "Wirausaha" | "Teknologi"

  export type BuildingData = {
      id: string,
      buildingType: BuildingType,
      level: number,           -- 1–5
      zone: number,            -- 1–5
      placedAt: number,
  }

  export type BuildingType =
      "Musholla" | "Dormitory" | "Education" | "Food" | "Economy" |
      "Library" | "Studio" | "LabKomputer" | "Klinik" | "Aula"

  export type UstadzData = {
      id: string,
      program: SantriProgram,
      skill: number,           -- 1–5
      kharisma: number,        -- 1–5
      fatigue: number,         -- 0–100 (100 = fully rested)
      rarity: UstadzRarity,
  }

  export type UstadzRarity = "Biasa" | "Terkenal" | "KyaiBesar" | "KyaiInternasional"

  export type MasalahEvent = {
      id: string,
      eventType: MasalahType,
      severity: number,        -- 1–3, drives penalty scale
      triggeredAt: number,
      resolved: boolean,
  }

  export type MasalahType = "SantriSakit" | "UstadzAbsen" | "BanjirAsrama"

  export type SeasonalEvent = "Ramadan" | "IdulFitri" | "IdulAdha" | "MaulidNabi" | "TahunBaru" | "IsraMiraj"
  ```

  **Done when:** File exports all types, `--!strict` passes with no errors, at least one other module successfully imports a type from here.

- [x] **T03 · Define all tuning constants in `Constants.luau`**

  **File:** `src/Shared/Modules/Constants.luau`

  Every numeric game value lives here. No magic numbers in scripts.

  **Required constants (initial values, tune during playtesting):**

  ```luau
  --!strict

  -- Economy
  RUPIAH_BASE_PER_SANTRI_PER_MIN = 10
  BARAKAH_BASE_PER_HAFIDZ_GRAD = 50
  ILMU_BASE_PER_SANTRI_PER_MIN = 5
  SEDEKAH_JARIYAH_PER_ALUMNI = 2        -- Rupiah/min per alumni, forever

  -- Santri needs (decay per minute)
  NEED_MAKAN_DECAY = 3
  NEED_ILMU_DECAY = 2
  NEED_IBADAH_DECAY = 2
  NEED_ISTIRAHAT_DECAY = 1

  -- Happiness thresholds
  HAPPINESS_PENALTY_THRESHOLD = 50      -- below this → income penalty
  HAPPINESS_DROPOUT_THRESHOLD = 20      -- below this → dropout risk
  HAPPINESS_BONUS_THRESHOLD = 90        -- above this → bonus Barakah

  -- Santri lifecycle
  STUDY_PROGRESS_PER_MIN = 5            -- per minute with ustadz present
  UJIAN_PASS_CHANCE_BASE = 0.7          -- 70% base pass rate

  -- Ustadz fatigue
  USTADZ_FATIGUE_DECAY_PER_HOUR = 10
  USTADZ_RESTED_THRESHOLD = 80

  -- Reputation
  REP_PER_GRADUATION = 2
  REP_PER_BUILDING_UPGRADE = 1
  REP_PER_MASALAH_FAST_RESOLVE = 3      -- resolved within 2 min
  REP_PER_VISITOR = 0.5
  REP_TIER_BERKEMBANG = 50
  REP_TIER_UNGGULAN = 75
  REP_TIER_PRESTIGE_UNLOCK = 100

  -- Events
  WAKTU_SHOLAT_INTERVAL_MIN = 288       -- 5 times per 1440 min (1 day)
  WAKTU_SHOLAT_DURATION_SEC = 60
  WAKTU_SHOLAT_MULTIPLIER = 3
  JUMAT_BERKAH_MULTIPLIER = 2
  JUMAT_BERKAH_DURATION_MIN = 30
  TABLIGH_AKBAR_MIN_PLAYERS = 10
  TABLIGH_AKBAR_MULTIPLIER = 5
  TABLIGH_AKBAR_DURATION_MIN = 5

  -- Zone unlock thresholds (santri count)
  ZONE_2_UNLOCK = 20
  ZONE_3_UNLOCK = 100
  ZONE_4_UNLOCK = 250
  ZONE_5_UNLOCK = 600

  -- Performance
  MAX_PARTS_PER_ZONE = 2000
  MAX_NETWORK_RPS = 20
  ```

  **Done when:** All constants defined, used in at least one other module, no hardcoded numbers in service/manager files.

- [x] **T04 · Define all RemoteEvents in `Events.luau`**

  **File:** `src/Shared/Net/Events.luau`

  All RemoteEvents created once here. No `Instance.new("RemoteEvent")` anywhere else.

  **Required events:**

  | Name | Direction | Payload |
  |---|---|---|
  | `PurchaseBuilding` | Client → Server | `buildingType, zone` |
  | `UpgradeBuilding` | Client → Server | `buildingId` |
  | `HireUstadz` | Client → Server | `program, rarityTier` |
  | `ResolveMasalah` | Client → Server | `masalahId` |
  | `BukaCabang` | Client → Server | _(none)_ |
  | `TriggerWaqf` | Client → Server | `amount: number` |
  | `VoteTabligAkbar` | Client → Server | _(none)_ |
  | `AcknowledgeWaktuSholat` | Client → Server | _(none)_ |
  | `TriggerQurban` | Client → Server | _(none)_ |
  | `SyncPlayerData` | Server → Client | `PlayerData` |
  | `NotifyMasalah` | Server → Client | `MasalahEvent` |
  | `NotifyEvent` | Server → Client | `eventType: string, payload: any` |
  | `NotifyGraduation` | Server → Client | `santriId, program` |
  | `NotifyKyaiBesar` | Server → All Clients | `ustadzName, pesantrenName` |

  Create each as a `RemoteEvent` instance under `ReplicatedStorage`. Return a typed table of references.

  **Done when:** All events accessible via `require(Events).PurchaseBuilding` etc., no other script creates RemoteEvents.

- [x] **T05 · Define all RemoteFunctions in `Functions.luau`**

  **File:** `src/Shared/Net/Functions.luau`

  | Name | Returns |
  |---|---|
  | `GetPlayerData` | `PlayerData` |
  | `GetLeaderboard` | `{ { player: string, value: number } }` |
  | `CheckGamePass` | `boolean` |

  **Done when:** All functions accessible via require, typed correctly.

---

## Phase 1 — Data Layer

- [x] **T06 · Implement `DataService` — save/load player data**

  **File:** `src/Server/Services/DataService.luau`

  Wraps `DataStoreService`. All other services call `DataService` to read/write player data — nothing else touches DataStores directly.

  **Required functions:**

  ```luau
  function DataService.loadPlayer(player: Player): PlayerData
  function DataService.savePlayer(player: Player): ()
  function DataService.getPlayerData(player: Player): PlayerData
  function DataService.updatePlayerData(player: Player, patch: { [string]: any }): ()
  ```

  **Implementation requirements:**
  - Use `DataStoreService:GetDataStore("PlayerData_v1")`.
  - On `loadPlayer`: attempt `pcall(store.GetAsync)`. On failure, retry up to 3 times with 1-second delay. If all retries fail, use default `PlayerData` and flag the player with `_loadFailed = true`.
  - On `savePlayer`: use `UpdateAsync` (not `SetAsync`) to avoid data overwrite race.
  - Auto-save every 5 minutes via a `while task.wait(300) do` loop per player.
  - On `Players.PlayerRemoving`: call `savePlayer` before the player leaves.
  - Default `PlayerData` for new players: `{ rupiah = 500, barakah = 0, ilmu = 0, sanad = 0, reputation = 0, prestigeCount = 0, santriList = {}, buildingList = {}, ustadzList = {}, alumniCount = 0, sedekahJariyahPerMin = 0, lastSaved = 0 }`.

  **Done when:** New player gets default data. Existing player data persists across server restarts. Save failure does not crash server.

- [x] **T07 · Implement `EconomyService` — currency transactions**

  **File:** `src/Server/Services/EconomyService.luau`

  Single point of truth for all currency mutations. No other script modifies currency directly.

  **Required functions:**

  ```luau
  function EconomyService.addCurrency(player: Player, currency: Currency, amount: number): ()
  function EconomyService.spendCurrency(player: Player, currency: Currency, amount: number): boolean
      -- returns false if insufficient balance, does NOT deduct
  function EconomyService.getCurrency(player: Player, currency: Currency): number
  function EconomyService.canAfford(player: Player, currency: Currency, amount: number): boolean
  ```

  **Implementation requirements:**
  - All functions call `DataService.getPlayerData` / `DataService.updatePlayerData` — never read workspace or module-level state.
  - `spendCurrency` must check balance before deducting. Return `false` without side effects if insufficient.
  - After any mutation, fire `ReplicationService.syncCurrencies(player)` to push updated values to client.
  - Log every transaction: `print(player.Name, currency, "+/-", amount)` for debugging.

  **Done when:** Client HUD reflects correct values after every earn/spend. Double-spend impossible (verified by calling spendCurrency twice rapidly on the server).

- [x] **T08 · Implement `ReplicationService` — sync server state to client**

  **File:** `src/Server/Services/ReplicationService.luau`

  Pushes game state snapshots to the owning client. Client never reads server state directly.

  **Required functions:**

  ```luau
  function ReplicationService.syncAll(player: Player): ()
  function ReplicationService.syncCurrencies(player: Player): ()
  function ReplicationService.broadcastToServer(eventName: string, payload: any): ()
  ```

  **Implementation requirements:**
  - `syncAll` fires `Events.SyncPlayerData` with full `PlayerData` table.
  - `syncCurrencies` fires `Events.SyncPlayerData` with only `{ rupiah, barakah, ilmu, sanad }` subset.
  - `broadcastToServer` iterates `Players:GetPlayers()` and fires the named event to each.
  - Call `syncAll` on player join (after DataService.loadPlayer completes).
  - Dirty-flag batching: mark player dirty instead of firing immediately. Flush on `RunService.Heartbeat`. Max one fire per player per frame — well under `MAX_NETWORK_RPS = 20`.

  **Done when:** Client HUD updates within 1 second of any server-side currency change.

- [x] **T09 · Populate all Data definition modules**

  **Files:**
  - `src/Shared/Data/BuildingData.luau`
  - `src/Shared/Data/SantriData.luau`
  - `src/Shared/Data/UstadzData.luau`
  - `src/Shared/Data/EventData.luau`

  **BuildingData.luau** — keyed by `BuildingType`. Each entry:

  ```luau
  {
      displayName: string,
      category: "Ibadah" | "Dormitory" | "Education" | "Food" | "Economy" | "Special",
      zone: number,
      tiers: {
          [number]: {
              cost: { currency: Currency, amount: number },
              capacity: number,
              incomeBonus: number,
              barakahBonus: number,
              ilmuBonus: number,
          }
      },
      unlockCondition: string | nil,
  }
  ```

  Include all buildings from PRD §4: Musholla→Masjid Internasional, Gubuk→Menara Santri, Tanah Lapang→Kampus Terpadu, Warung Kecil→Food Court Halal, Kebun Sayur→Pusat Bisnis, and all 5 Special buildings.

  **SantriData.luau** — keyed by `SantriProgram`:

  ```luau
  {
      displayName: string,
      generates: { currency: Currency, baseRate: number }[],
      alumniSedekahBonus: number,
      ujianPassBonus: number,
      requiredBuilding: BuildingType | nil,
  }
  ```

  **UstadzData.luau** — rarity roll table:

  ```luau
  {
      rarityWeights: { Biasa: 70, Terkenal: 22, KyaiBesar: 7, KyaiInternasional: 1 },
      rarityMultipliers: { Biasa: 1, Terkenal: 2, KyaiBesar: 5, KyaiInternasional: 10 },
      hireCost: {
          Biasa: { currency: "Rupiah", amount: 500 },
          Terkenal: { currency: "Barakah", amount: 20 },
          KyaiBesar: { currency: "Sanad", amount: 1 },
      },
  }
  ```

  **EventData.luau** — keyed by event name:

  ```luau
  {
      displayName: string,
      durationDays: number,
      barakahMultiplier: number,
      incomeMultiplier: number,
      reputationBonus: number,
      specialMechanic: string | nil,
  }
  ```

  **Done when:** All data tables load without error, types match `Types.luau` definitions.

---

## Phase 2 — Building System

- [x] **T10 · Implement `BuildingManager` — placement and zone unlock**

  **File:** `src/Server/Managers/BuildingManager.luau`

  **Required functions:**

  ```luau
  function BuildingManager.placeBuilding(player: Player, buildingType: BuildingType, zone: number): boolean
  function BuildingManager.upgradeBuilding(player: Player, buildingId: string): boolean
  function BuildingManager.getZoneUnlocked(player: Player): number
  function BuildingManager.checkZoneUnlock(player: Player): ()
  ```

  **Implementation requirements:**

  1. `placeBuilding`:
     - Validate `buildingType` is a valid `BuildingType` and `zone` is 1–5 (server-side — never trust client).
     - Check player's current zone vs building's required zone in `BuildingData`. Reject if locked.
     - Check `EconomyService.canAfford` for tier 1 cost. Spend if affordable.
     - Create `BuildingData` entry in player data via `DataService.updatePlayerData`.
     - Spawn placeholder Part in workspace tagged via `CollectionService:AddTag(part, buildingType)`.
     - Set attributes: `part:SetAttribute("buildingId", id)`, `buildingLevel = 1`, `ownerId = player.UserId`.
     - Attach `ProximityPrompt`: `ActionText = "Lihat Info"`, `KeyboardKeyCode = Enum.KeyCode.E`, `GamepadKeyCode = Enum.KeyCode.ButtonX`, `MaxActivationDistance = 10`.
     - Fire `ReplicationService.syncAll(player)`.

  2. `upgradeBuilding`:
     - Lookup building by `buildingId` in player data. Reject if level 5.
     - Check and spend upgrade cost from `BuildingData` tier table.
     - Increment `buildingLevel` attribute on workspace part.
     - Call `ReputationManager.addReputation(player, REP_PER_BUILDING_UPGRADE)`.

  3. `checkZoneUnlock`:
     - Count total santri. Compare against zone thresholds in Constants.
     - If new zone unlocked, fire `Events.NotifyEvent { eventType = "ZoneUnlocked" }` to client.

  **Done when:** Player can place a Musholla, upgrade it to level 2, and receive zone 2 unlock notification at 20 santri.

- [x] **T11 · Add BillboardGui to buildings**

  **File:** `src/Client/Controllers/BuildController.luau`

  **Implementation requirements:**
  - Listen for `CollectionService:GetInstanceAddedSignal("Building")` on the client.
  - On tagged part appear: create `BillboardGui` parented to it. `Size = UDim2.new(0, 120, 0, 40)`, `StudsOffset = Vector3.new(0, 5, 0)`, `AlwaysOnTop = false`.
  - `TextLabel` inside: `Text = buildingType .. " Lv." .. level`, `TextScaled = true`, `BackgroundTransparency = 1`.
  - Update label when `buildingLevel` attribute changes (`part:GetAttributeChangedSignal`).
  - No hardcoded pixel sizes — Scale-based only.

  **Done when:** All placed buildings show a floating label that updates on upgrade.

- [x] **T12 · Add SurfaceGui income display to economy/food buildings**

  **File:** `src/Client/Controllers/BuildController.luau`

  **Implementation requirements:**
  - For parts tagged `"FoodBuilding"` or `"EconomyBuilding"`, create a `SurfaceGui` on `Enum.NormalId.Front`.
  - `TextLabel` displays `"+Rp " .. incomeRate .. "/min"`. `TextScaled = true`.
  - Update value on every `SyncPlayerData` event receive.

  **Done when:** Warung Kecil front face shows income rate. Value updates when building is upgraded.

---

## Phase 3 — Santri System

- [x] **T13 · Implement `SantriManager` — spawn and enroll**

  **File:** `src/Server/Managers/SantriManager.luau`

  **Required functions:**

  ```luau
  function SantriManager.enrollSantri(player: Player, program: SantriProgram): boolean
  function SantriManager.getSantriCount(player: Player): number
  function SantriManager.getMaxCapacity(player: Player): number
  function SantriManager.dropoutSantri(player: Player, santriId: string): ()
  ```

  **Implementation requirements:**
  - `enrollSantri`: check `getSantriCount < getMaxCapacity`. Create `SantriData` with all needs at 100, `studyProgress = 0`. Add to player data. Call `BuildingManager.checkZoneUnlock`.
  - Auto-enroll: when reputation ≥ 50, enroll one santri every 5 minutes automatically. Program chosen randomly weighted by available ustadz programs.
  - `dropoutSantri`: remove from player data. Fire `Events.NotifyEvent { eventType = "SantriDropout" }`.

  **Done when:** Manual enroll works. Auto-enroll activates at rep 50. Enrolling beyond dormitory cap is rejected.

- [x] **T14 · Implement santri needs tick system**

  **File:** `src/Server/Managers/SantriManager.luau`

  Runs every 60 seconds. Decays all four needs for all santri across all players.

  **Implementation requirements:**
  1. `while task.wait(60) do` loop.
  2. For each player, for each santri:
     - Decay `needMakan` by `NEED_MAKAN_DECAY`. If Food building exists (level ≥ 1), reduce decay by 50%.
     - Decay `needIlmu` by `NEED_ILMU_DECAY`. If Education + matching ustadz exist, reduce by 70%.
     - Decay `needIbadah` by `NEED_IBADAH_DECAY`. If Ibadah building exists, reduce by 60%.
     - Decay `needIstirahat` by `NEED_ISTIRAHAT_DECAY`. If Dormitory level ≥ 2, reduce by 40%.
     - Clamp all needs to [0, 100].
  3. Compute happiness: `(needMakan + needIlmu + needIbadah + needIstirahat) / 4`.
  4. Apply happiness:
     - < 50: income multiplier `0.5 + (happiness / 100)`.
     - > 90: grant 0.1 Barakah per santri in this state via `EconomyService.addCurrency`.
     - < 20: 10% chance per tick to call `dropoutSantri`.
  5. Save via `DataService.updatePlayerData`. Fire `ReplicationService.syncAll`.

  **Done when:** Needs decay over time. Food building slows Makan decay. Dropout occurs when needs stay critically low.

- [x] **T15 · Implement santri study → graduation lifecycle**

  **File:** `src/Server/Managers/SantriManager.luau`

  **Implementation requirements:**
  1. On the same 60-second tick: if matching ustadz exists and `ustadz.fatigue > 20`, add `STUDY_PROGRESS_PER_MIN` to `studyProgress`. Clamp to 100.
  2. When `studyProgress >= 100`:
     - Roll `math.random()`. Pass if roll ≤ `UJIAN_PASS_CHANCE_BASE + ustadz.skill * 0.04`.
     - **Pass:** remove santri, increment `alumniCount`, add `SantriData[program].alumniSedekahBonus` to `sedekahJariyahPerMin`. Call `ReputationManager.addReputation(player, REP_PER_GRADUATION)`. Fire `Events.NotifyGraduation`.
     - **Fail:** reset `studyProgress = 0`. Fire `Events.NotifyEvent { eventType = "UjianFail" }`.
  3. Tutoring (fail recovery): client fires `ResolveMasalah { masalahId = "UjianFail_" .. santriId }`. Server deducts 200 Rupiah, resets progress to 50.

  **Done when:** Santri progresses to 100%, graduation notification fires, alumni count increments, Sedekah Jariyah increases permanently.

- [x] **T16 · Implement Masalah (random crisis) event system**

  **File:** `src/Server/Managers/SantriManager.luau`

  **Implementation requirements:**
  1. Every 10 minutes: 30% chance a Masalah triggers per player.
  2. Event types (weighted random):
     - `SantriSakit` (40%): 3 random santri → `needMakan` and `needIlmu` forced to 10. Resolve: Klinik present = free auto-resolve; else spend 300 Rupiah.
     - `UstadzAbsen` (35%): random ustadz fatigue → 0. Resolve: 150 Rupiah (substitute) or 10 Barakah (instant recovery).
     - `BanjirAsrama` (25%): all santri `needIstirahat` → 20. Resolve: 500 Rupiah.
  3. Fire `Events.NotifyMasalah` to player.
  4. If unresolved after 5 minutes: cascade — reduce affected santri happiness by 20 more, double dropout chance.
  5. Fast resolve (within 2 min): call `ReputationManager.addReputation(player, REP_PER_MASALAH_FAST_RESOLVE)`.

  **Done when:** Masalah events appear in client UI. Resolving deducts correct currency. Fast resolve grants reputation.

- [x] **T17 · Implement Sedekah Jariyah passive income tick**

  **File:** `src/Server/Services/EconomyService.luau`

  **Implementation requirements:**
  - `while task.wait(60) do` loop inside `EconomyService`.
  - Each tick: call `EconomyService.addCurrency(player, "Rupiah", data.sedekahJariyahPerMin)` for each connected player.
  - `sedekahJariyahPerMin` starts at 0 and grows each graduation (set in T15).
  - After adding, call `ReplicationService.syncCurrencies(player)`.

  **Done when:** After first graduation, Rupiah increases by the correct amount every 60 seconds passively.

---

## Phase 4 — Ustadz System

- [ ] **T18 · Implement `UstadzManager` — hire and assign**

  **File:** `src/Server/Managers/UstadzManager.luau`

  **Required functions:**

  ```luau
  function UstadzManager.hireUstadz(player: Player, program: SantriProgram, targetRarity: UstadzRarity | nil): boolean
  function UstadzManager.getUstadzForProgram(player: Player, program: SantriProgram): UstadzData | nil
  function UstadzManager.getUstadzCount(player: Player): number
  ```

  **Implementation requirements:**
  1. `hireUstadz`:
     - If `targetRarity` is nil: roll rarity using `UstadzData.rarityWeights` (weighted random).
     - Check and spend hire cost from `UstadzData.hireCost[rarity]` via `EconomyService`.
     - Generate `UstadzData` with random `skill` (1–5), `kharisma` (1–5), `fatigue = 100`.
     - Add to `ustadzList` in player data.
     - One ustadz per program per player in v1 — reject if slot filled.
     - If rarity is `KyaiBesar` or `KyaiInternasional`: call `ReplicationService.broadcastToServer("NotifyKyaiBesar", ...)`.

  **Done when:** Hiring deducts correct currency, rarity rolls match weight table, Kyai Besar triggers server announcement.

- [ ] **T19 · Implement ustadz fatigue tick**

  **File:** `src/Server/Managers/UstadzManager.luau`

  **Implementation requirements:**
  - Every 60 real minutes: decay each ustadz `fatigue` by `USTADZ_FATIGUE_DECAY_PER_HOUR`.
  - If `fatigue < 20`: ustadz cannot teach. Fire `Events.NotifyEvent { eventType = "UstadzTired" }` to player.
  - Restore options:
    1. 100 Rupiah → `fatigue += 30`.
    2. Libur: set `liburUntil = os.time() + 7200`. Skip teaching if `os.time() < liburUntil`. Fatigue fully recovers after libur.

  **Done when:** Fatigue depletes, notification fires, Rupiah spend restores fatigue.

---

## Phase 5 — Reputation & Prestige

- [ ] **T20 · Implement `ReputationManager`**

  **File:** `src/Server/Managers/ReputationManager.luau`

  **Required functions:**

  ```luau
  function ReputationManager.addReputation(player: Player, amount: number): ()
  function ReputationManager.getReputation(player: Player): number
  function ReputationManager.checkTierUnlocks(player: Player): ()
  ```

  **Implementation requirements:**
  1. `addReputation`: add to `player.data.reputation`. Clamp to [0, 100]. Call `checkTierUnlocks`.
  2. `checkTierUnlocks` (each fires once — track fired tiers in PlayerData flags):
     - rep ≥ 50: fire `NotifyEvent { eventType = "TierBerkembang" }`. Enable auto-enroll in `SantriManager`.
     - rep ≥ 75: fire `NotifyEvent { eventType = "TierUnggulan" }`. Call `BuildingManager.checkZoneUnlock`.
     - rep ≥ 100: fire `NotifyEvent { eventType = "KunjunganMenteri" }`. Apply 5× income multiplier to this player for 3 real minutes. Enable "Buka Cabang" flag.
  3. Wire into other managers: `SantriManager` calls on graduation; `BuildingManager` calls on upgrade; `SantriManager` calls on fast masalah resolve.

  **Done when:** Rep bar fills correctly. Tier 50 unlocks auto-enroll. Tier 100 triggers Kunjungan Menteri.

- [ ] **T21 · Implement Buka Cabang (prestige reset)**

  **File:** `src/Server/Managers/ReputationManager.luau`

  **Required function:**

  ```luau
  function ReputationManager.bukaCabang(player: Player): boolean
  ```

  **Implementation requirements:**
  1. Reject if `reputation < 100` (server-side check — never trust client).
  2. Sanad reward: `1 + math.floor(prestigeCount * 0.5)`.
  3. Preserve: `sanad`, `prestigeCount + 1`, `alumniCount`, `sedekahJariyahPerMin`.
  4. Reset: `rupiah = 500`, `barakah = 0`, `ilmu = 0`, `reputation = 0`, `santriList = {}`, `buildingList = {}`, `ustadzList = {}`.
  5. Store `prestigeMultiplier = 1 + (prestigeCount * 0.15)` in PlayerData. Apply in `EconomyService.addCurrency` for Rupiah.
  6. Save via `DataService.savePlayer`. Fire `ReplicationService.syncAll`. Fire `NotifyEvent { eventType = "BukaCabang" }`.

  **Done when:** Player at rep 100 can prestige. Data resets correctly. Second run earns 15% more Rupiah.

---

## Phase 6 — Events & Live Retention

- [ ] **T22 · Implement `EventService` — in-game event scheduler**

  **File:** `src/Server/Services/EventService.luau`

  **Required functions:**

  ```luau
  function EventService.start(): ()
  function EventService.isSeasonalActive(event: SeasonalEvent): boolean
  function EventService.setSeasonalEvent(event: SeasonalEvent, active: boolean): ()
  function EventService.getActiveMultiplier(player: Player): number
  ```

  **Implementation requirements:**
  - Call `EventService.start()` from `init.server.luau` on server boot.
  - Maintain in-game clock: track `currentDayMinutes` (0–1440) and `currentDayOfWeek` (1–7).
  - Seasonal event flags stored server-wide (not per-player).
  - `getActiveMultiplier`: sum all active event multipliers from `EventData` plus base 1×. All `EconomyService` income ticks call this.

  **Done when:** `getActiveMultiplier` returns correct combined multiplier during overlapping events.

- [ ] **T23 · Implement Waktu Sholat bonus**

  **File:** `src/Server/Services/EventService.luau`

  **Implementation requirements:**
  1. Trigger at minutes `[288, 576, 864, 1152, 1440]` of in-game day.
  2. On trigger: fire `NotifyEvent { eventType = "WaktuSholat" }` to all clients.
  3. Player acknowledges via `Events.AcknowledgeWaktuSholat`. Server sets per-player `waktuSholatActive = true` with expiry `os.time() + 60`.
  4. In `EconomyService` income ticks: if active and not expired, multiply Rupiah by `WAKTU_SHOLAT_MULTIPLIER`.
  5. Track `dailyPrayerCount` per player. Reset at day rollover.
  6. `dailyPrayerCount == 5` at day end: grant 50 Rupiah + 5 Barakah ("Sholat Sempurna" chest).

  **Done when:** Banner appears 5 times per in-game day. Acknowledging triples income for 60 seconds. All 5 grants bonus chest.

- [ ] **T24 · Implement Jum'at Berkah weekly event**

  **File:** `src/Server/Services/EventService.luau`

  **Implementation requirements:**
  1. Track in-game day of week. Day 5 (mod 7) = Friday.
  2. On Friday at minute 576: broadcast `NotifyEvent { eventType = "JumatBerkah" }` to all clients. Set `jumatBerkahActive = true` server-wide for `JUMAT_BERKAH_DURATION_MIN` in-game minutes.
  3. In `EconomyService`: while `jumatBerkahActive`, apply `JUMAT_BERKAH_MULTIPLIER` to all players.
  4. Client `EventBanner`: show Jum'at cutscene animation (2 seconds), then auto-dismiss.

  **Done when:** Every in-game Friday triggers for all online players. Income doubles for 30 in-game minutes.

- [ ] **T25 · Implement seasonal event framework**

  **File:** `src/Server/Services/EventService.luau`

  **Implementation requirements:**
  1. On server start, load active seasonal event from `EventData` based on configurable start/end day stored there.
  2. `getActiveMultiplier` sums seasonal multipliers on top of base.
  3. Special seasonal mechanics:
     - **Ramadan**: enable nightly Tarawih event (8 PM in-game, reward 10 Barakah). Reduce `NEED_MAKAN_DECAY` by 30%.
     - **Idul Fitri**: auto-graduate every santri with `studyProgress ≥ 80`. Fire graduation notifications for each.
     - **Idul Adha / Qurban**: handle `TriggerQurban` RemoteEvent — deduct 1000 Rupiah, add +10 Reputation, broadcast `eventType = "QurbanEvent"`.
     - **Maulid Nabi**: spawn one free `KyaiBesar` ustadz for every player. Set `liburUntil` to expire after 24 in-game hours.
  4. Fire `NotifyEvent { eventType = "SeasonalTheme", theme = eventName }` to all clients on seasonal event start/end.

  **Done when:** Toggling Ramadan doubles Barakah output. Idul Fitri auto-graduates eligible santri. Qurban spends Rupiah and raises rep.

- [ ] **T26 · Implement Tabligh Akbar (server-wide event)**

  **File:** `src/Server/Services/EventService.luau`

  **Implementation requirements:**
  1. When `#Players:GetPlayers() >= TABLIGH_AKBAR_MIN_PLAYERS`: enable vote UI → fire `NotifyEvent { eventType = "TabligVoteOpen" }` to all.
  2. Tally `VoteTabligAkbar` events. If > 50% vote yes:
     - Fire `NotifyEvent { eventType = "TabligStart" }` to all clients.
     - Deduct 5 Barakah from each voting player via `EconomyService` (skip if can't afford, vote still counts).
     - Set `tabligActive = true` for `TABLIGH_AKBAR_DURATION_MIN` minutes server-wide.
  3. While `tabligActive`: `getActiveMultiplier` returns additional `TABLIGH_AKBAR_MULTIPLIER` for all players.

  **Done when:** With 10+ players, vote UI appears. Majority vote gives 5× income to all for 5 minutes.

---

## Phase 7 — Social & Multiplayer

- [ ] **T27 · Implement Visit Mode**

  **Files:** `src/Server/Services/DataService.luau`, `src/Client/Controllers/UIController.luau`

  **Implementation requirements:**
  1. Server: on each `savePlayer`, write public snapshot to `DataStore("PublicPesantren_{userId}")`: `{ reputation, alumniCount, buildingList, lastSeen }`.
  2. Client social UI: fetch friend list via `Players:GetFriendsAsync`. Show friend cards with reputation and alumni count.
  3. "Kunjungi" button: use `TeleportService:TeleportAsync` to bring player to friend's server if online. If offline, show read-only snapshot.
  4. On visit arrival: server fires `NotifyEvent { eventType = "VisitorArrived", visitorName }` to host.
  5. Doa mechanic: `ProximityPrompt` on host's Ibadah building (`ActionText = "Doakan"`). On activate: grant 1 Barakah to both players. 24-hour cooldown per visitor-host pair stored in DataStore.
  6. On visitor arrival: call `ReputationManager.addReputation(host, REP_PER_VISITOR)`.

  **Done when:** Player can visit a friend, leave a Doa, both get Barakah, host gets reputation.

- [ ] **T28 · Implement Waqf Board (shared server pool)**

  **Files:** `src/Server/Services/EconomyService.luau`, `src/Server/Services/EventService.luau`

  **Implementation requirements:**
  1. Server-wide Waqf pool stored in `DataStore("ServerWaqf_{game.JobId}")`.
  2. `TriggerWaqf { amount }` handler: validate amount > 0, deduct from player Rupiah, add to pool.
  3. When pool reaches 10,000 Rupiah: upgrade shared server Masjid (CollectionService-tagged `"SharedMasjid"`) by incrementing its `buildingLevel` attribute. Reset pool to 0.
  4. Broadcast `NotifyEvent { eventType = "WaqfMasjidUpgraded" }` to all clients.
  5. Client HUD: small progress bar in bottom corner showing pool fill toward 10,000.

  **Done when:** Multiple players donate, pool accumulates, Masjid upgrades visually at threshold.

- [ ] **T29 · Implement Leaderboards**

  **File:** `src/Server/Services/DataService.luau`

  **Implementation requirements:**
  1. Three `OrderedDataStore` keys: `"Leaderboard_Reputation"`, `"Leaderboard_Sanad"`, `"Leaderboard_Alumni"`.
  2. Update all three on every `savePlayer` call.
  3. `Functions.GetLeaderboard` handler: query top 10 from requested board via `GetSortedAsync(false, 10)`. Return `{ { player: string, value: number } }[]`.
  4. Client leaderboard panel (inside social UI): calls `GetLeaderboard` on open. Render results in `UIListLayout`.

  **Done when:** Leaderboard panel shows top 10 by all three metrics.

---

## Phase 8 — UI & HUD

- [ ] **T30 · Implement HUD**

  **File:** `src/Client/Components/HUD.luau`

  **Layout (Scale-based UDim2 only — no pixel offsets):**
  - Top-left: four currency bars (Rupiah, Barakah, Ilmu, Sanad) stacked via `UIListLayout`.
  - Top-right: Reputation bar (0–100) with tier label.
  - Bottom-center: action buttons — "Bangun", "Santri", "Ustadz", "Event", "Social".
  - Bottom-left: Sedekah Jariyah rate (`"+Rp X/min passive"`).
  - Top-center: notification area (used by NotifController).

  **Implementation requirements:**
  - `ScreenGui` with `ResetOnSpawn = false`.
  - Bottom buttons offset by `GuiService:GetGuiInset()` Y value for safe area.
  - `UIAspectRatioConstraint` on all currency icon `ImageLabel`s.
  - `TextScaled = true` on all `TextLabel`s.
  - Minimum button size: `UDim2.new(0.08, 0, 0.07, 0)`.
  - Listen to `Events.SyncPlayerData` — update all currency labels on receive.

  **Done when:** All currencies display correctly. Renders without clipping on 375×667 mobile viewport (verify in Studio emulator).

- [ ] **T31 · Implement BuildMenu**

  **File:** `src/Client/Components/BuildMenu.luau`

  **Implementation requirements:**
  - Slide-up panel opened by "Bangun" HUD button.
  - `UIGridLayout` for building cards. Each card: icon, name, cost, level indicator, action button.
  - Locked buildings (zone not unlocked): greyed-out, show unlock requirement text.
  - "Beli" fires `Events.PurchaseBuilding`. "Upgrade" fires `Events.UpgradeBuilding`.
  - Slide in/out using `TweenService` (0.25s, `Enum.EasingStyle.Quad`).
  - Gamepad: set `GuiService.SelectedObject` to first card on open.

  **Done when:** All PRD §4 buildings listed. Purchasing deducts currency and building appears in world.

- [ ] **T32 · Implement SantriPanel**

  **File:** `src/Client/Components/SantriPanel.luau`

  **Implementation requirements:**
  - Each santri card: program label, four color-coded need bars (green >60, yellow 30–60, red <30).
  - Tap santri with `studyProgress = 100` and failed ujian: show "Bayar 200 Rp untuk tutoring?" confirm dialog.
  - Sort: santri with any need < 30 floated to top via `UIListLayout` `LayoutOrder`.
  - Refresh on every `SyncPlayerData` receive.

  **Done when:** Panel shows all santri. Need bars update in real time. Tutoring confirm works.

- [ ] **T33 · Implement EventBanner**

  **File:** `src/Client/Components/EventBanner.luau`

  Listen to `Events.NotifyEvent`. Show banner per `eventType`:

  | eventType | Content | Action |
  |---|---|---|
  | `WaktuSholat` | "Waktu Sholat! Tap untuk bonus!" + 60s countdown | Tap → fire `AcknowledgeWaktuSholat` |
  | `JumatBerkah` | Jum'at animation, "Pendapatan 2× selama 30 menit!" | Auto-dismiss 3s |
  | `SeasonalTheme` | Event name + icon | Auto-dismiss 5s |
  | `ZoneUnlocked` | "Zona baru terbuka!" | Tap to dismiss |
  | `KunjunganMenteri` | "Kunjungan Menteri! 5× income!" | Auto-dismiss |
  | `BukaCabang` | Prestige animation | Auto-dismiss 5s |

  **Implementation requirements:**
  - All animate in/out with `TweenService`.
  - Waktu Sholat: `RunService.Heartbeat` countdown from 60.
  - `HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0.5, 0.3)` on `WaktuSholat` and `NotifyGraduation`.
  - Queue banners — show second after first dismisses.

  **Done when:** All event types show correct banners. Countdown accurate. Haptic fires on mobile/gamepad.

- [ ] **T34 · Implement NotifController — toast alerts**

  **File:** `src/Client/Controllers/NotifController.luau`

  **Implementation requirements:**
  - `Events.NotifyMasalah` → red toast: `"⚠ [masalahType]! Ketuk untuk selesaikan"`. Tap opens resolve confirm dialog.
  - `Events.NotifyGraduation` → green toast: `"Santri [program] lulus!"`.
  - Toasts stack vertically, auto-dismiss after 8 seconds.
  - Max 3 visible at once — queue overflow.
  - Slide-in from top via `TweenService`.

  **Done when:** Masalah alerts appear and are tappable. Graduation toasts appear on each graduation.

- [ ] **T35 · Implement InputController — cross-platform bindings**

  **File:** `src/Client/Controllers/InputController.luau`

  **Required bindings (all via `ContextActionService:BindAction`):**

  | Action | Keyboard | Gamepad | Touch |
  |---|---|---|---|
  | `OpenBuildMenu` | B | DPadDown | HUD button |
  | `OpenSantriPanel` | S | DPadUp | HUD button |
  | `OpenSocialMenu` | F | Select | HUD button |
  | `ConfirmDialog` | Enter | ButtonA | Tap button |
  | `CloseMenu` | Escape | ButtonB | Back button |
  | `CameraZoomIn` | E | RightTrigger | Pinch |
  | `CameraZoomOut` | Q | LeftTrigger | Pinch |

  **Implementation requirements:**
  - `createTouchButton = false` for all — HUD handles touch.
  - `UIController` listens to action callbacks via `BindableEvent`.
  - Never read `UserInputService.InputBegan` for game actions.

  **Done when:** All menus openable via keyboard, gamepad D-pad, and HUD touch buttons.

---

## Phase 9 — Cross-Platform & Performance

- [ ] **T36 · Enable StreamingEnabled and LOD**

  **(Roblox Studio configuration + script)**

  - [ ] Set `workspace.StreamingEnabled = true`, `StreamingMinRadius = 64`, `StreamingTargetRadius = 256`.
  - [ ] Each building model: create `LOD` folder with simplified mesh (< 50 parts), attribute `"IsLOD" = true`.
  - [ ] `BuildController` (client): if building > 150 studs from camera, set `Model.LevelOfDetail = Enum.ModelLevelOfDetail.Automatic`.

  **Done when:** Studio profiler shows < 2,000 parts loaded at any time with all zones built.

- [ ] **T37 · Mobile safe area and touch target audit**

  **Files:** All `src/Client/Components/*.luau`

  - [ ] All ScreenGui bottom elements offset by `GuiService:GetGuiInset()` Y value.
  - [ ] All interactive buttons minimum `UDim2.new(0, 44, 0, 44)` or Scale equivalent.
  - [ ] No `UDim2.new(0, X, 0, Y)` pixel offsets in layout — Scale-based only.
  - [ ] `UIAspectRatioConstraint` on all icon `ImageLabel`s.
  - [ ] All `TextLabel`s use `TextScaled = true`.
  - [ ] Test at 375×667 (iPhone SE) and 768×1024 (iPad) in Studio mobile emulator.

  **Done when:** Zero clipping or overflow at both test resolutions. All buttons tappable without zoom.

- [ ] **T38 · Gamepad navigation audit**

  **File:** `src/Client/Controllers/UIController.luau`

  - [ ] On `UserInputService.GamepadConnected`: set `GuiService.AutoSelectGuiEnabled = false`.
  - [ ] On each menu open: `GuiService.SelectedObject = firstButton`.
  - [ ] On `CloseMenu` action: `GuiService.SelectedObject = nil`.
  - [ ] `ScrollingFrame`s: add thumbstick scroll via `ContextActionService`.
  - [ ] No critical path feature requires text input.

  **Done when:** Full game loop (build → hire → graduate) completable using only gamepad.

- [ ] **T39 · Network RPS guard**

  **File:** `src/Server/Services/ReplicationService.luau`

  - [ ] Dirty-flag batching implemented: mark dirty, flush on `RunService.Heartbeat`, max one `SyncPlayerData` per player per frame.
  - [ ] Dev-mode warning logged if any player exceeds 20 remote fires/sec.

  **Done when:** Studio Network profiler shows ≤ 20 RemoteEvent fires/sec per client at peak.

---

## Phase 10 — Monetization

- [ ] **T40 · Implement MarketplaceService product handler**

  **File:** `src/Server/Services/DataService.luau`

  **Implementation requirements:**
  1. Define Developer Product ID constants (fill in real IDs after creating in Creator Hub):
     ```luau
     PRODUCT_TIME_SKIP_1H = 0
     PRODUCT_STARTER_PACK = 0
     ```
  2. `MarketplaceService.ProcessReceipt` handler:
     - `PRODUCT_TIME_SKIP_1H`: grant `sedekahJariyahPerMin * 60` Rupiah (minimum 1000 if no alumni).
     - `PRODUCT_STARTER_PACK`: store `starterPackExpiry = os.time() + 1800` in PlayerData. `EconomyService.addCurrency` checks this and doubles Rupiah for 30 minutes.
  3. Always return `PurchaseGranted` on success, `NotProcessedYet` on error.
  4. Deduplicate via `DataStore("ProcessedReceipts")` — check `receiptInfo.PurchaseId` before granting.

  **Done when:** Time Skip grants correct Rupiah. Starter Pack doubles income for 30 minutes. No duplicate grants.

- [ ] **T41 · Implement Game Pass checks**

  **File:** `src/Server/Services/DataService.luau`

  **Implementation requirements:**
  - On player join: `MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAMEPASS_PREMIUM_PASS)`.
  - Cache result server-side (not in DataStore — re-check each join).
  - `EconomyService.addCurrency`: if player owns pass and currency is Rupiah, multiply by 1.2.
  - Never store pass ownership in DataStore — always re-verify from MarketplaceService.

  **Done when:** Premium Pass owners earn 20% more Rupiah. Verified in Studio with test account.

---

## Phase 11 — Tutorial & Progression Flow

- [ ] **T42 · Implement tutorial flow**

  **Files:** `src/Client/Controllers/UIController.luau`, `src/Server/Services/EventService.luau`

  Target: player understands core loop in ≤ 15 minutes. Goal: 10 santri, first graduation.

  **Tutorial steps (sequential — each waits for completion trigger):**

  | Step | Instruction | Completion trigger |
  |---|---|---|
  | 1 | "Tap 'Bangun' dan beli Musholla" | Musholla placed |
  | 2 | "Sekarang beli Gubuk untuk santri tinggal" | Dormitory placed |
  | 3 | "Tap 'Santri' lalu daftarkan santri pertamamu" | 1 santri enrolled |
  | 4 | "Bangun Ruang Kelas agar santri bisa belajar" | Education building placed |
  | 5 | "Hire ustadz di menu Ustadz" | 1 ustadz hired |
  | 6 | "Tunggu santri belajar dan lulus ujian!" | First graduation |

  **Implementation requirements:**
  - `tutorialStep: number` stored in PlayerData (0 = not started, 6 = complete).
  - Arrow UI pointing at relevant HUD button per step.
  - Skip button available from step 3 onward.
  - On step 6: play 2-second camera zoom on graduating santri, show "Selamat! Santrimu lulus!" full-screen.
  - Fire `NotifyEvent { eventType = "TutorialComplete" }` after step 6.

  **Done when:** New player completes all 6 steps in < 15 minutes. Graduation moment fires correctly.

---

## Phase 12 — QA & Polish

- [ ] **T43 · Server-side exploit prevention audit**

  **Files:** All `src/Server/` scripts.

  - [ ] All `Events.*` server handlers validate input types before processing.
  - [ ] `PurchaseBuilding` handler: validate `buildingType` is valid `BuildingType`, `zone` is 1–5.
  - [ ] `HireUstadz` handler: validate `program` is valid `SantriProgram`.
  - [ ] `ResolveMasalah` handler: validate `masalahId` belongs to requesting player's data.
  - [ ] `BukaCabang` handler: validate `reputation >= 100` server-side regardless of client.
  - [ ] `EconomyService.spendCurrency`: balance checked server-side on every call.
  - [ ] Game Pass ownership never read from DataStore — always from MarketplaceService.

  **Done when:** Exploit firing `BukaCabang` at rep < 100 is rejected by server. No client payload trusted without validation.

- [ ] **T44 · Performance audit**

  **Target:** 30 fps on mid-tier mobile.

  - [ ] Studio Profiler → Script Activity: no single script > 2ms/frame.
  - [ ] Needs tick runs every 60 seconds — not every frame.
  - [ ] Income ticks run every 60 seconds — not every frame.
  - [ ] No `while true do task.wait(0)` loops anywhere.
  - [ ] Part count per zone ≤ 2,000 (check Studio Explorer filter).
  - [ ] Script Memory ≤ 150 MB (Studio Diagnostic panel).
  - [ ] `workspace.StreamingEnabled = true` confirmed.

  **Done when:** 30+ fps sustained on Roblox mobile emulator with all 5 zones built.

- [ ] **T45 · Cross-platform playthrough test**

  **Desktop:**
  - [ ] Tutorial completes via keyboard + mouse only.
  - [ ] All menus openable. No hover-only interactions.

  **Mobile:**
  - [ ] All ProximityPrompts show native tap button.
  - [ ] All HUD buttons tappable without zoom (44px confirmed).
  - [ ] No text cut off by notch or home bar.
  - [ ] Haptic fires on Waktu Sholat and graduation.

  **Gamepad:**
  - [ ] Full tutorial completable with gamepad only.
  - [ ] D-pad navigates all menus.
  - [ ] No menu requires text input to progress.

  **Done when:** All three platform checklists fully checked off.

---

## Task Summary

| Phase | Tasks | Description |
|---|---|---|
| M0 | T01–T05 | Scaffolding, types, constants, network |
| M1 | T06–T09 | DataService, EconomyService, Replication, Data modules |
| M2 | T10–T12 | Building placement, BillboardGui, SurfaceGui |
| M3 | T13–T17 | Santri enroll, needs tick, lifecycle, masalah, alumni income |
| M4 | T18–T19 | Ustadz hire, fatigue |
| M5 | T20–T21 | Reputation, Buka Cabang prestige |
| M6 | T22–T26 | EventService, Waktu Sholat, Jum'at, seasonal, Tabligh Akbar |
| M7 | T27–T29 | Visit Mode, Waqf Board, Leaderboards |
| M8 | T30–T35 | HUD, BuildMenu, SantriPanel, EventBanner, NotifController, InputController |
| M9 | T36–T39 | StreamingEnabled, mobile audit, gamepad nav, network guard |
| M10 | T40–T41 | Robux products, Game Pass |
| M11 | T42 | Tutorial flow |
| M12 | T43–T45 | Security audit, performance audit, cross-platform test |
