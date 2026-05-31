# Muscle Map — Execution Plan

A two-phase plan. **Phase 1 ships now.** Phase 2 is asset-gated.

---

## Phase 1 — MuscleMap SwiftUI SDK (immediate, ships today)

**Goal:** Replace the image-crop figure with a true segmented vector anatomy
that supports per-muscle coloring driven by workout data.

**Why:** The MuscleMap SDK
([github.com/melihcolpan/MuscleMap](https://github.com/melihcolpan/MuscleMap))
already provides:
- 22 base muscles + 14 sub-groups
- Male/female × front/back views
- `.heatmap(data, colorScale:)` with intensity values 0–1
- Per-muscle tap detection via `.onMuscleSelected`
- Gradient highlighting, animated transitions, custom color scales

**What changes in the app:**
1. Add `MuscleMap` Swift Package (SPM, version `1.6.4+`).
2. Replace `MuscleMapView` body with `BodyView(gender:side:)`.
3. Convert `MuscleStatsService` output → `[MuscleIntensity]` (0–1 normalized).
4. Map our internal `AnatomyRegion` → `MuscleMap.Muscle` enum.
5. Use the `.workout` color scale (matches our level system: gray → yellow → orange → red).
6. Tap a muscle → drill into existing `MuscleDetailSheet`.
7. Add a Front/Back side toggle and keep the existing sex toggle.
8. Delete the image-crop assets and `AnatomyFigure.swift` once SDK is verified.

**Deliverables (Phase 1):**
- `Awakened/Features/Workouts/MuscleMapView.swift` — rewritten
- `Awakened/Features/Workouts/MuscleRegionMapping.swift` — region ↔ MuscleMap.Muscle bridge
- SPM dependency added to `Awakened.xcodeproj`

---

## Phase 2 — RealityKit 3D viewer (asset-gated)

**Hard prerequisite:** A licensed, segmented USDZ model.

### 2a. Asset acquisition (this is the blocker)

Decide one of:

| Option | Cost | Time | Quality |
|--------|------|------|---------|
| Commission custom model (Fiverr/Upwork 3D artist) | $500–2,000 | 2–4 weeks | Highest — exact art direction |
| License segmented anatomy from TurboSquid | $50–300 | hours | Variable; check mobile-app license |
| Build in Blender (in-house) | time | 2–8 weeks | Depends on skill |

**Required spec for the artist/marketplace:**
- Two USDZ files: `MaleBody.usdz`, `FemaleBody.usdz`
- Triangle budget: 30k–120k per body for mobile real-time
- Each muscle group is a **separate named child entity**, not a flattened mesh:
  ```
  root
  ├── chest_left, chest_right
  ├── deltoid_left, deltoid_right
  ├── biceps_left, biceps_right, triceps_left, triceps_right
  ├── forearm_left, forearm_right
  ├── abs_upper, abs_lower
  ├── obliques_left, obliques_right
  ├── upper_back, lower_back, lats_left, lats_right
  ├── trapezius_upper, trapezius_lower
  ├── glutes_left, glutes_right
  ├── quads_left, quads_right
  ├── hamstrings_left, hamstrings_right
  └── calves_left, calves_right
  ```
- Names must match the strings in `MuscleEntity.swift`.
- License terms must allow **commercial mobile app distribution** and **modification**.

### 2b. Code (already scaffolded — see `Muscle3DView.swift`)

Once the USDZ drops in `Awakened/Resources/Anatomy/MaleBody.usdz`, the
existing scaffolding turns on automatically (feature flag flips to `true`).

Architecture:
- `Muscle3DView` — RealityView wrapping the anatomy model
- `MuscleEntityRegistry` — discovers entities by name, attaches `InputTargetComponent` + `CollisionComponent`
- `MuscleMaterialController` — swaps `PhysicallyBasedMaterial` per muscle based on level
- `CameraPresets` — Front, Back, Left, Right, Upper, Lower, SelectedMuscleDetail
- `Muscle3DTapHandler` — `.gesture(TapGesture().targetedToAnyEntity())` → maps entity name → AnatomyRegion → drives selection state

### 2c. Visual recipe (apply once asset lands)

- Dark background plane behind the model
- Rim lights (purple/blue) from sides + soft key light from above-front
- Skin material: high roughness, normal map, AO map, base color
- Selected muscle: emissive rim + brighter diffuse + subtle pulse animation
- Inactive muscles: desaturated/dimmed
- Camera: orthographic-leaning low-FOV perspective; locked presets at first
- No free rotation in MVP (looks awkward at oblique angles)

### 2d. Performance guardrails

- Async load via `Entity(named:)` on a background actor
- Cache the loaded `Entity` — don't reload on every appear
- Pre-build the highlighted material variants once at load
- Simplified collision shapes (capsules/boxes) per muscle, not generated convex from full mesh
- Older devices (A12 and below): fall back to MuscleMap 2D path

---

## Phase 3 — Data integration (lands with Phase 1, expanded in Phase 2)

Already mostly built (`MuscleStatsService`). Modes the renderer should support:

| Mode | Source | Color meaning |
|------|--------|---------------|
| Strength level | `MuscleStatsService.computeAll` | gray → red, level 0–4 |
| Weekly volume | last-7-days set tonnage | thermal scale |
| Recovery | days since last trained | green (rested) → red (overtrained) |
| Imbalance | left vs right ratio | flag asymmetric pairs |
| Today's focus | quest plan | highlight only target muscles |

The `BodyView`/`Muscle3DView` both consume the same
`[MuscleIntensity]` array — switching modes is a one-line `intensitiesProvider`
change.

---

## Phase 1 acceptance criteria

- [ ] `BodyView(gender: .male, side: .front)` renders on the Workouts page
- [ ] Each muscle is colored by `MuscleStatsService` data
- [ ] Tapping a muscle opens the existing `MuscleDetailSheet`
- [ ] Front/Back toggle works
- [ ] Sex toggle (M/F) works
- [ ] No more cropped PNG figures in `Assets.xcassets`
- [ ] Builds clean for iPhone 17 Pro Max simulator

## Phase 2 acceptance criteria (post-asset)

- [ ] Model loads in <1.5s on iPhone 13+
- [ ] Tapping any muscle entity selects it
- [ ] Material swap completes in <100ms
- [ ] Camera presets transition smoothly
- [ ] 60fps sustained on iPhone 13+, 30fps minimum on iPhone XR
- [ ] Memory under 250MB
