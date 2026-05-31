import SceneKit
import UIKit

/// MVP body provider: assembles a stylised humanoid from SceneKit primitives
/// (capsules / boxes / spheres). No external assets, no network, mobile-safe
/// low-poly geometry.
///
/// Each muscle group is a separately-named node (`MuscleRegion.rawValue`) so
/// it can be coloured and tapped individually. Left/right halves share the
/// same name. Joints, head, hands and feet are named `"base"`.
///
/// TODO(USDZ): `USDZAnatomyModelProvider` will replace this with a real
/// segmented model. As long as that model keeps the same node names, nothing
/// downstream changes.
struct ProceduralAnatomyModelProvider: AnatomyModelProvider {

    /// Body proportions that differ a little by gender. Kept tiny on purpose —
    /// the goal is a recognisable silhouette, not medical accuracy.
    private struct Proportions {
        var shoulderWidth: Float
        var hipWidth: Float
        var limbRadius: Float
        var torsoWidth: Float

        static let male = Proportions(shoulderWidth: 0.44, hipWidth: 0.13, limbRadius: 0.105, torsoWidth: 0.36)
        static let female = Proportions(shoulderWidth: 0.36, hipWidth: 0.16, limbRadius: 0.092, torsoWidth: 0.30)
    }

    func makeBodyNode(gender: AnatomyGender) -> SCNNode {
        let p = gender == .female ? Proportions.female : Proportions.male
        let root = SCNNode()
        root.name = "anatomyRoot"

        addTorso(to: root, p: p)
        addArms(to: root, p: p)
        addLegs(to: root, p: p)

        // Centre the body roughly on the origin so it rotates about its middle.
        root.position = SCNVector3(0, -0.28, 0)

        // Give every node a sensible default material up-front; the scene
        // controller overrides muscle materials from live scores.
        root.enumerateHierarchy { node, _ in
            if node.geometry != nil {
                node.geometry?.firstMaterial = MuscleMaterialMapper.baseMaterial()
            }
        }
        return root
    }

    // MARK: - Torso / head

    private func addTorso(to root: SCNNode, p: Proportions) {
        // Head + neck (neutral)
        root.addChildNode(node(anatomyBaseNodeName, sphere(0.20), at: SCNVector3(0, 1.42, 0)))
        root.addChildNode(node(anatomyBaseNodeName, capsule(0.08, 0.18), at: SCNVector3(0, 1.22, 0)))

        // Torso core volume (neutral, fills the body behind the muscles)
        root.addChildNode(node(anatomyBaseNodeName,
                               box(p.torsoWidth, 0.62, p.torsoWidth * 0.62),
                               at: SCNVector3(0, 0.62, 0)))
        // Pelvis (neutral)
        root.addChildNode(node(anatomyBaseNodeName,
                               box(p.torsoWidth * 0.85, 0.20, p.torsoWidth * 0.6),
                               at: SCNVector3(0, 0.22, 0)))

        // Shoulders / deltoids
        root.addChildNode(node(MuscleRegion.shoulders.rawValue, sphere(0.135),
                               at: SCNVector3(-p.shoulderWidth, 1.02, 0)))
        root.addChildNode(node(MuscleRegion.shoulders.rawValue, sphere(0.135),
                               at: SCNVector3(p.shoulderWidth, 1.02, 0)))

        // Chest (two pecs, front)
        root.addChildNode(node(MuscleRegion.chest.rawValue, box(0.17, 0.22, 0.12),
                               at: SCNVector3(-0.10, 0.88, p.torsoWidth * 0.42)))
        root.addChildNode(node(MuscleRegion.chest.rawValue, box(0.17, 0.22, 0.12),
                               at: SCNVector3(0.10, 0.88, p.torsoWidth * 0.42)))

        // Back (lats slab + traps, behind)
        root.addChildNode(node(MuscleRegion.back.rawValue, box(p.torsoWidth, 0.34, 0.12),
                               at: SCNVector3(0, 0.82, -p.torsoWidth * 0.42)))
        root.addChildNode(node(MuscleRegion.back.rawValue, box(0.26, 0.12, 0.10),
                               at: SCNVector3(0, 1.04, -p.torsoWidth * 0.28)))

        // Abs (front)
        root.addChildNode(node(MuscleRegion.abs.rawValue, box(0.20, 0.34, 0.10),
                               at: SCNVector3(0, 0.50, p.torsoWidth * 0.42)))
        // Obliques (front sides)
        root.addChildNode(node(MuscleRegion.obliques.rawValue, box(0.07, 0.30, 0.11),
                               at: SCNVector3(-0.16, 0.50, p.torsoWidth * 0.30)))
        root.addChildNode(node(MuscleRegion.obliques.rawValue, box(0.07, 0.30, 0.11),
                               at: SCNVector3(0.16, 0.50, p.torsoWidth * 0.30)))

        // Glutes (behind, lower)
        root.addChildNode(node(MuscleRegion.glutes.rawValue, sphere(0.14),
                               at: SCNVector3(-0.11, 0.14, -p.torsoWidth * 0.38)))
        root.addChildNode(node(MuscleRegion.glutes.rawValue, sphere(0.14),
                               at: SCNVector3(0.11, 0.14, -p.torsoWidth * 0.38)))
    }

    // MARK: - Arms

    private func addArms(to root: SCNNode, p: Proportions) {
        for side: Float in [-1, 1] {
            let armX = p.shoulderWidth + 0.02
            // Biceps (front) + triceps (back) of the upper arm
            root.addChildNode(node(MuscleRegion.biceps.rawValue, capsule(0.075, 0.34),
                                   at: SCNVector3(side * armX, 0.74, 0.06)))
            root.addChildNode(node(MuscleRegion.triceps.rawValue, capsule(0.075, 0.34),
                                   at: SCNVector3(side * armX, 0.74, -0.06)))
            // Elbow joint (neutral)
            root.addChildNode(node(anatomyBaseNodeName, sphere(0.07),
                                   at: SCNVector3(side * armX, 0.56, 0)))
            // Forearm
            root.addChildNode(node(MuscleRegion.forearms.rawValue, capsule(0.066, 0.32),
                                   at: SCNVector3(side * (armX + 0.01), 0.36, 0.02)))
            // Hand (neutral)
            root.addChildNode(node(anatomyBaseNodeName, sphere(0.07),
                                   at: SCNVector3(side * (armX + 0.02), 0.17, 0.03)))
        }
    }

    // MARK: - Legs

    private func addLegs(to root: SCNNode, p: Proportions) {
        for side: Float in [-1, 1] {
            let hipX = p.hipWidth
            // Quads (front) + hamstrings (back) of the thigh
            root.addChildNode(node(MuscleRegion.quads.rawValue, capsule(0.10, 0.50),
                                   at: SCNVector3(side * hipX, -0.20, 0.05)))
            root.addChildNode(node(MuscleRegion.hamstrings.rawValue, capsule(0.10, 0.50),
                                   at: SCNVector3(side * hipX, -0.20, -0.06)))
            // Knee (neutral)
            root.addChildNode(node(anatomyBaseNodeName, sphere(0.09),
                                   at: SCNVector3(side * hipX, -0.48, 0)))
            // Calves
            root.addChildNode(node(MuscleRegion.calves.rawValue, capsule(0.085, 0.42),
                                   at: SCNVector3(side * hipX, -0.74, -0.02)))
            // Foot (neutral)
            root.addChildNode(node(anatomyBaseNodeName, box(0.12, 0.07, 0.24),
                                   at: SCNVector3(side * hipX, -1.00, 0.06)))
        }
    }

    // MARK: - Geometry helpers (low-poly for mobile)

    private func node(_ name: String, _ geometry: SCNGeometry, at position: SCNVector3) -> SCNNode {
        let n = SCNNode(geometry: geometry)
        n.name = name
        n.position = position
        return n
    }

    private func capsule(_ radius: CGFloat, _ height: CGFloat) -> SCNCapsule {
        let c = SCNCapsule(capRadius: radius, height: height)
        c.radialSegmentCount = 14
        c.heightSegmentCount = 1
        c.capSegmentCount = 8
        return c
    }

    private func sphere(_ radius: CGFloat) -> SCNSphere {
        let s = SCNSphere(radius: radius)
        s.segmentCount = 14
        return s
    }

    private func box(_ w: CGFloat, _ h: CGFloat, _ l: CGFloat) -> SCNBox {
        SCNBox(width: w, height: h, length: l, chamferRadius: min(w, h, l) * 0.35)
    }
}
