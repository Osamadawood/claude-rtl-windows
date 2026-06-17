import SwiftUI

struct SettingsAppearanceView: View {
    @EnvironmentObject private var model: SettingsModel
    @Environment(\.palette) private var palette
    @State private var themeSelection: ThemeMode

    init() {
        _themeSelection = State(initialValue: SettingsModel.shared.themeMode)
    }

    var body: some View {
        VStack(alignment: SettingsAlign.horizontal, spacing: SettingsMetrics.cardSpacing) {
            SettingsCard {
                SettingsCardLabel(text: "السمة")
                CoralSegmentedControl(selection: Binding(
                    get: { themeSelection },
                    set: { newMode in
                        themeSelection = newMode
                        model.setThemeMode(newMode)
                    }
                ))
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
        .onChange(of: model.appearanceScheme) { _ in
            themeSelection = model.themeMode
        }
    }
}
