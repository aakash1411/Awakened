import Foundation
import CoreLocation
import MapKit
import SwiftUI

/// Processes raw CLLocation data into route polylines, colored segments, and splits
struct RouteDataProvider {
    
    // MARK: - Route Polyline
    
    /// Create an MKPolyline from route locations
    /// - Parameter locations: GPS locations along the route
    /// - Returns: MKPolyline for map overlay
    static func polyline(from locations: [CLLocation]) -> MKPolyline {
        let coordinates = locations.map { $0.coordinate }
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
    
    /// Compute the map region that fits all route locations with padding
    /// - Parameter locations: GPS locations along the route
    /// - Returns: MKCoordinateRegion encompassing the route
    static func region(for locations: [CLLocation]) -> MKCoordinateRegion {
        guard !locations.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        let lats = locations.map { $0.coordinate.latitude }
        let lons = locations.map { $0.coordinate.longitude }
        
        let minLat = lats.min()!
        let maxLat = lats.max()!
        let minLon = lons.min()!
        let maxLon = lons.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3 + 0.002,
            longitudeDelta: (maxLon - minLon) * 1.3 + 0.002
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    // MARK: - Colored Segments
    
    /// Segment of a route with an associated color (for pace or HR visualization)
    struct ColoredSegment: Identifiable {
        let id = UUID()
        let polyline: MKPolyline
        let color: Color
        let pace: Double? // seconds per km
        let heartRate: Double?
    }
    
    /// Create pace-colored route segments
    /// - Parameter locations: GPS locations along the route
    /// - Returns: Array of colored segments based on pace
    static func paceColoredSegments(from locations: [CLLocation]) -> [ColoredSegment] {
        guard locations.count >= 2 else { return [] }
        
        var segments: [ColoredSegment] = []
        let chunkSize = max(2, locations.count / 20) // ~20 segments
        
        for i in stride(from: 0, to: locations.count - 1, by: chunkSize) {
            let end = min(i + chunkSize, locations.count - 1)
            let segmentLocations = Array(locations[i...end])
            
            guard segmentLocations.count >= 2 else { continue }
            
            let distance = segmentLocations.first!.distance(from: segmentLocations.last!)
            let time = segmentLocations.last!.timestamp.timeIntervalSince(segmentLocations.first!.timestamp)
            
            let pacePerKm = distance > 0 ? (time / (distance / 1000.0)) : 0
            let color = paceColor(secondsPerKm: pacePerKm)
            
            let coords = segmentLocations.map { $0.coordinate }
            let polyline = MKPolyline(coordinates: coords, count: coords.count)
            
            segments.append(ColoredSegment(
                polyline: polyline,
                color: color,
                pace: pacePerKm,
                heartRate: nil
            ))
        }
        
        return segments
    }
    
    /// Create HR-colored route segments
    /// - Parameters:
    ///   - locations: GPS locations along the route
    ///   - hrSamples: Heart rate samples during the activity
    /// - Returns: Array of colored segments based on HR zone
    static func hrColoredSegments(
        from locations: [CLLocation],
        hrSamples: [HeartRateSample]
    ) -> [ColoredSegment] {
        guard locations.count >= 2, !hrSamples.isEmpty else {
            return paceColoredSegments(from: locations)
        }
        
        var segments: [ColoredSegment] = []
        let sortedSamples = hrSamples.sorted { $0.date < $1.date }
        let chunkSize = max(2, locations.count / 20)
        
        for i in stride(from: 0, to: locations.count - 1, by: chunkSize) {
            let end = min(i + chunkSize, locations.count - 1)
            let segmentLocations = Array(locations[i...end])
            
            guard segmentLocations.count >= 2 else { continue }
            
            let segStart = segmentLocations.first!.timestamp
            let segEnd = segmentLocations.last!.timestamp
            
            // Find HR samples in this time range
            let matchingSamples = sortedSamples.filter { $0.date >= segStart && $0.date <= segEnd }
            let avgHR = matchingSamples.isEmpty ? nil : matchingSamples.reduce(0.0) { $0 + $1.bpm } / Double(matchingSamples.count)
            
            let zone = avgHR.map { HeartRateZone.from(bpm: $0) }
            let color = zone?.color ?? AppColors.primaryBlue
            
            let coords = segmentLocations.map { $0.coordinate }
            let polyline = MKPolyline(coordinates: coords, count: coords.count)
            
            segments.append(ColoredSegment(
                polyline: polyline,
                color: color,
                pace: nil,
                heartRate: avgHR
            ))
        }
        
        return segments
    }
    
    // MARK: - Splits
    
    /// Calculate per-kilometer splits from route locations
    /// - Parameters:
    ///   - locations: GPS locations along the route
    ///   - hrSamples: Optional HR samples for per-split HR
    /// - Returns: Array of SplitData for each kilometer
    static func calculateSplits(
        from locations: [CLLocation],
        hrSamples: [HeartRateSample]? = nil
    ) -> [SplitData] {
        guard locations.count >= 2 else { return [] }
        
        var splits: [SplitData] = []
        var splitNumber = 1
        var splitStartIndex = 0
        var accumulatedDistance = 0.0
        let sortedSamples = hrSamples?.sorted { $0.date < $1.date }
        
        for i in 1..<locations.count {
            let segmentDistance = locations[i].distance(from: locations[i - 1])
            accumulatedDistance += segmentDistance
            
            // Check if we've completed a kilometer
            if accumulatedDistance >= 1000.0 {
                let splitLocations = Array(locations[splitStartIndex...i])
                let split = buildSplit(
                    number: splitNumber,
                    locations: splitLocations,
                    distance: accumulatedDistance,
                    hrSamples: sortedSamples
                )
                splits.append(split)
                
                splitNumber += 1
                splitStartIndex = i
                accumulatedDistance = 0
            }
        }
        
        // Add final partial split if significant (> 200m)
        if accumulatedDistance > 200, splitStartIndex < locations.count - 1 {
            let splitLocations = Array(locations[splitStartIndex...])
            let split = buildSplit(
                number: splitNumber,
                locations: splitLocations,
                distance: accumulatedDistance,
                hrSamples: sortedSamples
            )
            splits.append(split)
        }
        
        return splits
    }
    
    // MARK: - Private Helpers
    
    /// Map pace (seconds per km) to a color
    private static func paceColor(secondsPerKm: Double) -> Color {
        // Fast (< 4:30/km) = green, Medium (4:30-6:00) = yellow/orange, Slow (> 6:00) = red
        switch secondsPerKm {
        case ..<270: return Color(hex: "69F0AE")  // Very fast - green
        case 270..<330: return Color(hex: "B2FF59") // Fast - light green
        case 330..<390: return Color(hex: "FFD54F") // Medium - yellow
        case 390..<450: return Color(hex: "FFB74D") // Moderate - orange
        case 450..<540: return Color(hex: "FF8A65") // Slow - deep orange
        default: return Color(hex: "EF5350")        // Very slow - red
        }
    }
    
    /// Build a SplitData from a range of locations
    private static func buildSplit(
        number: Int,
        locations: [CLLocation],
        distance: Double,
        hrSamples: [HeartRateSample]?
    ) -> SplitData {
        guard let first = locations.first, let last = locations.last else {
            return SplitData(
                number: number, distanceMeters: distance, duration: 0,
                averageHeartRate: nil, elevationGain: 0, elevationLoss: 0
            )
        }
        
        let duration = last.timestamp.timeIntervalSince(first.timestamp)
        
        // Calculate elevation
        var elevationGain = 0.0
        var elevationLoss = 0.0
        for i in 1..<locations.count {
            let diff = locations[i].altitude - locations[i - 1].altitude
            if diff > 0 { elevationGain += diff }
            else { elevationLoss += abs(diff) }
        }
        
        // Find matching HR samples
        var avgHR: Double?
        if let samples = hrSamples {
            let matching = samples.filter { $0.date >= first.timestamp && $0.date <= last.timestamp }
            if !matching.isEmpty {
                avgHR = matching.reduce(0.0) { $0 + $1.bpm } / Double(matching.count)
            }
        }
        
        return SplitData(
            number: number,
            distanceMeters: distance,
            duration: duration,
            averageHeartRate: avgHR,
            elevationGain: elevationGain,
            elevationLoss: elevationLoss
        )
    }
}
