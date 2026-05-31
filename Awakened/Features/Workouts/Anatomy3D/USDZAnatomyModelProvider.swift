import SceneKit

/// Placeholder for the future photoreal body.
///
/// When a licensed/commissioned **segmented** model (`.usdz` / `.scn`) is
/// added to the app bundle, implement `makeBodyNode` here to load it. The
/// only hard requirement is that the model keeps the same node-naming
/// contract as `ProceduralAnatomyModelProvider`:
///
/// - one (or several) named nodes per `MuscleRegion.rawValue`
/// - everything else named `anatomyBaseNodeName`
///
/// If those names match, this can be swapped in by changing a single line in
/// `AnatomySceneController`'s initialiser — no workout data, colour, selection
/// or camera code needs to change.
///
/// Reference asset spec lives in `Docs/MUSCLE_MAP_PLAN.md`.
struct USDZAnatomyModelProvider: AnatomyModelProvider {

    /// File names (without extension) expected in the app bundle.
    let maleModelName: String
    let femaleModelName: String

    init(maleModelName: String = "MaleBody", femaleModelName: String = "FemaleBody") {
        self.maleModelName = maleModelName
        self.femaleModelName = femaleModelName
    }

    func makeBodyNode(gender: AnatomyGender) -> SCNNode {
        let name = gender == .female ? femaleModelName : maleModelName

        // TODO(USDZ): load and return the bundled segmented model, e.g.
        //   guard let scene = try? SCNScene(named: "\(name).usdz") else { ... }
        //   let root = scene.rootNode.clone()
        //   remapNodeNames(in: root)   // ensure names match MuscleRegion.rawValue
        //   return root
        //
        // Until the asset ships we deliberately fall back to the procedural
        // body so the feature is always functional.
        assertionFailure("USDZ model \"\(name)\" not bundled yet — falling back to procedural body.")
        return ProceduralAnatomyModelProvider().makeBodyNode(gender: gender)
    }
}
