# Studio Setup — Pesantren Tycoon

Complete checklist to get the project running in Roblox Studio from a fresh clone.

---

## 1. Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Rojo](https://rojo.space/) | ≥ 7.x | Sync filesystem → Studio |
| [Roblox Studio](https://www.roblox.com/create) | Latest | Run and test |
| [Rojo Studio plugin](https://www.roblox.com/library/13640humphrey) | Matching Rojo CLI | Bridge in Studio |

Install Rojo CLI:
```bash
aftman install   # if using aftman
# or
cargo install rojo
```

---

## 2. Sync project into Studio

```bash
# In project root (same folder as default.project.json)
rojo serve
```

Open Studio → Rojo plugin → **Connect** to `localhost:34872`.

The plugin maps source folders to Studio containers:

| Filesystem path | Studio location |
|-----------------|-----------------|
| `src/Server/` | `ServerScriptService.Server` (Script) |
| `src/Client/` | `StarterPlayer.StarterPlayerScripts.Client` (LocalScript) |
| `src/Character/` | `StarterPlayer.StarterCharacterScripts.Character` (LocalScript) |
| `src/Shared/` | `ReplicatedStorage.Shared` (ModuleScript tree) |

All `.luau` files sync automatically while `rojo serve` is running. **Do not edit scripts directly in Studio** — changes will be overwritten on next sync.

---

## 3. Game Settings (required before first play-test)

Open **Home → Game Settings** in Studio.

### Security tab
- **Enable Studio Access to API Services** → ON

  Required for DataStore to work during local play-tests. Without this, all `DataStoreService` calls silently fail and every player starts with default data.

### Avatar tab
- Leave defaults (R15, no forced scaling). Scripts do not depend on avatar type.

### Other
- No HTTP Service calls are made — leave HTTP disabled unless you add external APIs later.

---

## 4. Workspace configuration

`init.server.luau` sets these at runtime:

```lua
workspace.StreamingEnabled = true
workspace.StreamingMinRadius = 64
workspace.StreamingTargetRadius = 256
```

For accurate in-Studio editing experience, mirror these manually:

1. Select **Workspace** in the Explorer.
2. In Properties: set **StreamingEnabled** = `true`, **StreamingMinRadius** = `64`, **StreamingTargetRadius** = `256`.

This is cosmetic — the script overwrites them on run — but prevents misleading Editor warnings.

---

## 5. Shared Masjid part (Waqf mechanic)

The Waqf pool (T28) upgrades a community Masjid visible to all players. You must place at least one part tagged `SharedMasjid` in Workspace:

1. Insert a **Part** into Workspace. Name it `SharedMasjid` (or anything — name doesn't matter, tag does).
2. Open **View → Tag Editor** (or use CollectionService plugin).
3. Add tag: `SharedMasjid`.
4. Set attribute `buildingLevel` (number) = `1`.

The `EconomyService` upgrades this part's `buildingLevel` attribute when the Waqf pool crosses `Constants.WAQF_UPGRADE_THRESHOLD` (default 10 000 Rupiah). Without this part the Waqf mechanic still works internally — it just has no visible world object to upgrade.

---

## 6. CollectionService tags reference

Scripts use these tags to find and classify workspace Parts. Do **not** add these manually — `BuildingManager` applies them automatically when a player places a building. Listed here for debugging:

| Tag | Applied to | Used by |
|-----|-----------|---------|
| `Building` | Every placed building Part | BillboardGui (BuildController), LOD loop |
| `FoodBuilding` | Parts with `buildingType = "Food"` | Income SurfaceGui |
| `EconomyBuilding` | Parts with `buildingType = "Economy"` | Income SurfaceGui |
| `SharedMasjid` | Manual — see §5 | Waqf upgrade |

---

## 7. RemoteEvents and RemoteFunctions

**No manual setup needed.** `Events.luau` and `Functions.luau` both use `getOrCreate()` — the server script creates all remotes on first require before any client loads. They live directly under `ReplicatedStorage` (not inside `Shared`).

Remotes created at runtime:

**RemoteEvents:** `PurchaseBuilding`, `UpgradeBuilding`, `HireUstadz`, `ResolveMasalah`, `BukaCabang`, `TriggerWaqf`, `VoteTabligAkbar`, `AcknowledgeWaktuSholat`, `TriggerQurban`, `RequestVisit`, `NotifyVisitArrival`, `SkipTutorial`, `SyncPlayerData`, `NotifyMasalah`, `NotifyEvent`, `NotifyGraduation`, `NotifyKyaiBesar`, `SyncWaqfPool`

**RemoteFunctions:** `GetPlayerData`, `GetLeaderboard`, `CheckGamePass`, `GetPublicSnapshot`

---

## 8. DataStore names

Five regular DataStores and three OrderedDataStores are created automatically at runtime:

| Store name | Type | Purpose |
|-----------|------|---------|
| `PlayerData_v1` | DataStore | Primary player save data |
| `PublicPesantren` | DataStore | Public snapshots for visit mode |
| `DoaCooldowns` | DataStore | Per-pair Doa 24 h cooldown |
| `ProcessedReceipts` | DataStore | Developer Product dedup (T40) |
| `Leaderboard_Reputation` | OrderedDataStore | Reputation leaderboard |
| `Leaderboard_Sanad` | OrderedDataStore | Sanad leaderboard |
| `Leaderboard_Alumni` | OrderedDataStore | Alumni count leaderboard |

DataStore keys use `tostring(player.UserId)`. The receipt dedup key format is `"receipt_" .. tostring(receiptInfo.PurchaseId)`.

---

## 9. Monetisation IDs (fill before publishing)

Open `src/Server/Services/DataService.luau` and replace the three placeholder `0` values:

```lua
-- Line 16 — Developer Product: "1 Hour Skip"
local PRODUCT_TIME_SKIP_1H = 0   -- ← replace with product ID from Creator Hub

-- Line 17 — Developer Product: "Starter Pack"
local PRODUCT_STARTER_PACK = 0   -- ← replace with product ID

-- Line 21 — Game Pass: "Premium Pass"
DataService.GAMEPASS_PREMIUM_PASS = 0  -- ← replace with game pass ID
```

**How to create them in Creator Hub:**

1. Go to [create.roblox.com](https://create.roblox.com) → your game → **Monetization**.
2. **Developer Products** → Create two products with names and prices of your choice. Copy their numeric IDs.
3. **Game Passes** → Create one pass (e.g. "Premium Pass", +20% income). Copy its numeric ID.
4. Paste IDs into the three fields above. The `ProcessReceipt` handler and `UserOwnsGamePassAsync` call are already wired — no other changes needed.

> **Note:** `MarketplaceService.ProcessReceipt` does not fire during Studio local play-tests. To test product grants manually, call `DataService` functions directly from the command bar or a test script.

---

## 10. Visit Mode / TeleportService (T27)

Visit mode teleports players between live servers. This requires:

1. Game must be **published** to Roblox (not just a local `.rbxl` file).
2. The Place ID used in TeleportService calls resolves to **this same game**.
3. Teleport data (`hostUserId`) is set by `RequestVisit` handler in `init.server.luau`.

**Local play-test limitation:** `TeleportService:TeleportAsync` and `GetLocalPlayerTeleportData` always return nil/error in Studio. The `NotifyVisitArrival` path is silently skipped — this is expected.

---

## 11. Play-test checklist

Before hitting **Play**:

- [ ] `rojo serve` is running and Studio shows "Connected".
- [ ] **Enable Studio Access to API Services** is ON (Game Settings → Security).
- [ ] `default.project.json` structure matches Studio Explorer (Server, Client, Shared all present).
- [ ] No script errors in Output on startup (particularly `DataService` and `ReplicationService`).
- [ ] Tutorial fires at step 1 for a new UserId (check Output for `[DataService] Loaded …`).

**Multi-client test** (two players):

Use **Test → Clients and Servers → Start** (set clients = 2). Both clients need independent UserIds — Studio uses your Roblox account for client 1 and a fake ID for client 2. DataStore writes from fake IDs are discarded on session end, which is expected.

---

## 12. Linting and type-checking (optional, recommended)

Project includes configs for two tools:

```bash
# Selene — static analysis
selene src/

# Luau LSP (VS Code extension: JohnnyMorganz.luau-lsp)
# Uses sourcemap.json generated by Rojo:
rojo sourcemap --output sourcemap.json
```

`selene.toml` is pre-configured (`std = "roblox+roblox+testez"`). All scripts use `--!strict` — type errors surface immediately in the LSP.

---

## 13. Folder structure summary

```
ServerScriptService/
└── Server/                      ← src/Server/
    ├── init.server.luau         (bootstrap + player lifecycle)
    ├── Services/
    │   ├── DataService.luau     (save/load, DataStore, receipts)
    │   ├── EconomyService.luau  (currency, waqf, income ticks)
    │   ├── EventService.luau    (waktu sholat, seasonal events, tutorial)
    │   └── ReplicationService.luau (dirty-flag sync to clients)
    └── Managers/
        ├── BuildingManager.luau (place, upgrade, zone unlock)
        ├── SantriManager.luau   (enroll, study, graduation, masalah)
        ├── UstadzManager.luau   (hire, fatigue, libur)
        └── ReputationManager.luau (rep, prestige, buka cabang)

StarterPlayerScripts/
└── Client/                      ← src/Client/
    ├── init.client.luau         (bootstrap all controllers + components)
    ├── Controllers/
    │   ├── InputController.luau (ContextActionService bindings)
    │   ├── UIController.luau    (tutorial GUI, visit arrival, gamepad scroll)
    │   ├── NotifController.luau (toast + masalah dialog)
    │   └── BuildController.luau (billboard, LOD, surface income GUI)
    └── Components/
        ├── HUD.luau             (bottom action bar, currency row, rep bar)
        ├── BuildMenu.luau       (build/upgrade panel)
        ├── SantriPanel.luau     (santri list + tutoring)
        └── EventBanner.luau     (event banners, haptic, WaktuSholat countdown)

StarterCharacterScripts/
└── Character/                   ← src/Character/
    └── init.client.luau         (character-local setup)

ReplicatedStorage/
└── Shared/                      ← src/Shared/
    ├── Net/
    │   ├── Events.luau          (all RemoteEvents via getOrCreate)
    │   └── Functions.luau       (all RemoteFunctions via getOrCreate)
    ├── Modules/
    │   ├── Types.luau           (all exported types)
    │   ├── Constants.luau       (all numeric tunables)
    │   ├── Network.luau
    │   └── Utils.luau
    └── Data/
        ├── BuildingData.luau    (building definitions + tier costs)
        ├── SantriData.luau      (program definitions)
        ├── UstadzData.luau      (rarity weights + hire costs)
        └── EventData.luau       (seasonal event definitions)
```
