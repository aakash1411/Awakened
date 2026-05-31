import SceneKit
import SwiftUI
import UIKit

/// Turns a `MuscleScore` into a `SCNMaterial` for the 3D body.
///
/// Visual rules (per the design brief):
/// - High score  → brighter / more saturated tier colour.
/// - Low score   → muted toward grey.
/// - High fatigue→ warm red/orange overlay.
/// - Selected    → emissive glow.
/// - Unselected (while something is selected) → dimmed but still visible.
enum MuscleMaterialMapper {

    /// Colour ramp by tier (matches the app's `MuscleLevel` palette).
    private static func tierColor(_ level: Int) -> UIColor {
        switch max(0, min(4, level)) {
        case 0: return UIColor(Color(hex: "55606F")) // grey
        case 1: return UIColor(Color(hex: "5AC8FA")) // blue
        case 2: return UIColor(Color(hex: "34C759")) // green
        case 3: return UIColor(Color(hex: "FF9500")) // orange
        default: return UIColor(Color(hex: "FF3B30")) // red
        }
    }

    private static let mutedGrey = UIColor(Color(hex: "3A4150"))
    private static let fatigueWarm = UIColor(Color(hex: "FF5A36"))

    /// Material for a scored muscle.
    static func material(for score: MuscleScore, isSelected: Bool, dimmed: Bool) -> SCNMaterial {
        // Base: interpolate grey → tier colour by score so weak muscles read muted.
        var color = blend(mutedGrey, tierColor(score.level),
                          t: 0.30 + 0.70 * CGFloat(score.normalizedScore))

        // Fatigue overlay.
        if score.fatigue > 0 {
            color = blend(color, fatigueWarm, t: 0.45 * CGFloat(min(1, score.fatigue)))
        }

        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.roughness.contents = 0.55
        material.metalness.contents = 0.0

        if isSelected {
            material.diffuse.contents = brighten(color, by: 0.12)
            material.emission.contents = color
            material.emission.intensity = 0.65
        } else if dimmed {
            material.diffuse.contents = blend(color, .black, t: 0.35)
            material.transparency = 0.8
        } else {
            material.diffuse.contents = color
        }
        return material
    }

    /// Neutral material for non-muscle body parts (head, hands, feet, joints).
    static func baseMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor(Color(hex: "2A2F3A"))
        material.roughness.contents = 0.8
        material.metalness.contents = 0.0
        return material
    }

    // MARK: - Colour helpers

    private static func blend(_ a: UIColor, _ b: UIColor, t: CGFloat) -> UIColor {
        let t = max(0, min(1, t))
        let ca = components(of: a)
        let cb = components(of: b)
        return UIColor(
            red: ca.r + (cb.r - ca.r) * t,
            green: ca.g + (cb.g - ca.g) * t,
            blue: ca.b + (cb.b - ca.b) * t,
            alpha: ca.a + (cb.a - ca.a) * t
        )
    }

    private static func brighten(_ color: UIColor, by amount: CGFloat) -> UIColor {
        let c = components(of: color)
        return UIColor(
            red: min(1, c.r + amount),
            green: min(1, c.g + amount),
            blue: min(1, c.b + amount),
            alpha: c.a
        )
    }

    private static func components(of color: UIColor) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}
