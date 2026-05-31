import SwiftUI
import SceneKit
import UIKit

/// SwiftUI wrapper around the SceneKit anatomy view.
///
/// Hosts an `SCNView`, wires drag-to-rotate, pinch-to-zoom and tap-to-select,
/// and keeps muscle colours in sync with `scores` / `selectedRegion`.
struct AnatomySceneView: UIViewRepresentable {
    let controller: AnatomySceneController
    let scores: [MuscleRegion: MuscleScore]
    @Binding var selectedRegion: MuscleRegion?

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = controller.scene
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = .multisampling2X
        view.autoenablesDefaultLighting = false
        view.rendersContinuously = false

        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: context.coordinator,
                                             action: #selector(Coordinator.handlePinch(_:)))
        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(pan)
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(tap)

        context.coordinator.view = view
        controller.apply(scores: scores, selected: selectedRegion)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.parent = self
        controller.apply(scores: scores, selected: selectedRegion)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject {
        var parent: AnatomySceneView
        weak var view: SCNView?

        init(_ parent: AnatomySceneView) { self.parent = parent }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            let translation = gesture.translation(in: view)
            parent.controller.rotate(deltaX: Float(translation.x) * 0.01,
                                     deltaY: Float(translation.y) * 0.01)
            gesture.setTranslation(.zero, in: view)
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            parent.controller.zoom(by: Float(gesture.scale))
            gesture.scale = 1
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view else { return }
            let point = gesture.location(in: view)
            let region = parent.controller.region(at: point, in: view)
            // Tapping the same muscle (or empty space) toggles selection off.
            withAnimation(.easeInOut(duration: 0.2)) {
                parent.selectedRegion = (region == parent.selectedRegion) ? nil : region
            }
        }
    }
}
