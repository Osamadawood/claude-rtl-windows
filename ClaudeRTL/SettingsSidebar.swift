import SwiftUI

enum SettingsSection: Hashable {
    case whereItWorks
    case appearance
    case general

    var title: String {
        switch self {
        case .whereItWorks: return "أين يعمل"
        case .appearance: return "المظهر"
        case .general: return "عام"
        }
    }

    var icon: String {
        switch self {
        case .whereItWorks: return "square.grid.2x2"
        case .appearance: return "paintpalette"
        case .general: return "gearshape"
        }
    }
}

struct SettingsSidebar: View {
    @Environment(\.palette) private var palette
    @Binding var selection: SettingsSection

    var body: some View {
        VStack(alignment: SettingsAlign.horizontal, spacing: 0) {
            sidebarHeader
            VStack(spacing: SettingsMetrics.navGap) {
                ForEach([SettingsSection.whereItWorks, .appearance, .general], id: \.self) { section in
                    SidebarNavButton(
                        title: section.title,
                        icon: section.icon,
                        isSelected: selection == section
                    ) {
                        selection = section
                    }
                }
            }
            Spacer(minLength: 0)
            sidebarFooter
        }
        .padding(.top, SettingsMetrics.sidebarTopPadding)
        .padding(.horizontal, SettingsMetrics.sidebarHorizontalPadding)
        .frame(width: SettingsMetrics.sidebarWidth)
        .background(palette.sidebarBg)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(palette.sidebarDivider)
                .frame(width: 1)
        }
    }

    private var sidebarHeader: some View {
        VStack(alignment: SettingsAlign.horizontal, spacing: 8) {
            SettingsAppIcon.view(size: 36, radius: 9)
            VStack(alignment: SettingsAlign.horizontal, spacing: 2) {
                Text("Claude RTL")
                    .font(.settingsAppName())
                    .foregroundStyle(palette.textPrimary)
                Text("الإصدار \(Settings.versionLabel())")
                    .font(.settingsVersion())
                    .foregroundStyle(palette.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: SettingsAlign.frame)
        .padding(.bottom, SettingsMetrics.sidebarHeaderBottom)
    }

    private var sidebarFooter: some View {
        let year = Calendar.current.component(.year, from: Date())
        return Text("© \(year) GRW Lab")
            .font(.settingsVersion())
            .foregroundStyle(palette.textMuted)
            .environment(\.layoutDirection, .leftToRight)
            .frame(maxWidth: .infinity, alignment: SettingsAlign.frame)
            .padding(.bottom, SettingsMetrics.sidebarFooterBottom)
    }
}

private struct SidebarNavButton: View {
    @Environment(\.palette) private var palette
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.settingsNav())
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .foregroundStyle(isSelected ? palette.coralTextSelected : palette.navUnselected)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(backgroundColor)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var backgroundColor: Color {
        if isSelected { return palette.navSelectedBg }
        if isHovered { return palette.navHoverBg }
        return .clear
    }
}
