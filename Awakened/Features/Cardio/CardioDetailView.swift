import SwiftUI
import HealthKit
import MapKit

/// Full detail view for a single cardio activity with route map, HR zones, and splits
struct CardioDetailView: View {
    let activity: CardioActivity
    
    @StateObject private var cardioService = CardioService()
    @State private var detailedActivity: CardioActivity?
    @State private var coloredSegments: [RouteDataProvider.ColoredSegment] = []
    @State private var splits: [SplitData] = []
    @State private var isLoadingDetail = true
    @State private var colorMode: RouteColorMode = .pace
    
    private var displayActivity: CardioActivity {
        detailedActivity ?? activity
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Route map
                    routeMapSection
                    
                    // Key stats
                    keyStatsGrid
                    
                    // Heart rate zones
                    if let zones = displayActivity.zoneDistribution, !zones.isEmpty {
                        HeartRateZoneChart(zoneDistribution: zones)
                    }
                    
                    // Pace splits
                    if !splits.isEmpty {
                        PaceSplitsTable(splits: splits)
                    }
                    
                    // XP breakdown
                    xpBreakdown
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.sm)
            }
        }
        .navigationTitle(activity.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDetailedData()
        }
    }
    
    // MARK: - Route Map
    
    private var routeMapSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(activity.dateFormatted)
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textSecondary)
                Text("\u{2022}")
                    .foregroundColor(AppColors.textTertiary)
                Text(activity.timeFormatted)
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                if displayActivity.routeLocations != nil && displayActivity.heartRateSamples != nil {
                    Picker("Color", selection: $colorMode) {
                        Text("Pace").tag(RouteColorMode.pace)
                        Text("HR").tag(RouteColorMode.heartRate)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                    .onChange(of: colorMode) { _, newMode in
                        updateSegments(mode: newMode)
                    }
                }
            }
            
            if let locations = displayActivity.routeLocations, !locations.isEmpty {
                RouteMapView(
                    locations: locations,
                    coloredSegments: coloredSegments
                )
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
            } else if isLoadingDetail {
                ProgressView()
                    .tint(AppColors.vitalityColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
            } else {
                NoRouteAvailable()
            }
        }
    }
    
    // MARK: - Key Stats Grid
    
    private var keyStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppSpacing.sm) {
            StatBox(
                label: "Distance",
                value: displayActivity.distanceFormatted,
                icon: "location.fill",
                color: AppColors.vitalityColor
            )
            StatBox(
                label: "Duration",
                value: displayActivity.durationFormatted,
                icon: "clock.fill",
                color: AppColors.primaryBlue
            )
            StatBox(
                label: "Pace",
                value: displayActivity.paceFormatted,
                icon: "speedometer",
                color: AppColors.agilityColor
            )
            StatBox(
                label: "Calories",
                value: displayActivity.caloriesFormatted,
                icon: "flame.fill",
                color: AppColors.strengthColor
            )
            StatBox(
                label: "Avg HR",
                value: displayActivity.averageHRFormatted,
                icon: "heart.fill",
                color: .red
            )
            StatBox(
                label: "Max HR",
                value: displayActivity.maxHeartRate != nil ? "\(Int(displayActivity.maxHeartRate!)) bpm" : "\u{2014}",
                icon: "heart.fill",
                color: Color(hex: "EF5350")
            )
        }
    }
    
    // MARK: - XP Breakdown
    
    private var xpBreakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("XP EARNED")
                .font(AppFonts.caption1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textSecondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(AppColors.vitalityColor)
                        Text("+\(displayActivity.xpEarned) XP")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.vitalityColor)
                    }
                    
                    Text("Vitality")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    let durationXP = Int(displayActivity.duration / 60.0 * 2.0)
                    Text("Duration: +\(durationXP)")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textSecondary)
                    
                    if let km = displayActivity.distanceKm {
                        Text("Distance: +\(Int(km * 10))")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    if displayActivity.zoneDistribution != nil {
                        Text("HR Zone Bonus Applied")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.vitalityColor)
                    }
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Data Loading
    
    private func loadDetailedData() async {
        isLoadingDetail = true
        defer { isLoadingDetail = false }
        
        // We need the original HKWorkout to fetch route and HR samples
        // Re-fetch from HealthKit using the date range
        let hkManager = HealthKitManager.shared
        guard let workouts = try? await hkManager.fetchWorkouts(
            from: activity.date,
            to: activity.date.addingTimeInterval(activity.duration + 60)
        ) else { return }
        
        guard let workout = workouts.first(where: { $0.uuid == activity.id }) else { return }
        
        if let detailed = try? await cardioService.fetchDetailedActivity(workout: workout) {
            detailedActivity = detailed
            
            if let locations = detailed.routeLocations, !locations.isEmpty {
                coloredSegments = RouteDataProvider.paceColoredSegments(from: locations)
                splits = RouteDataProvider.calculateSplits(
                    from: locations,
                    hrSamples: detailed.heartRateSamples
                )
            }
        }
    }
    
    private func updateSegments(mode: RouteColorMode) {
        guard let locations = displayActivity.routeLocations, !locations.isEmpty else { return }
        
        switch mode {
        case .pace:
            coloredSegments = RouteDataProvider.paceColoredSegments(from: locations)
        case .heartRate:
            if let samples = displayActivity.heartRateSamples {
                coloredSegments = RouteDataProvider.hrColoredSegments(from: locations, hrSamples: samples)
            }
        }
    }
}

// MARK: - Route Color Mode

enum RouteColorMode: String, CaseIterable {
    case pace
    case heartRate
}

// MARK: - Stat Box

private struct StatBox: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            
            Text(value)
                .font(AppFonts.caption1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}
