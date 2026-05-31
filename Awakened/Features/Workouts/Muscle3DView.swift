import SwiftUI
import RealityKit

/// **Phase 2 — RealityKit 3D anatomy viewer (asset-gated).**
///
/// This is the scaffolding for the eventual 3D muscle map. It loads a
/// segmented USDZ model from the bundle, attaches input/collision components
/// to each muscle entity by name, and swaps materials per-muscle based on
/// `MuscleStatsService` output.
///
/// ## How to enable
/// 1. Add the segmented USDZ files to the app bundle:
///    - `Awakened/Resources/Anatomy/MaleBody.usdz`
///    - `Awakened/Resources/Anatomy/FemaleBody.usdz`
///    Each model **must** preserve a hierarchy where every muscle is a
///    separately-named child entity (see `Muscle3DEntity` for required names).
/// 2. Set `Muscle3DView.is3DEnabled = true` (or flip the flag at runtime).
/// 3. `MuscleMapView` will swap from the SDK 2D view to this 3D view.
///
/// See `docs/MUSCLE_MAP_PLAN.md` for full pipeline & licensing notes.
struct Muscle3DView: View {

    /// Master flag. Stays `false` until a segmented USDZ ships in the bundle.
    /// When you have the asset, flip this to `true`.
    static let is3DEnabled: Bool = false

    let isMale: Bool
    let intensitiesByRegion: [AnatomyRegion: MuscleLevel]
    let onSelect: (AnatomyRegion) -> Void

    @State private var loadError: String?

    var body: some View {
        Group {
            if Muscle3DView.is3DEnabled {
                realityViewBody
            } else {
                placeholder
            }
        }
    }

    // MARK: - RealityView path (active once asset is bundled)

    @ViewBuilder
    private var realityViewBody: some View {
        RealityView { content in
            do {
                let modelName = isMale ? "MaleBody" : "FemaleBody"
                let body = try await Entity(named: modelName)
                Muscle3DEntity.configureMuscleEntities(in: body)
                Muscle3DEntity.applyLevels(intensitiesByRegion, to: body)
                content.add(body)
                // Camera + lighting presets land with the actual asset.
            } catch {
                loadError = "Failed to load anatomy model: \(error.localizedDescription)"
            }
        } update: { content in
            // Re-apply colours when intensities change
            if let body = content.entities.first {
                Muscle3DEntity.applyLevels(intensitiesByRegion, to: body)
            }
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    if let region = Muscle3DEntity.region(forEntityName: value.entity.name) {
                        onSelect(region)
                    }
                }
        )
        .overlay(alignment: .top) {
            if let err = loadError {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Placeholder while asset is missing

    private var placeholder: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textTertiary)
            Text("3D model not yet bundled")
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textSecondary)
            Text("See docs/MUSCLE_MAP_PLAN.md, Phase 2")
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .background(AppColors.surfaceElevated.opacity(0.4))
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

// MARK: - Muscle3DEntity (entity discovery + material swap)

/// Discovers muscle entities by name inside a loaded model and configures
/// them for tap interaction + material swapping.
enum Muscle3DEntity {

    /// Entity-name → `AnatomyRegion` map. Names must match the USDZ hierarchy.
    /// Multiple entity names can map to one region (e.g. left+right halves).
    static let nameToRegion: [String: AnatomyRegion] = [
        "chest_left": .chest, "chest_right": .chest,
        "deltoid_left": .shoulders, "deltoid_right": .shoulders,
        "biceps_left": .biceps, "biceps_right": .biceps,
        "triceps_left": .triceps, "triceps_right": .triceps,
        "forearm_left": .forearms, "forearm_right": .forearms,
        "abs_upper": .abs, "abs_lower": .abs,
        "obliques_left": .abs, "obliques_right": .abs,
        "upper_back": .back, "lower_back": .back,
        "lats_left": .back, "lats_right": .back,
        "trapezius_upper": .back, "trapezius_lower": .back,
        "glutes_left": .glutes, "glutes_right": .glutes,
        "quads_left": .quads, "quads_right": .quads,
        "hamstrings_left": .hamstrings, "hamstrings_right": .hamstrings,
        "calves_left": .calves, "calves_right": .calves
    ]

    static func region(forEntityName name: String) -> AnatomyRegion? {
        nameToRegion[name.lowercased()]
    }

    /// Walk the loaded model and attach `InputTargetComponent` +
    /// `CollisionComponent` to every recognised muscle entity so taps land.
    static func configureMuscleEntities(in root: Entity) {
        for child in allDescendants(of: root) {
            guard nameToRegion[child.name.lowercased()] != nil,
                  let model = child as? ModelEntity else { continue }
            model.components.set(InputTargetComponent())
            // Capsule/sphere fallback in case generateConvex fails on dense meshes
            let bounds = model.visualBounds(relativeTo: nil)
            let halfExtents = SIMD3<Float>(
                Float(bounds.extents.x) * 0.5,
                Float(bounds.extents.y) * 0.5,
                Float(bounds.extents.z) * 0.5
            )
            model.components.set(CollisionComponent(shapes: [.generateBox(size: halfExtents * 2)]))
        }
    }

    /// Apply per-muscle materials based on their current `MuscleLevel`.
    static func applyLevels(
        _ levels: [AnatomyRegion: MuscleLevel],
        to root: Entity
    ) {
        for child in allDescendants(of: root) {
            guard let region = nameToRegion[child.name.lowercased()],
                  let model = child as? ModelEntity else { continue }
            let level = levels[region] ?? .untrained
            model.model?.materials = [makeMaterial(for: level)]
        }
    }

    private static func makeMaterial(for level: MuscleLevel) -> RealityKit.Material {
        var mat = PhysicallyBasedMaterial()
        let uic = UIColor(level.color)
        mat.baseColor = .init(tint: uic.withAlphaComponent(0.95))
        mat.roughness = .init(floatLiteral: 0.55)
        mat.metallic = .init(floatLiteral: 0.0)
        // Higher levels glow more
        let emissive = CGFloat(level.rawValue) / 4.0
        mat.emissiveColor = .init(color: uic.withAlphaComponent(emissive * 0.6))
        mat.emissiveIntensity = Float(emissive) * 1.2
        return mat
    }

    private static func allDescendants(of entity: Entity) -> [Entity] {
        var stack: [Entity] = [entity]
        var out: [Entity] = []
        while let next = stack.popLast() {
            out.append(next)
            stack.append(contentsOf: next.children)
        }
        return out
    }
}

// Camera & lighting presets (Phase 2 polish — implemented when asset lands).
// They will configure a perspective camera at (0, 1.0, 2.5) looking at origin
// and add purple/blue rim lights + a soft front-key light to match the
// mockup's sculpted look. Sized off model bounds available at load time.
