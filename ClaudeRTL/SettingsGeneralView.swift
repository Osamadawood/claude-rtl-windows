import SwiftUI

struct SettingsGeneralView: View {
    @EnvironmentObject private var model: SettingsModel
    @Environment(\.palette) private var palette
    @State private var showResetConfirm = false

    var body: some View {
        VStack(alignment: SettingsAlign.horizontal, spacing: SettingsMetrics.cardSpacing) {
            SettingsCard {
                HStack {
                    Text("تشغيل عند بدء النظام")
                        .font(.settingsRowLabel())
                        .foregroundStyle(palette.textPrimary)
                    Spacer(minLength: 0)
                    CoralSwitch(isOn: $model.launchAtLogin)
                }
            }

            SettingsCard {
                SettingsActionRow(title: "إعادة عرض الشرح") {
                    model.showOnboarding()
                }
                Rectangle()
                    .fill(palette.rowDivider)
                    .frame(height: 1)
                SettingsActionRow(
                    title: "إعادة تعيين كل الإعدادات",
                    titleColor: palette.destructiveText
                ) {
                    showResetConfirm = true
                }
            }

            SettingsCard {
                aboutSection
            }
        }
        .confirmationDialog(
            "إعادة تعيين كل الإعدادات؟",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("إعادة تعيين", role: .destructive) {
                model.resetAllSettings()
            }
            Button("إلغاء", role: .cancel) {}
        } message: {
            Text("سيتم إرجاع الوضع إلى «كل التطبيقات»، وتفريغ القوائم، وحجم الخط 16، والمظهر تلقائي.\nلن يتغيّر «تشغيل عند بدء النظام».")
        }
    }

    private var aboutSection: some View {
        VStack(alignment: SettingsAlign.horizontal, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                SettingsAppIcon.view(size: 34, radius: 9)
                Text("Claude RTL — الإصدار \(Settings.versionLabel())")
                    .font(.settingsAboutTitle())
                    .foregroundStyle(palette.textPrimary)
            }
            SettingsDisclaimerText()
        }
        .settingsContentWidth()
    }
}
