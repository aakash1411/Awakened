import SwiftUI
import HealthKit
import AuthenticationServices

/// Settings page for Apple Health connection
struct HealthSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var isConnecting = false
    @StateObject private var stravaService = StravaService()
    
    private var isAuthorized: Bool {
        HealthKitManager.shared.isAuthorized
    }
    
    private var isAvailable: Bool {
        HealthKitManager.shared.isAvailable
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Connection status
                        ConnectionStatusCard(
                            isAuthorized: isAuthorized,
                            isAvailable: isAvailable,
                            isConnecting: isConnecting,
                            onConnect: connectHealth
                        )
                        
                        // Sync info
                        if isAuthorized {
                            SyncInfoCard(syncEngine: appState.healthSyncEngine)
                            DataTypesCard()
                        }
                        
                        // Strava Integration
                        StravaConnectionCard(stravaService: stravaService)
                        
                        // Open settings
                        Button {
                            openHealthSettings()
                        } label: {
                            HStack {
                                Image(systemName: "gear")
                                    .foregroundColor(AppColors.primaryBlue)
                                
                                Text("Open Health Settings")
                                    .font(AppFonts.body)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(AppColors.textTertiary)
                            }
                            .padding(AppSpacing.cardPadding)
                            .background(AppColors.surface)
                            .cornerRadius(AppSpacing.cardCornerRadius)
                        }
                        
                        // Info text
                        Text("Apple Health data is stored on your device and synced securely via iCloud. Awakened never sends your health data to external servers.")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.lg)
                        
                        Spacer(minLength: AppSpacing.xxl)
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.md)
                }
            }
            .navigationTitle("Apple Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
        }
    }
    
    private func connectHealth() {
        isConnecting = true
        Task {
            do {
                let granted = try await HealthKitManager.shared.requestAuthorization()
                appState.isHealthAuthorized = granted
                if granted {
                    await appState.healthSyncEngine?.syncAll()
                }
            } catch {
                appState.showError("Health Connection Failed", message: error.localizedDescription)
            }
            isConnecting = false
        }
    }
    
    private func openHealthSettings() {
        if let url = URL(string: "x-apple-health://") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Connection Status Card

private struct ConnectionStatusCard: View {
    let isAuthorized: Bool
    let isAvailable: Bool
    let isConnecting: Bool
    let onConnect: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 36))
                    .foregroundColor(statusColor)
            }
            
            // Status text
            Text(statusTitle)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text(statusDescription)
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            // Connect/reconnect button
            if !isAuthorized && isAvailable {
                Button(action: onConnect) {
                    HStack {
                        if isConnecting {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "heart.fill")
                            Text("Connect")
                        }
                    }
                    .font(AppFonts.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.strengthColor)
                    .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                .disabled(isConnecting)
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    private var statusColor: Color {
        if !isAvailable { return AppColors.textTertiary }
        return isAuthorized ? AppColors.success : AppColors.warning
    }
    
    private var statusIcon: String {
        if !isAvailable { return "heart.slash.fill" }
        return isAuthorized ? "heart.circle.fill" : "heart.text.square"
    }
    
    private var statusTitle: String {
        if !isAvailable { return "Not Available" }
        return isAuthorized ? "Connected" : "Not Connected"
    }
    
    private var statusDescription: String {
        if !isAvailable { return "Apple Health is not available on this device." }
        if isAuthorized { return "Awakened is reading your health data to track progress." }
        return "Connect Apple Health to auto-track your activities."
    }
}

// MARK: - Sync Info Card

private struct SyncInfoCard: View {
    var syncEngine: HealthSyncEngine?
    
    var body: some View {
        if let engine = syncEngine {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Text("Sync Status")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        Task { await engine.syncAll() }
                    } label: {
                        HStack(spacing: AppSpacing.xxs) {
                            if engine.isSyncing {
                                ProgressView().tint(AppColors.primaryBlue).scaleEffect(0.7)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            Text("Sync Now")
                        }
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.primaryBlue)
                    }
                    .disabled(engine.isSyncing)
                }
                
                if let lastSync = engine.lastSyncDate {
                    HStack {
                        Text("Last synced")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Text(lastSync, style: .relative)
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textTertiary)
                        Text("ago")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                if let error = engine.syncError {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppColors.warning)
                            .font(.system(size: 12))
                        Text(error)
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.warning)
                    }
                }
            }
            .padding(AppSpacing.cardPadding)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
        }
    }
}

// MARK: - Data Types Card

private struct DataTypesCard: View {
    private let dataTypes = [
        ("figure.walk", "Steps & Distance", "Vitality XP"),
        ("flame.fill", "Workouts", "STR/AGI/VIT XP"),
        ("bed.double.fill", "Sleep Analysis", "Vitality XP"),
        ("brain.head.profile", "Mindful Minutes", "Sense XP"),
        ("heart.fill", "Heart Rate", "XP Bonus"),
        ("bolt.fill", "Active Energy", "Vitality XP"),
        ("scalemass.fill", "Body Measurements", "Display only")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Data Types")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 0) {
                ForEach(Array(dataTypes.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: item.0)
                            .foregroundColor(AppColors.primaryBlue)
                            .frame(width: 24)
                        
                        Text(item.1)
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Text(item.2)
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(.vertical, AppSpacing.sm)
                    
                    if index < dataTypes.count - 1 {
                        Divider().background(AppColors.textTertiary.opacity(0.3))
                    }
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

// MARK: - Strava Connection Card

private struct StravaConnectionCard: View {
    @ObservedObject var stravaService: StravaService
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "figure.outdoor.cycle")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "FC4C02")) // Strava brand orange
                
                Text("Strava")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if stravaService.isConnected {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(AppColors.success)
                            .frame(width: 8, height: 8)
                        Text("Connected")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.success)
                    }
                }
            }
            
            Text(stravaService.isConnected
                 ? "Your Strava activities are synced to Awakened."
                 : "Connect Strava to import runs, rides, and swims.")
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textSecondary)
            
            if let error = stravaService.authError {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppColors.warning)
                        .font(.system(size: 12))
                    Text(error)
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.warning)
                }
            }
            
            if stravaService.isConnected {
                Button(role: .destructive) {
                    stravaService.disconnect()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Disconnect Strava")
                    }
                    .font(AppFonts.caption1)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.error)
                    .padding(.vertical, 6)
                }
            } else {
                Button {
                    // TODO: Connect when API keys are configured
                    stravaService.authError = "Strava API keys not configured yet. Coming soon!"
                } label: {
                    HStack {
                        if stravaService.isAuthenticating {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        } else {
                            Image(systemName: "link")
                            Text("Connect Strava")
                        }
                    }
                    .font(AppFonts.caption1)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, 8)
                    .background(Color(hex: "FC4C02"))
                    .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                .disabled(stravaService.isAuthenticating)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

#Preview("Health Settings") {
    HealthSettingsView()
        .environmentObject(AppState())
}
