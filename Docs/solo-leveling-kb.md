# Solo Leveling — Knowledge Base

Reference material from the Solo Leveling (나 혼자만 레벨업) manhwa/anime/light novel.

---

## Hunter Ranks

Hunters are humans who awakened with supernatural abilities. Ranked by measured power:

| Rank | Description | Notes |
|------|-------------|-------|
| **E-Rank** | Weakest hunters. Slightly superhuman. | Often work support roles, can't solo low-tier dungeons |
| **D-Rank** | Can clear basic Gates. Most common rank. | Reliable but limited |
| **C-Rank** | Professional level. | Can form raid parties for mid-tier dungeons |
| **B-Rank** | Elite hunters. Rare abilities. | Often guild leaders or vice-leaders |
| **A-Rank** | Top 1% of hunters. National-level assets. | Can solo high-tier dungeons. Extremely rare |
| **S-Rank** | The pinnacle. Strategic assets. | Can solo Red Gates, fight Monarchs. Nations compete for them |
| **National Level** | Unofficial rank for strongest S-Ranks. | Only five exist worldwide. Jinwoo surpasses even this |

### Re-Awakening
- Hunters can "re-awaken" and jump ranks (rare).
- Sung Jinwoo is the only hunter who gained a System that allows leveling.

---

## Hunter Classes (Types)

Six official classes divided into two categories:

### Fighter Types
| Class | Role | Key Traits |
|-------|------|-----------|
| **Fighter** | Balanced melee combat | Strength-focused, frontline, versatile |
| **Assassin** | Speed and stealth | High agility, burst damage, evasion |
| **Tanker** | Defense and aggro | High vitality, absorbs damage, protects party |
| **Ranger** | Ranged physical attacks | Bows, projectiles, kiting, positioning |

### Mage Types
| Class | Role | Key Traits |
|-------|------|-----------|
| **Mage** | Elemental/magic attacks | Intelligence-focused, AoE damage, crowd control |
| **Healer** | Recovery and support | Restoration, buffs, essential for raids |

---

## The System (Sung Jinwoo Only)

After the Double Dungeon incident, Jinwoo gains access to a unique leveling System:

### Core Mechanics
- **Quests** give experience points (daily quests, emergency quests, penalty quests)
- **Leveling** increases base stats
- **Stat points** can be manually allocated on level-up
- **Skills** can be unlocked and upgraded
- **Items** drop from dungeons and quests

### Stats
| Stat | Effect | In-App Mapping |
|------|--------|---------------|
| **Strength (STR)** | Physical damage output | Workouts / Weight Training |
| **Agility (AGI)** | Speed and evasion | Steps, Cardio, Movement |
| **Vitality (VIT)** | Health and endurance | Cardio Health, Heart Rate |
| **Intelligence (INT)** | Mana pool and magic damage | Reading, Learning |
| **Perception (PER)** | Awareness and detection | Meditation, Mindfulness (mapped to Sense in app) |

### Daily Quest (Penalty System)
Jinwoo's System issues mandatory daily quests:
- **100 push-ups**
- **100 sit-ups**
- **100 squats**
- **10 km run**
- Failure to complete → **Penalty Zone** (extraction quest with harsh punishment)

### Key Skills
- **Shadow Extraction** — Turn defeated enemies into shadow soldiers
- **Shadow Exchange** — Teleport to shadow locations
- **Ruler's Authority** — Telekinesis
- **Domain of the Monarch** — Enhanced territory control

---

## Shadow Army

### How Extraction Works
- After killing an enemy, Jinwoo can extract their shadow
- Shadows retain abilities from life
- Stronger enemies = stronger shadows
- Shadows can level up independently
- No limit to army size (eventually)

### Notable Shadows
| Shadow | Origin | Role |
|--------|--------|------|
| **Igris** | Blood-red knight | First major extraction, loyal knight |
| **Tusk** | High Orc shaman | Magic support |
| **Iron** | Tank demon | Heavy frontline |
| **Beru** | Ant King | Strongest shadow initially, healer abilities |
| **Greed** | Giant knight | Heavy assault |

---

## Gates and Dungeons

### Gate Ranks
- Gates (portals) are ranked **E through S**, matching required Hunter levels
- **Red Gates** are special — they trap Hunters inside until the dungeon is cleared
- Higher rank = exponentially more dangerous

### Dungeon Breaks
- If a Gate isn't cleared in time, monsters pour into the real world
- Higher rank Gate breaks = civilization-ending threats
- S-Rank breaks require national-level response

---

## The True Origin

**[MAJOR SPOILER]**

The System exists because Jinwoo is the vessel for **Ashborn, the Shadow Monarch**. The System was designed to train him to inherit Ashborn's full power and fight the other Monarchs who seek to destroy humanity.

---

## Activity → Stat XP Mapping (Auto-Leveling System)

Stats **auto-level** based on the XP earned in their respective activity area. There is no manual stat-point distribution — every activity routes XP directly to one of the five stats.

### Strength (STR)
| Source | XP Calculation | File |
|--------|---------------|------|
| Gym workout sessions (live logging) | Per-set XP + session bonus, capped at 500/session | `ActiveWorkoutView.swift` |
| HKWorkout: traditional/functional strength training, core training | Mapped via `WorkoutStatMapper` | `HealthSyncEngine.swift` |

### Agility (AGI)
| Source | XP Calculation | File |
|--------|---------------|------|
| Manual flexibility/yoga/calisthenics sessions | `session.xpEarned` | `LogFlexibilityView.swift` |
| HKWorkout: yoga, pilates, dance, martial arts, gymnastics, climbing, mind & body | Mapped via `WorkoutStatMapper` | `HealthSyncEngine.swift` |

### Vitality (VIT)
| Source | XP Calculation | File |
|--------|---------------|------|
| Daily steps | 1 XP per 100 steps, cap 150/day | `HealthSyncEngine.swift` |
| Sleep hours | hours × 5, +10 bonus for 7-9h | `HealthSyncEngine.swift` |
| Active energy burned | kcal / 50, cap 50/day | `HealthSyncEngine.swift` |
| HKWorkout: running, walking, cycling, swimming, HIIT, rowing, hiking | Mapped via `WorkoutStatMapper` | `HealthSyncEngine.swift` |

### Sense (SEN)
| Source | XP Calculation | File |
|--------|---------------|------|
| Meditation timer sessions | `XPCalculator.senseXP(durationMinutes:consecutiveDays:)` | `MeditationTimerView.swift` |
| Manual mindfulness logs | `session.xpEarned` | `SenseView.swift` |
| HK mindful sessions (Apple Health) | Same formula as meditation timer | `HealthSyncEngine.swift` |

### Intelligence (INT)
| Source | XP Calculation | File |
|--------|---------------|------|
| Reading entries (pages × duration) | `entry.xpEarned` | `IntelligenceService.swift` |
| Learning sessions (courses, coding, study) | `session.xpEarned` | `IntelligenceService.swift` |

### Daily Quests (6 fixed rings, Apple Activity-style grid)
The dashboard / Quests tab shows exactly 6 daily quests — one per stat area + Recovery:

| Quest | Category | Stat | Default Target | Tracking |
|-------|----------|------|---------------|----------|
| **Strength** | `.strength` | STR | 50 SP | Composite Strength Points (see below) |
| **Agility** | `.flexibility` | AGI | 20 min | Yoga / calisthenics / stretching minutes |
| **Vitality** | `.cardioDistance` | VIT | 30 min | Cardio workout minutes |
| **Sense** | `.meditation` | SEN | 10 min | Meditation minutes |
| **Intelligence** | `.knowledge` | INT | 30 min | Reading + learning minutes combined |
| **Recovery** | `.sleep` | VIT | 7 hours | Sleep hours from HealthKit |

Each ring is **tap-to-customize** (Apple Activity-Ring style) — opens a sheet with a slider to adjust the target. Saved to `UserDefaults("questCustomTargets")`.

Quest rewards route XP to the quest's `statType` — e.g., the strength quest awards STR XP, the meditation quest awards SEN XP, the recovery (sleep) quest awards VIT XP.

### Strength Points (SP) — Composite Strength Quest
The strength quest is hit by accumulating **Strength Points** from bodyweight work + walking:

| Movement | SP per rep |
|----------|-----------|
| Pushup, dip, burpee | **1.0 SP** |
| Pullup, chin-up, muscle-up | **3.0 SP** |
| Situp, crunch, plank, leg-raise, hollow, V-up, Russian twist | **0.5 SP** |
| Walking (100 steps) | **1.0 SP** (cap 30 SP from steps alone) |

Reps are sourced from logged `WorkoutSession` sets (matched by exercise name) and steps from HealthKit. Logic lives in `StrengthPointsCalculator`. Default daily target: **50 SP**.

### Player Total Level
The player's overall level is computed from `totalXP` (the sum of all XP earned across all stats). When a stat earns XP, it accumulates both at the stat level and the player's `totalXP`. No stat points are awarded at level-up — leveling up is purely a milestone marker for the **rank** progression and **hunter class** assignment.

---

## App Implementation Mapping

### Hunter Classes → Activity-Based Assignment
Classes are assigned automatically once the player reaches **D-Rank (Level 10)** based on stat distribution:

| Class | Primary Stat | Trigger Activities | Hybrid Rule |
|-------|-------------|-------------------|-------------|
| **Fighter** | STR dominant | Weight training, resistance exercises | — |
| **Assassin** | AGI dominant | Calisthenics, yoga, martial arts | STR + AGI close → Assassin |
| **Tanker** | VIT dominant | Running, cycling, swimming (endurance) | STR + VIT close → Tanker |
| **Ranger** | AGI + VIT | Distance running, cycling | AGI + VIT close → Ranger |
| **Mage** | INT dominant | Reading, coding, learning | INT + SEN close → Healer |
| **Healer** | SEN dominant | Meditation, mindfulness, breathing | — |

**Dominance threshold**: If the top stat is ≥ 20% higher than the second, the direct 1:1 mapping applies. Otherwise, hybrid rules kick in.

### Hunter Titles → Milestone-Based Earning
Titles are earned through achievements and displayed on the status card:

| Title | Condition |
|-------|----------|
| Novice Hunter → Absolute Being | Rank-based (D through SSS) |
| Iron Will / Unbreakable / Relentless | 7 / 30 / 100 day streak |
| Steel Fist, Wind Walker, Stone Heart, Third Eye, Sage Mind | Any stat reaches level 25 |
| Penalty Survivor | Escape the Penalty Zone |

### Rank Descriptions (Lore-Aligned)
- **E-Rank**: Weakest. Slightly superhuman. Every journey starts here.
- **D-Rank**: Can clear basic Gates. Your awakening has begun. (Class assigned here)
- **C-Rank**: Professional level. Respected in the hunter community.
- **B-Rank**: Elite hunter. Rare abilities set you apart.
- **A-Rank**: Top 1%. A national-level asset.
- **S-Rank**: The pinnacle. Nations compete for your allegiance.
- **SS-Rank**: Legendary power. You stand above S-Rank.
- **SSS-Rank**: Transcendent being. Your name echoes through history.

---

## App Design Inspiration

### Status Window UI
The Solo Leveling status window features:
- Dark blue/black background with marble-like texture
- Glowing blue border with corner accents
- **"STATUS"** title in bordered header
- Large level number prominently displayed
- Job and Title labels
- HP and MP progress bars
- Stat grid layout: STR, VIT, AGI, INT, PER, AP (available points)
- Values displayed in monospaced, glowing white font
- Overall aesthetic: sci-fi holographic panel

### Color Palette
- **Primary**: Deep navy/black (`#0A0E1A` to `#141B2D`)
- **Borders/Accents**: Electric blue (`#4A9EFF`, `#2B7FFF`)
- **Glow**: Soft blue (`#4A9EFF` at 30-40% opacity)
- **Text**: White with slight blue tint
- **Secondary text**: Muted blue-gray
- **Stats**: Each stat can have its own accent color
