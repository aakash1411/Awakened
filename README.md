# Awakened

**A Solo Leveling-inspired fitness RPG for iOS**

Transform your real-world fitness journey into an immersive RPG experience. Track strength training, cardio, meditation, learning, and nutrition while leveling up your hunter through five core stats: **Strength**, **Vitality**, **Intelligence**, **Sense**, and **Agility**.

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-Private-red.svg)]()

---

## 🎮 Features

### Core Systems
- **5-Stat Progression System**: STR, VIT, INT, SEN, AGI with pentagon radar visualization
- **XP & Leveling**: Earn XP from workouts, cardio, meditation, reading, and learning
- **Rank System**: E → S rank progression with visual badges
- **Daily Quests**: 6 customizable daily quests with Apple Activity Ring-style UI
- **Achievements**: 30+ unlockable achievements tracking milestones

### Fitness Modules

#### 💪 Strength (Gym Logging)
- 870+ exercise database from [free-exercise-db](https://github.com/yuhonas/free-exercise-db)
- Live workout tracking with set logging, rest timer, PR detection
- Personal records tracking (max weight, reps, volume, estimated 1RM)
- Workout templates (6 built-in + custom)
- **Muscle Anatomy Map** (Phase 1: MuscleMap SDK integration)
  - Segmented vector anatomy (22 muscles + 14 sub-groups)
  - Male/female × front/back views
  - Per-muscle coloring driven by workout volume (0-4 levels)
  - Tap detection → muscle detail sheets
  - Phase 2 ready: RealityKit 3D scaffold for USDZ models

#### 🏃 Vitality (Cardio & Health)
- Apple Health integration (HealthKit sync)
- Cardio activity tracking with route maps, pace splits, HR zones
- Weekly cardio stats & charts
- Strava OAuth integration (ready for API calls)
- Body measurements & weight tracking

#### 🧠 Intelligence (Learning & Reading)
- Reading log with page/time tracking
- Learning session tracker (courses, tutorials, practice)
- Weekly learning charts
- Goodreads/Notion integration placeholders

#### 🧘 Sense (Meditation & Mindfulness)
- Meditation timer with ambient sounds
- Session history & stats
- Apple Health mindfulness sync

#### 🤸 Agility (Flexibility & Mobility)
- Flexibility session logging (yoga, stretching, calisthenics)
- Duration & intensity tracking

#### 🍎 Nutrition
- MyFitnessPal-style macro tracking
- Food database (~50 seeded items, extensible)
- Meal logging with date navigation
- Recipe builder for custom foods
- Macro ring visualizations

### Social Features
- **Friends System**: Add friends, send/accept requests, view profiles
- **Activity Feed**: Share workouts, achievements, level-ups
- **Guilds**: Create/join guilds, guild quests, leaderboards
- **Duels**: 1v1 XP challenges with wager system
- **Seasons**: Ranked seasons with tier progression (Unranked → Champion)
- **Leaderboards**: Global, friends, guild rankings
- **Privacy Controls**: Public/friends-only/private profile settings

### Theming
- **4 Built-in Themes**: Awakened (dark), Anime (gamified), Professional (light), Pastel (soft)
- **Custom Theme Editor**: Full color customization with live preview
- **Theme Selection in Onboarding**

---

## 🛠 Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Data**: SwiftData + CloudKit (automatic sync)
- **Health**: HealthKit + CoreLocation (route tracking)
- **3D**: RealityKit (Phase 2 muscle map)
- **Dependencies**: 
  - [MuscleMap](https://github.com/melihcolpan/MuscleMap) 1.6.4 (SPM)
- **Minimum iOS**: 17.0
- **Target Device**: iPhone

---

## 📁 Project Structure

```
Awakened/
├── App/
│   ├── AwakenedApp.swift          # App entry point
│   ├── AppState.swift             # Global state + services
│   └── AppDelegate.swift          # Background tasks
├── Core/
│   ├── Models/                    # SwiftData models (15 total)
│   ├── Services/                  # Business logic (XP, Health, Stats, etc.)
│   ├── Utilities/                 # Helpers (SVGPathParser, etc.)
│   └── Extensions/                # Swift extensions
├── Features/
│   ├── Dashboard/                 # Main hub + weekly recap
│   ├── Workouts/                  # Strength module + muscle map
│   ├── Cardio/                    # Vitality cardio tracking
│   ├── Nutrition/                 # Macro tracking + food DB
│   ├── Intelligence/              # Reading + learning
│   ├── Sense/                     # Meditation timer
│   ├── Agility/                   # Flexibility logging
│   ├── Social/                    # Friends, guilds, duels, seasons
│   ├── Profile/                   # Settings, achievements, themes
│   ├── Onboarding/                # 6-page onboarding flow
│   └── Quests/                    # Daily quests UI
├── UI/
│   ├── Components/                # Reusable views (RadarChart, XPBar, etc.)
│   ├── Theme/                     # AppTheme, ThemeManager, design tokens
│   └── Modifiers/                 # SwiftUI modifiers (Glow, Pulse)
├── Resources/
│   └── exercises.json             # 870+ exercise database
├── Docs/
│   ├── solo-leveling-kb.md        # Design knowledge base
│   └── MUSCLE_MAP_PLAN.md         # 3D muscle map roadmap
└── themes/                        # Theme mockup assets
```

---

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ device or simulator
- Apple Developer account (for HealthKit entitlements)

### Installation

1. **Clone the repo**
   ```bash
   git clone https://github.com/aakash1411/Awakened.git
   cd Awakened
   ```

2. **Open in Xcode**
   ```bash
   open Awakened.xcodeproj
   ```

3. **Resolve Swift Package Dependencies**
   - Xcode will auto-resolve `MuscleMap` on first build
   - Or manually: `File > Packages > Resolve Package Versions`

4. **Configure Signing**
   - Select your development team in `Awakened` target > Signing & Capabilities
   - Update bundle identifier if needed

5. **Build & Run**
   - Select a simulator or device
   - `Cmd+R` to build and run

### First Launch
1. Complete the 6-page onboarding:
   - Welcome
   - Theme selection
   - Name & class
   - Goal setting
   - HealthKit permissions
   - Ready screen
2. Grant HealthKit permissions for full functionality
3. Start logging workouts, cardio, or complete daily quests

---

## 📊 Data Models

**15 SwiftData Models** (CloudKit-synced):
- `Player` — core progression (level, XP, stats, rank)
- `Quest` — daily quests with progress tracking
- `Achievement` — unlockable milestones
- `WorkoutSession`, `WorkoutSet`, `WorkoutTemplate` — strength training
- `PersonalRecord` — PRs per exercise
- `Exercise` — 870+ exercise definitions
- `FlexibilitySession`, `MeditationSession`, `ReadingEntry`, `LearningSession` — module tracking
- `FoodItem`, `MealEntry`, `BodyMeasurement` — nutrition & body tracking
- `CloudProfile`, `Guild`, `GuildQuest` — social features

---

## 🎯 Roadmap

### Phase 1 ✅ (Complete)
- Foundation: SwiftData, CloudKit, design system
- Apple Health integration
- Strength module (gym logging)
- Vitality module (cardio tracking)
- Intelligence, Sense, Agility modules
- Nutrition tracking
- Social features (friends, guilds, duels, seasons)
- Theme system
- **MuscleMap SDK integration** (segmented vector anatomy)

### Phase 2 🚧 (In Progress)
- **3D Muscle Map** (RealityKit + USDZ models)
  - Asset acquisition (commission or marketplace)
  - Segmented male/female models with named meshes
  - Camera presets, rim lighting, material swapping
  - See `Docs/MUSCLE_MAP_PLAN.md` for details

### Phase 3 📋 (Planned)
- AI workout generation (Foundation Models iOS 26+)
- Advanced analytics & insights
- Apple Watch companion app
- Widgets (Lock Screen, Home Screen, StandBy)
- Shortcuts integration
- Export/import data

---

## 🤝 Contributing

This is a private project. If you have access and want to contribute:

1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. Commit your changes (`git commit -m 'Add amazing feature'`)
3. Push to the branch (`git push origin feature/amazing-feature`)
4. Open a Pull Request

---

## 📄 License

**Private Repository** — All rights reserved.

### Third-Party Licenses
- **Exercise Database**: [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db) (Unlicense)
- **MuscleMap SDK**: [melihcolpan/MuscleMap](https://github.com/melihcolpan/MuscleMap) (MIT License)

---

## 🙏 Acknowledgments

- **Inspiration**: Solo Leveling (manhwa/anime)
- **Exercise Data**: [free-exercise-db](https://github.com/yuhonas/free-exercise-db)
- **Muscle Anatomy**: [MuscleMap](https://github.com/melihcolpan/MuscleMap) by Melih Colpan
- **Design References**: Hevy, Strong, MyFitnessPal, Apple Fitness

---

## 📧 Contact

**Aakash** — [@aakash1411](https://github.com/aakash1411)

**Project Link**: [https://github.com/aakash1411/Awakened](https://github.com/aakash1411/Awakened)

---

**Built with ❤️ and SwiftUI**
