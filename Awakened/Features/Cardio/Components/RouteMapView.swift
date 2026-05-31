import SwiftUI
import MapKit
import CoreLocation

/// MapKit view displaying a workout route with pace/HR color-coded polyline overlay
struct RouteMapView: UIViewRepresentable {
    let locations: [CLLocation]
    let coloredSegments: [RouteDataProvider.ColoredSegment]
    
    /// Start annotation coordinate
    var startCoordinate: CLLocationCoordinate2D? {
        locations.first?.coordinate
    }
    
    /// End annotation coordinate
    var endCoordinate: CLLocationCoordinate2D? {
        locations.last?.coordinate
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.mapType = .standard
        mapView.overrideUserInterfaceStyle = .dark
        mapView.pointOfInterestFilter = .excludingAll
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        guard !locations.isEmpty else { return }
        
        // Add colored segments
        if !coloredSegments.isEmpty {
            for segment in coloredSegments {
                mapView.addOverlay(segment.polyline)
            }
            context.coordinator.segments = coloredSegments
        } else {
            // Fallback: single polyline
            let polyline = RouteDataProvider.polyline(from: locations)
            mapView.addOverlay(polyline)
            context.coordinator.segments = []
        }
        
        // Add start/end annotations
        if let start = startCoordinate {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = start
            startAnnotation.title = "Start"
            mapView.addAnnotation(startAnnotation)
        }
        
        if let end = endCoordinate, locations.count > 1 {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = end
            endAnnotation.title = "Finish"
            mapView.addAnnotation(endAnnotation)
        }
        
        // Fit map to route
        let region = RouteDataProvider.region(for: locations)
        mapView.setRegion(region, animated: false)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var segments: [RouteDataProvider.ColoredSegment] = []
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 4
            
            // Find matching segment color
            if let segment = segments.first(where: { $0.polyline === polyline }) {
                renderer.strokeColor = UIColor(segment.color)
            } else {
                renderer.strokeColor = UIColor(AppColors.vitalityColor)
            }
            
            return renderer
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let pointAnnotation = annotation as? MKPointAnnotation else { return nil }
            
            let identifier = pointAnnotation.title ?? "pin"
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            if pointAnnotation.title == "Start" {
                view.markerTintColor = .systemGreen
                view.glyphImage = UIImage(systemName: "flag.fill")
            } else {
                view.markerTintColor = .systemRed
                view.glyphImage = UIImage(systemName: "flag.checkered")
            }
            
            return view
        }
    }
}

/// Placeholder shown when no route data is available
struct NoRouteAvailable: View {
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "map")
                .font(.system(size: 30))
                .foregroundColor(AppColors.textTertiary)
            Text("No route available")
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}
