import SwiftUI
import SwiftData

/// Body measurements overview with trends
struct BodyTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]
    
    @State private var service: BodyTrackingService?
    @State private var showAddMeasurement = false
    @State private var selectedType: BodyMeasurementType = .weight
    
    private var player: Player? { players.first }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Latest measurements grid
                    latestMeasurementsCard
                    
                    // Weight trend
                    trendCard(type: .weight)
                    
                    // Body fat trend (if data exists)
                    if service?.latestByType[.bodyFat] != nil {
                        trendCard(type: .bodyFat)
                    }
                    
                    // Log button
                    Button {
                        showAddMeasurement = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Log Measurement")
                        }
                        .font(AppFonts.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.agilityColor)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("Body Tracking")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddMeasurement) {
            AddMeasurementView { refreshData() }
        }
        .onAppear {
            if service == nil {
                service = BodyTrackingService(modelContext: modelContext)
            }
            refreshData()
        }
    }
    
    private func refreshData() {
        service?.fetchRecentMeasurements()
    }
    
    // MARK: - Latest Measurements
    
    private var latestMeasurementsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Latest")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                ForEach(BodyMeasurementType.allCases) { type in
                    if let measurement = service?.latestByType[type] {
                        VStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.agilityColor)
                            Text(measurement.formattedValue)
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Text(type.displayName)
                                .font(AppFonts.caption2)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AppSpacing.sm)
                        .background(AppColors.surface.opacity(0.5))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Trend Card
    
    private func trendCard(type: BodyMeasurementType) -> some View {
        let data = service?.trendData(for: type) ?? []
        
        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("\(type.displayName) Trend")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                if let latest = data.last {
                    Text(type == .bodyFat ? String(format: "%.1f%%", latest.value) : String(format: "%.1f %@", latest.value, type.unit))
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.agilityColor)
                }
            }
            
            if data.count > 1 {
                // Simple line chart
                GeometryReader { geo in
                    let minVal = data.map(\.value).min() ?? 0
                    let maxVal = data.map(\.value).max() ?? 1
                    let range = max(maxVal - minVal, 0.1)
                    let width = geo.size.width
                    let height = geo.size.height
                    
                    Path { path in
                        for (i, point) in data.enumerated() {
                            let x = width * CGFloat(i) / CGFloat(max(data.count - 1, 1))
                            let y = height * (1 - CGFloat((point.value - minVal) / range))
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(AppColors.agilityColor, lineWidth: 2)
                }
                .frame(height: 80)
            } else {
                Text("Log more data to see trends")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}
