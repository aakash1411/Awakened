import SwiftUI

/// Main hub for agility/flexibility activities
struct AgilityView: View {
    @StateObject private var service = AgilityService()
    @State private var dailyMinutes: [Double] = Array(repeating: 0, count: 7)
    @State private var showLogSession = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Weekly Stats Card
                    weeklyStatsCard
                    
                    // Weekly Chart
                    weeklyChart
                    
                    // Quick Log Button
                    Button {
                        showLogSession = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Log Session")
                                .font(AppFonts.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.agilityColor)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                    
                    // Recent Sessions
                    recentSessionsSection
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("Sensation")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AgilityHistoryView()
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(AppColors.agilityColor)
                }
            }
        }
        .sheet(isPresented: $showLogSession) {
            LogFlexibilityView { session in
                // Refresh after logging
                Task {
                    await service.fetchWeeklyStats()
                    dailyMinutes = await service.fetchDailyBreakdown()
                }
            }
        }
        .task {
            await service.fetchRecentSessions()
            await service.fetchWeeklyStats()
            dailyMinutes = await service.fetchDailyBreakdown()
        }
    }
    
    // MARK: - Weekly Stats Card
    
    private var weeklyStatsCard: some View {
        HStack(spacing: AppSpacing.lg) {
            statBubble(
                value: String(format: "%.0f", service.weeklyMinutes),
                label: "Minutes",
                icon: "clock.fill"
            )
            
            statBubble(
                value: "\(service.weeklySessions)",
                label: "Sessions",
                icon: "flame.fill"
            )
            
            statBubble(
                value: String(format: "%.0f", service.weeklyMinutes > 0 ? service.weeklyMinutes / max(Double(service.weeklySessions), 1) : 0),
                label: "Avg Min",
                icon: "chart.bar.fill"
            )
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    private func statBubble(value: String, label: String, icon: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.agilityColor)
            
            Text(value)
                .font(AppFonts.title2)
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Weekly Chart
    
    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("This Week")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
                let maxMinutes = max(dailyMinutes.max() ?? 1, 1)
                
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(dailyMinutes[index] > 0 ? AppColors.agilityColor : AppColors.surface)
                            .frame(height: max(4, CGFloat(dailyMinutes[index] / maxMinutes) * 80))
                        
                        Text(dayLabels[index])
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Recent Sessions
    
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Recent Sessions")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                NavigationLink {
                    AgilityHistoryView()
                } label: {
                    Text("See All")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.agilityColor)
                }
            }
            
            if service.recentSessions.isEmpty && !service.isLoading {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "figure.yoga")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text("No sessions yet")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("Log a yoga, stretching, or calisthenics session to get started.")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
            } else {
                ForEach(service.recentSessions.prefix(5)) { session in
                    sessionRow(session)
                }
            }
            
            if service.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    private func sessionRow(_ session: FlexibilitySession) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: session.icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.agilityColor)
                .frame(width: 36, height: 36)
                .background(AppColors.agilityColor.opacity(0.15))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayName)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(session.dateFormatted)
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.durationFormatted)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("+\(session.xpEarned) XP")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.agilityColor)
            }
        }
        .padding(.vertical, 4)
    }
}
