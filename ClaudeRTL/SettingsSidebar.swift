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
        VStack(alignment: .trailing, spacing: 0) {
            sidebarHeader
            VStack(spacing: SettingsMetrics.navGap) {
                ForEach([SettingsSection.whereItWorks, .appearance, .general], id: \.self) { section in
                    SidebarNavButton(
                        title: section.title,
                        icon: section.icon,
                        isSelected: selection == section
                    ) {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selection = section
                        }
                    }
                }
            }
            Spacer(minLength: 0)
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
        HStack(spacing: 10) {
            SettingsAppIcon.view(size: 38, radius: 10)
            VStack(alignment: .trailing, spacing: 2) {
                Text("Claude RTL")
                    .font(.settingsAppName())
                    .foregroundStyle(palette.textPrimary)
                Text("الإصدار \(Settings.versionLabel())")
                    .font(.settingsVersion())
                    .foregroundStyle(palette.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.bottom, SettingsMetrics.sidebarHeaderBottom)
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
                    .font(.system(size: 18, weight: .medium))
                Text(title)
                    .font(.settingsNav())
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .foregroundStyle(isSelected ? palette.coralTextSelected : palette.navUnselected)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
