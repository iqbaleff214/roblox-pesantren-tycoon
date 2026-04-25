# PRD — Pesantren Tycoon (Roblox)

**Version:** 0.1  
**Date:** 2026-04-26  
**Status:** Draft

---

## 1. Overview

Pesantren Tycoon is an incremental tycoon game on Roblox where players build and manage an Islamic boarding school (pesantren) from a tiny musholla and a single dormitory hut into a world-renowned international Islamic institution. The game blends idle-tycoon mechanics with active management decisions, cultural authenticity, and social multiplayer hooks to drive long-term retention.

**Target Audience:** Indonesian/Southeast Asian Roblox players (10–20 y/o), Muslim gamers globally, pesantren alumni with nostalgia.

**Core Fantasy:** "I am the Kiai who built the most prestigious pesantren in the world."

---

## 2. Core Game Loop

```
BUILD facilities
    ↓
ATTRACT santri (students)
    ↓
SANTRI study, pray, work → generate Rupiah + Barakah
    ↓
EARN income → UPGRADE buildings / HIRE ustadz
    ↓
REPUTATION rises → more santri enroll
    ↓
EXPAND to new zones → loop repeats
```

### Sub-loop: Prayer Cycle (Active Retention Hook)

Every real-world prayer time window (Fajr, Dhuhr, Asr, Maghrib, Isha) triggers a **Waktu Sholat Bonus** — a short timed event where players tap/click to multiply income for 60 seconds. Five natural daily touchpoints, culturally resonant, zero grind feel.

### Sub-loop: Santri Lifecycle

```
Enroll → Study (generate Ilmu) → Pass Ujian → Graduate → Become Alumni
                                    ↓ fail ↓
                               Extra tutoring (costs Rupiah, player choice)
```

Alumni send **Sedekah Jariyah** (passive income) forever. First graduation is a powerful dopamine spike that teaches the loop.

---

## 3. Currencies

| Currency | How Earned | How Spent |
|---|---|---|
| **Rupiah (Rp)** | Santri income, koperasi sales, farm produce | Buildings, upgrades, salaries |
| **Barakah (✦)** | Prayer events, graduating hafidz, charity acts | Premium buildings, ustadz celebrities, event unlocks |
| **Ilmu (📖)** | Santri studying, library, research sessions | Unlock new programs/kurikulum, tech tree |
| **Sanad (🔗)** | Prestige resets ("Buka Cabang") | Permanent multipliers, cosmetics, exclusive titles |

Barakah is earnable through gameplay — not pay-walled. Monetization comes through cosmetics and time skips.

---

## 4. Buildings & Zones

### Zone Progression (unlocks sequentially)

| # | Zone Name | Unlock Condition | Theme |
|---|---|---|---|
| 1 | **Tanah Kosong** | Start | Empty land |
| 2 | **Komplek Inti** | 20 santri | Main campus core |
| 3 | **Komplek Alam** | 100 santri | Farms, nature |
| 4 | **Komplek Wirausaha** | 250 santri | Entrepreneurship hub |
| 5 | **Komplek Internasional** | 600 santri | Global exchange wing |

### Building Tiers (each has 5 upgrade levels)

**Ibadah (Prayer)**
- Musholla → Masjid → Masjid Jami → Masjid Agung → Masjid Internasional
- Effect: Barakah generation rate, prayer event multiplier

**Tempat Tinggal (Dormitory)**
- Gubuk → Pondok Kayu → Asrama → Gedung Asrama → Menara Santri
- Effect: Max santri capacity

**Pendidikan (Education)**
- Tanah Lapang → Kelas Darurat → Ruang Kelas → Gedung Madrasah → Kampus Terpadu
- Effect: Ilmu generation speed, program slots

**Konsumsi (Food)**
- Warung Kecil → Kantin → Dapur Bersama → Food Court Halal
- Effect: Santri happiness, reduces dropout rate

**Ekonomi (Economy)**
- Kebun Sayur → Ladang → Koperasi Santri → Pusat Bisnis
- Effect: Passive Rupiah per minute

**Spesial Buildings** (unlocked via Ilmu tree)
- Perpustakaan Kitab Kuning — doubles Ilmu for kitab program santri
- Studio Podcast/Dakwah — generates Barakah passively + Reputation
- Lab Komputer — unlocks Tech program
- Klinik Sehat — reduces santri unhappiness events
- Aula Serbaguna — enables special event hosting

---

## 5. Santri System

### Santri Types (Programs)

| Program | Generates | Speciality |
|---|---|---|
| **Tahfidz** | High Barakah | Graduates become Hafidz → huge alumni Sedekah Jariyah |
| **Kitab Kuning** | Ilmu + Rupiah | Boosts research speed |
| **Bahasa Arab/Inggris** | Reputation | Attracts foreign santri (higher value) |
| **Wirausaha** | High Rupiah | Unlocks cooperative business buildings |
| **Teknologi** | Rupiah + Ilmu | Required for late-game buildings |

### Santri Needs (Happiness Meter)

Santri have 4 needs tracked on a hidden score (0–100):
1. **Makan** — depletes over time, restored by food buildings
2. **Ilmu** — satisfied by attending class
3. **Ibadah** — satisfied by prayer buildings & events
4. **Istirahat** — satisfied by dorm quality

Happiness below 50 → Rupiah income penalty.  
Happiness below 20 → santri dropout (lost permanently).  
Happiness 90+ → santri produce bonus Barakah.

### Dropout Prevention (Active Tension)
Random "Masalah" events pop up:
- "Santri sakit" → needs klinik
- "Ustadz tidak hadir" → needs substitute hire or Barakah spend
- "Banjir di asrama" → needs repair Rupiah

Ignoring events cascades into mass dropout. Resolving them fast rewards bonus Reputation.

---

## 6. Ustadz (Teacher) System

Players hire ustadz to run programs. Ustadz have:
- **Kemampuan (Skill):** 1–5 stars, affects Ilmu/income multiplier for their program
- **Kharisma:** affects how many santri want to enroll for that program
- **Kelelahan (Fatigue):** depletes daily, restored by "libur" or paying gaji bonus

### Ustadz Rarity

| Rarity | Source | Bonus |
|---|---|---|
| Biasa | Hire with Rupiah | 1× |
| Terkenal | Hire with Barakah | 2× |
| Kyai Besar | Random event / Sanad | 5×, special passive effect |
| Kyai Internasional | Late-game unlock | 10×, unlocks unique zone |

Kyai Besar ustadz trigger server-wide announcements — social proof loop.

---

## 7. Reputation & Prestige

### Reputation Meter
0 → 100 bar (resets on prestige). Reputation earned by:
- Graduating santri
- Completing events
- Building upgrades
- Resolving masalah events fast
- Other players visiting your pesantren

Reputation tier unlocks:
- **50:** "Pesantren Berkembang" title + santri auto-enroll
- **75:** "Pesantren Unggulan" + unlock Komplek Internasional
- **100:** Trigger "Kunjungan Menteri" event → massive income spike + Prestige unlock

### Prestige: Buka Cabang
At Rep 100, player can **Buka Cabang** (open a branch):
- Reset current pesantren to scratch
- Keep all Sanad points
- Gain permanent global multiplier (stacks per prestige)
- Unlock cosmetic "Generasi ke-N" badge

First prestige is the primary mid-game goal. Design all early content to funnel toward it.

---

## 8. Events & Live Retention

### Daily: Waktu Sholat (5×/day)
Aligned with real prayer times (configurable in settings). 60-second active income multiplier. Players who hit all 5 get end-of-day "Sholat Sempurna" bonus chest.

### Weekly: Jum'at Berkah (Friday)
Every in-game Friday (or real Friday), income is doubled for 30 minutes after server-wide Jum'at prayer cutscene plays. Social event — all online players on the server benefit together.

### Seasonal Events (tied to Islamic calendar)

| Event | Effect |
|---|---|
| **Ramadan** (30 days) | 2× Barakah, daily Tarawih reward, special Ramadan buildings |
| **Idul Fitri** | Mass santri graduation, Eid cosmetics, Lebaran gift chest |
| **Idul Adha** | "Qurban" mechanic — spend Rupiah for huge Reputation surge |
| **Maulid Nabi** | Celebrity Kyai visits, server event, exclusive ustadz unlock |
| **Tahun Baru Hijriyah** | Yearly reset leaderboard, special title for top players |
| **Isra Mi'raj** | Nighttime visual theme, double Barakah for the night |

### Limited: Tabligh Akbar (Server Event)
When 10+ players are online in same server, a server-wide Tabligh Akbar can be voted. All players pool Barakah, and the event gives server-wide 5× income for 5 minutes. Creates social coordination moment.

---

## 9. Progression Timeline

| Phase | Time Estimate | Goal | Key Unlock |
|---|---|---|---|
| **Tutorial** | 0–15 min | 10 santri, first musholla | Core loop understood |
| **Early** | 15 min–2 hrs | 50 santri, first graduation | Santri lifecycle |
| **Mid** | 2–10 hrs | 200 santri, all zone 1–3 buildings | Masalah events, Ustadz system |
| **Late** | 10–30 hrs | 600 santri, Rep 100 | First Buka Cabang |
| **Endgame** | 30 hrs+ | Sanad stacking, cosmetics | Leaderboard, prestige depth |

---

## 10. Monetization (Robux)

All monetization is **cosmetic or time-based** — no pay-to-win.

| Item | Type | Example |
|---|---|---|
| **Skin Bangunan** | Cosmetic | Golden Masjid skin, Futuristic Lab |
| **Pakaian Santri** | Cosmetic | Uniform color packs |
| **Time Skip** | Convenience | Skip 1-hr wait (not blocking) |
| **Starter Pack** | Bundle | 2× Rupiah for first 30 min |
| **Premium Pass** | Battle Pass | Monthly, exclusive cosmetics + small QoL |

No Barakah for Robux — Barakah stays earned-only to preserve cultural respect.

---

## 11. Social & Multiplayer Hooks

- **Visit Mode:** Visit other players' pesantren, leave "Doa" (like) for small Barakah gift to both
- **Waqf Board:** Players can donate Rupiah to a shared server pool that funds a server building (Masjid upgrade visible to all)
- **Leaderboard:** Top pesantren by Reputation, by Sanad, by total santri graduated
- **Kunjungan:** Friends can send "tamu" (guest) santri that temporarily boost your income for 10 minutes

---

## 12. Retention Summary

| Hook | Frequency | Mechanic |
|---|---|---|
| Waktu Sholat bonus | 5×/day | Active income burst |
| Daily masalah event | 1–3×/day | Risk management |
| Santri graduation | Every few hrs | Dopamine moment |
| Weekly Jum'at Berkah | 1×/week | Social event |
| Seasonal events | Monthly | FOMO + cosmetics |
| Prestige (Buka Cabang) | Major milestone | Reset with power fantasy |
| Visit friends | Any time | Social loop |

---

## 13. Out of Scope (v1)

- Real-time PvP
- Voice chat / real adhan audio (Roblox ToS)
- Full open-world exploration
- Custom santri character creation

---

## 14. Open Questions

1. Should Waktu Sholat timers use real-world prayer times or fixed in-game intervals? Fixed in-game
2. Ramadan event — use real Hijri calendar or fixed in-game event window? Fixed in-game
3. Is multiplayer co-op (shared pesantren) feasible for v1 scope? Yes
4. Any specific Indonesian cultural elements to highlight or avoid? No

---

## 15. Cross-Platform Requirements

Game must be fully playable on **all Roblox-supported platforms** with no degraded feature access:

| Platform | Input | Notes |
|---|---|---|
| **Desktop** | Keyboard + Mouse | Primary dev target |
| **Mobile (Phone)** | Touch | Must be fully featured, not stripped |
| **Tablet** | Touch (larger viewport) | Same as mobile, more screen real estate |
| **Console (Xbox/PlayStation)** | Gamepad | D-pad + thumbstick navigation |

### Input Abstraction — ContextActionService First

Use **ContextActionService** for all player actions. Never bind raw `UserInputService` key checks for gameplay actions. This guarantees one binding works across keyboard, touch, and gamepad automatically.

```luau
-- Correct
ContextActionService:BindAction("InteractBuilding", callback, true, Enum.KeyCode.E, Enum.KeyCode.ButtonX)

-- Wrong (desktop-only)
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E then ...
```

### Touch & Mobile Rules

- All interactive 3D objects use **ProximityPrompt** — Roblox renders the native tap button on mobile automatically, no custom touch detection needed.
- No interaction that requires hover state (hover = desktop only).
- Minimum GUI touch target: **44×44 studs** screen space.
- All ScreenGui elements use `Scale`-based UDim2 values (no hardcoded pixel offsets).
- Account for device safe area (notch/home bar) using `GuiService:GetGuiInset()` for HUD placement.
- HUD buttons grouped at bottom of screen for thumb reach on phones.

### Gamepad Rules

- All menus navigable with D-pad + **A** (confirm) / **B** (back).
- Use `GuiService.SelectedObject` to manage gamepad focus — never assume mouse.
- No UI that requires text input in core loop. Search/name fields are optional features only.

### Performance Budget (cross-platform)

| Metric | Target |
|---|---|
| Frame rate | 30 fps minimum on mid-tier mobile |
| Part count per zone | ≤ 2,000 parts visible at once |
| Script memory | ≤ 150 MB total |
| Network RPS | ≤ 20 RemoteEvent fires/sec per client |

Use `workspace.StreamingEnabled = true`. Distant buildings swap to lower-poly mesh or billboard sprite via LOD.

---

## 16. Roblox Native API Priority

**Rule:** Use a Roblox first-party API before building a custom solution. Custom solutions add maintenance burden and can break on engine updates.

### Interaction

| Need | Use | Not |
|---|---|---|
| 3D object interaction | `ProximityPrompt` | Custom ClickDetector + touch raycast |
| NPC dialogue trigger | `ProximityPrompt` + BillboardGui | Custom 3D click region |
| Item/reward pickup | `ProximityPrompt` (HoldDuration) | Custom overlap detection |

### UI

| Need | Use | Not |
|---|---|---|
| Floating label above building | `BillboardGui` | Custom beam or part label |
| Screen HUD | `ScreenGui` (ResetOnSpawn=false) | Part-based UI |
| Building surface display | `SurfaceGui` | Decal swapping |
| Animated transitions | `TweenService` | Manual RunService lerp |
| UI layout | `UIListLayout`, `UIGridLayout` | Manual position math |
| Responsive sizing | `UIAspectRatioConstraint`, `UISizeConstraint` | Hardcoded pixel sizes |

### Data & Persistence

| Need | Use | Not |
|---|---|---|
| Player save data | `DataStoreService` (with retry + versioning) | Custom HTTP backend for core saves |
| Cross-server events (Tabligh Akbar) | `MessagingService` | Polling DataStore |
| Player teleport | `TeleportService` | Manual server join link |

### Tagging & Systems

| Need | Use | Not |
|---|---|---|
| Mark buildings by type | `CollectionService:AddTag()` | String attributes or manual tables |
| Collision groups | `PhysicsService:RegisterCollisionGroup()` | Per-script CanCollide toggling |
| Building state (level, owner) | `Instance:SetAttribute()` | Module-stored tables keyed by instance ref |

### Monetization

| Need | Use | Not |
|---|---|---|
| Robux product purchase | `MarketplaceService:PromptProductPurchase()` | External payment redirect |
| Game Pass check | `MarketplaceService:UserOwnsGamePassAsync()` | DataStore flag (exploitable) |
| Premium membership check | `Players.LocalPlayer.MembershipType` | Manual check endpoint |

### Haptics (mobile immersion)

Use `HapticService:SetMotor()` for short vibration pulses on:
- Waktu Sholat bonus trigger
- Santri graduation
- Masalah event alert

---

## 17. Project Structure

Follows the Rojo layout defined in `default.project.json`. All source under `src/`.

```
src/
├── Server/
│   ├── init.server.luau          # Bootstrap: load all services
│   ├── Services/
│   │   ├── DataService.luau      # DataStore wrapper, player save/load
│   │   ├── EconomyService.luau   # Rupiah/Barakah/Ilmu transactions
│   │   ├── EventService.luau     # Waktu Sholat, seasonal event scheduler
│   │   └── ReplicationService.luau # Sync game state to clients
│   └── Managers/
│       ├── SantriManager.luau    # Spawn, needs tick, dropout logic
│       ├── BuildingManager.luau  # Place, upgrade, zone unlock
│       ├── UstadzManager.luau    # Hire, fatigue, rarity roll
│       └── ReputationManager.luau
│
├── Client/
│   ├── init.client.luau          # Bootstrap: load all controllers
│   ├── Controllers/
│   │   ├── InputController.luau  # ContextActionService bindings
│   │   ├── UIController.luau     # Open/close menus, HUD state
│   │   ├── BuildController.luau  # Building placement UI flow
│   │   └── NotifController.luau  # Toast alerts (masalah, events)
│   └── Components/
│       ├── HUD.luau              # Income display, currency bars
│       ├── BuildMenu.luau        # Building shop panel
│       ├── SantriPanel.luau      # Santri list + needs overview
│       └── EventBanner.luau      # Waktu Sholat / seasonal banner
│
├── Character/
│   └── init.client.luau          # Camera, character controls
│
└── Shared/
    ├── Modules/
    │   ├── Types.luau            # Strict type definitions (Luau types)
    │   ├── Constants.luau        # Tuning values (income rates, costs)
    │   ├── Utils.luau            # Pure helper functions
    │   └── Network.luau          # RemoteEvent/RemoteFunction refs
    ├── Data/
    │   ├── BuildingData.luau     # All building definitions + tier costs
    │   ├── SantriData.luau       # Program definitions, need decay rates
    │   ├── UstadzData.luau       # Rarity table, skill ranges
    │   └── EventData.luau        # Event schedules, reward tables
    └── Net/
        ├── Events.luau           # All RemoteEvent instances (defined once)
        └── Functions.luau        # All RemoteFunction instances
```

### Architecture Rules

1. **Server is authoritative.** Clients fire RemoteEvents; server validates and applies state. Economy, santri state, and reputation live server-side only.
2. **No business logic in LocalScripts.** Controllers handle input and render UI. Calculations (income, dropout, event reward) run on the server.
3. **Data defined once in `Shared/Data/`.** No magic numbers in scripts — reference `Constants.luau` or the relevant Data module.
4. **Services own their domain.** `EconomyService` is the only script that mutates currency. No other script adds/subtracts Rupiah directly.
5. **Strict Luau types.** All modules start with `--!strict`. Types defined in `Shared/Modules/Types.luau`, imported where needed.
6. **Centralized network layer.** All RemoteEvents defined in `Shared/Net/Events.luau`. No `Instance.new("RemoteEvent")` scattered in scripts.
7. **CollectionService for building instances.** Tag every placed building part (`"Building"`, `"Masjid"`, `"Dormitory"` etc.). Managers query by tag, not by path.

### Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Modules | PascalCase | `DataService.luau` |
| Functions | camelCase | `getSantriCount()` |
| Constants | SCREAMING_SNAKE | `MAX_SANTRI_PER_ZONE` |
| RemoteEvents | PascalCase verb-noun | `PurchaseBuilding`, `TriggerEvent` |
| CollectionService tags | PascalCase | `"Dormitory"`, `"FoodBuilding"` |
| Instance attributes | camelCase | `part:SetAttribute("buildingLevel", 2)` |
