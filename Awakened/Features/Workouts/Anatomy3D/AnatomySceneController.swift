import SceneKit
import UIKit

/// Owns the SceneKit scene for the workout anatomy: builds the body via an
/// `AnatomyModelProvider`, applies per-muscle colours from `MuscleScore`s,
/// and exposes rotate / zoom / hit-test for the SwiftUI wrapper.
///
/// Conforms to `ObservableObject` only so SwiftUI can hold a single instance
/// across redraws (`@StateObject`); it publishes nothing itself.
final class AnatomySceneController: ObservableObject {

    let scene = SCNScene()

    private let cameraNode = SCNNode()
    /// Container we rotate so the camera and lights stay put.
    private let bodyPivot = SCNNode()
    private var bodyNode: SCNNode?

    private let provider: AnatomyModelProvider
    private(set) var gender: AnatomyGender

    private var cameraDistance: Float = 6.0
    private let minDistance: Float = 3.5
    private let maxDistance: Float = 9.0
    private let maxPitch: Float = 0.6

    init(provider: AnatomyModelProvider = ProceduralAnatomyModelProvider(),
         gender: AnatomyGender = .male) {
        self.provider = provider
        self.gender = gender
        setupScene()
        setBody(gender: gender)
    }

    // MARK: - Scene setup

    private func setupScene() {
        scene.background.contents = UIColor.clear

        let camera = SCNCamera()
        camera.fieldOfView = 38
        camera.zNear = 0.1
        camera.zFar = 100
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, cameraDistance)
        scene.rootNode.addChildNode(cameraNode)

        // Soft ambient fill.
        let ambient = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 350
        ambientLight.color = UIColor.white
        ambient.light = ambientLight
        scene.rootNode.addChildNode(ambient)

        // Key light from above-front.
        let key = SCNNode()
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 700
        key.light = keyLight
        key.eulerAngles = SCNVector3(-Float.pi / 5, Float.pi / 6, 0)
        scene.rootNode.addChildNode(key)

        // Purple + cyan rim lights for the gamified look.
        let rimPurple = SCNNode()
        let rimPurpleLight = SCNLight()
        rimPurpleLight.type = .omni
        rimPurpleLight.intensity = 500
        rimPurpleLight.color = UIColor(red: 0.55, green: 0.36, blue: 0.96, alpha: 1)
        rimPurple.light = rimPurpleLight
        rimPurple.position = SCNVector3(-3, 1.5, 2)
        scene.rootNode.addChildNode(rimPurple)

        let rimCyan = SCNNode()
        let rimCyanLight = SCNLight()
        rimCyanLight.type = .omni
        rimCyanLight.intensity = 400
        rimCyanLight.color = UIColor(red: 0.13, green: 0.83, blue: 0.93, alpha: 1)
        rimCyan.light = rimCyanLight
        rimCyan.position = SCNVector3(3, 0.5, 2)
        scene.rootNode.addChildNode(rimCyan)

        scene.rootNode.addChildNode(bodyPivot)
    }

    // MARK: - Body

    func setBody(gender: AnatomyGender) {
        self.gender = gender
        bodyNode?.removeFromParentNode()
        let node = provider.makeBodyNode(gender: gender)
        bodyPivot.addChildNode(node)
        bodyNode = node
    }

    /// Colour every muscle from its score; dim the rest when one is selected.
    func apply(scores: [MuscleRegion: MuscleScore], selected: MuscleRegion?) {
        guard let bodyNode else { return }
        for region in MuscleRegion.allCases {
            let score = scores[region] ?? .empty(region)
            let isSelected = (selected == region)
            let dimmed = (selected != nil && !isSelected)
            let material = MuscleMaterialMapper.material(for: score, isSelected: isSelected, dimmed: dimmed)
            for node in bodyNode.muscleNodes(for: region) {
                node.geometry?.firstMaterial = material
            }
        }
    }

    // MARK: - Interaction

    /// Drag-to-rotate. `deltaX` yaws around the vertical axis; `deltaY`
    /// pitches within a clamped range so the body never flips over.
    func rotate(deltaX: Float, deltaY: Float) {
        bodyPivot.eulerAngles.y += deltaX
        let pitch = bodyPivot.eulerAngles.x + deltaY
        bodyPivot.eulerAngles.x = max(-maxPitch, min(maxPitch, pitch))
    }

    /// Pinch-to-zoom; `scale` is the gesture's incremental scale (>1 zooms in).
    func zoom(by scale: Float) {
        guard scale > 0 else { return }
        cameraDistance = max(minDistance, min(maxDistance, cameraDistance / scale))
        cameraNode.position = SCNVector3(0, 0, cameraDistance)
    }

    func resetOrientation() {
        bodyPivot.eulerAngles = SCNVector3(0, 0, 0)
    }

    /// Hit-test a screen point and resolve the owning muscle region.
    func region(at point: CGPoint, in view: SCNView) -> MuscleRegion? {
        let hits = view.hitTest(point, options: [SCNHitTestOption.firstFoundOnly: true])
        return hits.first?.node.muscleRegion()
    }
}
