import SceneKit

/// Body variant to render.
enum AnatomyGender: String {
    case male
    case female
}

/// Supplies the 3D body node for the workout anatomy scene.
///
/// The contract that every provider must honour:
/// - Returns a single root `SCNNode` containing the whole body.
/// - Every selectable muscle mesh is named with a `MuscleRegion.rawValue`.
///   A region may be split across several nodes (e.g. left/right biceps);
///   all of them share the same name.
/// - Non-muscle parts (head, hands, feet, joints) are named `"base"`.
///
/// This abstraction is the swap point for assets: the procedural provider is
/// the MVP, and `USDZAnatomyModelProvider` will later load a real model
/// using the exact same naming contract — so none of the workout data,
/// colouring, selection or camera logic has to change.
protocol AnatomyModelProvider {
    func makeBodyNode(gender: AnatomyGender) -> SCNNode
}

/// Name used for all non-selectable body parts.
let anatomyBaseNodeName = "base"

// MARK: - SCNNode lookup helpers

extension SCNNode {
    /// All mesh nodes belonging to a muscle region (self + descendants).
    func muscleNodes(for region: MuscleRegion) -> [SCNNode] {
        var result: [SCNNode] = []
        enumerateHierarchy { node, _ in
            if node.name == region.rawValue, node.geometry != nil {
                result.append(node)
            }
        }
        return result
    }

    /// All neutral (non-muscle) mesh nodes.
    func baseNodes() -> [SCNNode] {
        var result: [SCNNode] = []
        enumerateHierarchy { node, _ in
            if node.name == anatomyBaseNodeName, node.geometry != nil {
                result.append(node)
            }
        }
        return result
    }

    /// Walk up from a hit-tested node to find the owning muscle region.
    func muscleRegion() -> MuscleRegion? {
        var current: SCNNode? = self
        while let node = current {
            if let name = node.name, let region = MuscleRegion(rawValue: name) {
                return region
            }
            current = node.parent
        }
        return nil
    }
}
