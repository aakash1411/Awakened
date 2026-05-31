import SwiftUI
import SwiftData

/// Sheet for logging a body measurement
struct AddMeasurementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]
    
    var onComplete: (() -> Void)?
    
    @State private var selectedType: BodyMeasurementType = .weight
    @State private var valueText = ""
    
    private var player: Player? { players.first }
    
    private var isValid: Bool {
        (Double(valueText) ?? 0) > 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: AppSpacing.xl) {
                    // Type picker
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Measurement Type")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: AppSpacing.sm) {
                            ForEach(BodyMeasurementType.allCases) { type in
                                Button {
                                    selectedType = type
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 18))
                                        Text(type.displayName)
                                            .font(AppFonts.caption2)
                                    }
                                    .foregroundColor(selectedType == type ? .white : AppColors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(selectedType == type ? AppColors.agilityColor : AppColors.surface)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.cardPadding)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                    
                    // Value input
                    VStack(spacing: AppSpacing.md) {
                        Text("Value")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textPrimary)
                        
                        HStack(alignment: .firstTextBaseline) {
                            TextField("0", text: $valueText)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 150)
                            
                            Text(selectedType.unit)
                                .font(AppFonts.title3)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                    .padding(AppSpacing.cardPadding)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                    
                    Spacer()
                    
                    // Save
                    Button {
                        saveMeasurement()
                    } label: {
                        Text("Log Measurement")
                            .font(AppFonts.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(isValid ? AppColors.agilityColor : AppColors.textTertiary)
                            .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                    .disabled(!isValid)
                    .padding(.bottom, AppSpacing.lg)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
            .navigationTitle("Log Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
    
    private func saveMeasurement() {
        guard let player = player, let value = Double(valueText), value > 0 else { return }
        
        let service = BodyTrackingService(modelContext: modelContext)
        service.addMeasurement(type: selectedType, value: value, player: player)
        
        onComplete?()
        dismiss()
    }
}
