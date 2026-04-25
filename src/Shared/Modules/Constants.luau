--!strict

local Constants = {}

-- ─── Economy ──────────────────────────────────────────────────────────────────
Constants.RUPIAH_BASE_PER_SANTRI_PER_MIN = 10
Constants.BARAKAH_BASE_PER_HAFIDZ_GRAD = 50
Constants.ILMU_BASE_PER_SANTRI_PER_MIN = 5
Constants.SEDEKAH_JARIYAH_PER_ALUMNI = 2 -- Rupiah/min added per graduated alumni, forever

-- ─── Santri needs (decay per in-game minute) ──────────────────────────────────
Constants.NEED_MAKAN_DECAY = 3
Constants.NEED_ILMU_DECAY = 2
Constants.NEED_IBADAH_DECAY = 2
Constants.NEED_ISTIRAHAT_DECAY = 1

-- ─── Happiness thresholds ─────────────────────────────────────────────────────
Constants.HAPPINESS_PENALTY_THRESHOLD = 50 -- below → income penalty
Constants.HAPPINESS_DROPOUT_THRESHOLD = 20 -- below → 10% dropout chance per tick
Constants.HAPPINESS_BONUS_THRESHOLD = 90 -- above → bonus Barakah per tick

-- ─── Santri lifecycle ─────────────────────────────────────────────────────────
Constants.STUDY_PROGRESS_PER_MIN = 5 -- progress/min when ustadz is present & rested
Constants.UJIAN_PASS_CHANCE_BASE = 0.7 -- 70% base, +0.04 per ustadz skill star
Constants.TUTORING_COST_RUPIAH = 200 -- cost to retry after ujian fail
Constants.TUTORING_PROGRESS_RESET = 50 -- progress value after tutoring (head-start)

-- ─── Masalah events ───────────────────────────────────────────────────────────
Constants.MASALAH_ROLL_INTERVAL_MIN = 10 -- minutes between rolls
Constants.MASALAH_TRIGGER_CHANCE = 0.30 -- 30% chance per roll
Constants.MASALAH_EXPIRE_MIN = 5 -- minutes before cascade
Constants.MASALAH_FAST_RESOLVE_MIN = 2 -- resolved within this → bonus rep
Constants.MASALAH_SANTRISAKIT_COST = 300
Constants.MASALAH_USTADZABSEN_COST_RUPIAH = 150
Constants.MASALAH_USTADZABSEN_COST_BARAKAH = 10
Constants.MASALAH_BANJIR_COST = 500

-- ─── Ustadz ───────────────────────────────────────────────────────────────────
Constants.USTADZ_FATIGUE_DECAY_PER_HOUR = 10
Constants.USTADZ_RESTED_THRESHOLD = 80 -- fatigue level at which ustadz is effective
Constants.USTADZ_CANT_TEACH_THRESHOLD = 20 -- below → cannot teach
Constants.USTADZ_RESTORE_COST_RUPIAH = 100 -- partial restore (+30 fatigue)
Constants.USTADZ_RESTORE_AMOUNT = 30
Constants.USTADZ_LIBUR_DURATION_SEC = 7200 -- 2 real hours to fully recover

-- ─── Reputation ───────────────────────────────────────────────────────────────
Constants.REP_PER_GRADUATION = 2
Constants.REP_PER_BUILDING_UPGRADE = 1
Constants.REP_PER_MASALAH_FAST_RESOLVE = 3
Constants.REP_PER_VISITOR = 0.5
Constants.REP_TIER_BERKEMBANG = 50
Constants.REP_TIER_UNGGULAN = 75
Constants.REP_TIER_PRESTIGE_UNLOCK = 100

-- ─── Prestige ─────────────────────────────────────────────────────────────────
Constants.PRESTIGE_RUPIAH_MULTIPLIER_PER_COUNT = 0.15 -- +15% per prestige
Constants.PRESTIGE_STARTING_RUPIAH = 500
Constants.KUNJUNGAN_MENTERI_MULTIPLIER = 5
Constants.KUNJUNGAN_MENTERI_DURATION_SEC = 180 -- 3 real minutes

-- ─── Events ───────────────────────────────────────────────────────────────────
Constants.WAKTU_SHOLAT_INTERVAL_MIN = 288 -- 5 prayer windows per 1440-min day
Constants.WAKTU_SHOLAT_DURATION_SEC = 60
Constants.WAKTU_SHOLAT_MULTIPLIER = 3
Constants.SHOLAT_SEMPURNA_RUPIAH = 50
Constants.SHOLAT_SEMPURNA_BARAKAH = 5

Constants.JUMAT_BERKAH_MULTIPLIER = 2
Constants.JUMAT_BERKAH_DURATION_MIN = 30

Constants.TABLIGH_AKBAR_MIN_PLAYERS = 10
Constants.TABLIGH_AKBAR_MULTIPLIER = 5
Constants.TABLIGH_AKBAR_DURATION_MIN = 5
Constants.TABLIGH_AKBAR_BARAKAH_COST = 5 -- per voting player

Constants.RAMADAN_NEED_MAKAN_DECAY_REDUCTION = 0.30 -- 30% slower Makan decay
Constants.TARAWIH_BARAKAH_REWARD = 10

-- ─── Social ───────────────────────────────────────────────────────────────────
Constants.DOA_BARAKAH_GIFT = 1 -- to both visitor and host per Doa
Constants.DOA_COOLDOWN_SEC = 86400 -- 24 real hours
Constants.KUNJUNGAN_TAMU_DURATION_MIN = 10
Constants.WAQF_UPGRADE_THRESHOLD = 10000 -- Rupiah pool needed to upgrade shared Masjid

-- ─── Zone unlock thresholds (total santri count) ──────────────────────────────
Constants.ZONE_2_UNLOCK = 20
Constants.ZONE_3_UNLOCK = 100
Constants.ZONE_4_UNLOCK = 250
Constants.ZONE_5_UNLOCK = 600

-- ─── Monetisation ─────────────────────────────────────────────────────────────
Constants.STARTER_PACK_DURATION_SEC = 1800 -- 30 real minutes
Constants.STARTER_PACK_MULTIPLIER = 2
Constants.TIME_SKIP_FALLBACK_RUPIAH = 1000 -- granted if player has no alumni
Constants.GAMEPASS_PREMIUM_MULTIPLIER = 1.2

-- ─── Auto-enroll ──────────────────────────────────────────────────────────────
Constants.AUTO_ENROLL_INTERVAL_MIN = 5 -- one free santri every N in-game minutes

-- ─── Performance ──────────────────────────────────────────────────────────────
Constants.MAX_PARTS_PER_ZONE = 2000
Constants.MAX_NETWORK_RPS = 20

return Constants
