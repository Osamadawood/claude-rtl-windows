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
        case .appearance: return "paintbrush"
        case .general: return "gearshape"
        }
    }
}

struct SettingsSidebar: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selection: SettingsSection

    var body: some View {
        ZStack {
            SidebarVisualEffect()
            VStack(alignment: .trailing, spacing: 20) {
                sidebarHeader
                VStack(spacing: 6) {
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
            .padding(.horizontal, 14)
            .padding(.vertical, 20)
        }
        .frame(width: SettingsMetrics.sidebarWidth)
    }

    private var sidebarHeader: some View {
        HStack(spacing: 10) {
            appIcon
            VStack(alignment: .trailing, spacing: 2) {
                Text("Claude RTL")
                    .font(.settingsSidebarBrand())
                    .foregroundStyle(SettingsSemantic.primaryText(colorScheme))
                Text("v\(Settings.versionLabel())")
                    .font(.settingsCaption())
                    .foregroundStyle(SettingsSemantic.secondaryText(colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var appIcon: some View {
        if let image = NSApp.applicationIconImage ?? NSImage(named: "AppIcon") {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: SettingsMetrics.appIconSidebarRadius, style: .continuous))
        }
    }
}

private struct SidebarNavButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                Text(title)
                    .font(.settingsLabel())
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: SettingsMetrics.navButtonHeight)
            .foregroundStyle(isSelected ? Color.white : SettingsSemantic.primaryText(colorScheme))
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: SettingsMetrics.navButtonRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var backgroundColor: Color {
        if isSelected { return ClaudeRTLColors.coral }
        if isHovered { return SettingsSemantic.hoverFill(colorScheme) }
        return .clear
    }
}
