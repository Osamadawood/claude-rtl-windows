import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: SettingsModel
    @Environment(\.palette) private var palette
    @State private var selection: SettingsSection = .whereItWorks

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(selection: $selection)
            contentArea
        }
        .background(palette.contentBg)
    }

    private var contentArea: some View {
        ScrollView {
            VStack(alignment: SettingsAlign.horizontal, spacing: 0) {
                Text(selection.title)
                    .font(.settingsSectionTitle())
                    .foregroundStyle(palette.textPrimary)
                    .settingsContentWidth()
                    .padding(.bottom, SettingsMetrics.sectionTitleBottom)

                Group {
                    switch selection {
                    case .whereItWorks:
                        SettingsWhereItWorksView()
                    case .appearance:
                        SettingsAppearanceView()
                    case .general:
                        SettingsGeneralView()
                    }
                }
                .settingsContentWidth()
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }
            .padding(.horizontal, SettingsMetrics.contentPaddingH)
            .padding(.vertical, SettingsMetrics.contentPaddingV)
            .settingsContentWidth()
            .animation(.easeInOut(duration: 0.2), value: selection)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.contentBg)
    }
}

struct SettingsRootView: View {
    @ObservedObject private var model = SettingsModel.shared

    var body: some View {
        SettingsView()
            .environmentObject(model)
            .environment(\.layoutDirection, .rightToLeft)
            .settingsPalette()
            .preferredColorScheme(model.preferredColorScheme)
    }
}
