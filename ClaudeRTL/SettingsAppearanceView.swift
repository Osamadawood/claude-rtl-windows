import SwiftUI

struct SettingsAppearanceView: View {
    @EnvironmentObject private var model: SettingsModel
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .trailing, spacing: SettingsMetrics.cardSpacing) {
            SettingsCard {
                SettingsCardLabel(text: "السمة")
                CoralSegmentedControl(selection: $model.themeMode)
            }

            SettingsCard {
                SettingsCardLabel(text: "حجم خط الفقاعة")
                CoralSliderRow(value: $model.fontSize, onReset: model.resetFontSize)
                SettingsPreviewBox {
                    Text("معاينة: السلام عليكم ورحمة الله")
                        .font(.settingsArabic(size: model.fontSize))
                        .foregroundStyle(palette.textPrimary)
                }
                .padding(.top, 12)
            }
        }
    }
}
