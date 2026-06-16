import AppKit
import CoreText
import SwiftUI

// MARK: - Brand colors (fixed in both themes)

enum ClaudeRTLColors {
    static let coral = Color(red: 217 / 255, green: 119 / 255, blue: 78 / 255)
    static let coralDark = Color(red: 193 / 255, green: 95 / 255, blue: 60 / 255)
}

// MARK: - Layout tokens

enum SettingsMetrics {
    static let windowWidth: CGFloat = 720
    static let windowHeight: CGFloat = 520
    static let windowMinWidth: CGFloat = 680
    static let windowMinHeight: CGFloat = 480
    static let sidebarWidth: CGFloat = 210
    static let contentPadding: CGFloat = 28
    static let sectionSpacing: CGFloat = 20
    static let rowHeight: CGFloat = 44
    static let cardRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let navButtonHeight: CGFloat = 36
    static let navButtonRadius: CGFloat = 8
    static let appIconSidebarRadius: CGFloat = 12
    static let appIconListSize: CGFloat = 22
    static let appIconListRadius: CGFloat = 6
    static let primaryButtonRadius: CGFloat = 10
}

// MARK: - Semantic colors

enum SettingsSemantic {
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .light
            ? Color(red: 243 / 255, green: 238 / 255, blue: 226 / 255)
            : Color(red: 23 / 255, green: 17 / 255, blue: 9 / 255)
    }

    static func cardBackground(_ scheme: ColorScheme) -> Color {
        scheme == .light ? .white : Color(red: 33 / 255, green: 30 / 255, blue: 28 / 255)
    }

    static func cardBorder(_ scheme: ColorScheme) -> Color {
        scheme == .light
            ? Color(red: 231 / 255, green: 227 / 255, blue: 216 / 255)
            : Color(red: 58 / 255, green: 53 / 255, blue: 49 / 255)
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .light
            ? Color(red: 23 / 255, green: 17 / 255, blue: 9 / 255)
            : Color(red: 243 / 255, green: 238 / 255, blue: 226 / 255)
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .light
            ? Color(red: 107 / 255, green: 103 / 255, blue: 95 / 255)
            : Color(red: 177 / 255, green: 173 / 255, blue: 161 / 255)
    }

    static func hoverFill(_ scheme: ColorScheme) -> Color {
        scheme == .light
            ? Color.black.opacity(0.04)
            : Color.white.opacity(0.06)
    }
}

// MARK: - IBM Plex Sans Arabic

enum SettingsFontRegistrar {
    static func register() {
        let names = [
            "IBMPlexSansArabic-Regular",
            "IBMPlexSansArabic-Medium",
            "IBMPlexSansArabic-SemiBold",
            "IBMPlexSansArabic-Bold",
        ]
        for name in names {
            guard let url = Bundle.main.url(
                forResource: name,
                withExtension: "woff2",
                subdirectory: "Resources/Fonts"
            ) else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Font {
    static func settingsTitle() -> Font {
        .custom("IBMPlexSansArabic-SemiBold", size: 20)
    }

    static func settingsSectionTitle() -> Font {
        .custom("IBMPlexSansArabic-SemiBold", size: 20)
    }

    static func settingsLabel() -> Font {
        .custom("IBMPlexSansArabic-Medium", size: 14)
    }

    static func settingsBody() -> Font {
        .custom("IBMPlexSansArabic-Regular", size: 14)
    }

    static func settingsCaption() -> Font {
        .custom("IBMPlexSansArabic-Regular", size: 12)
    }

    static func settingsSidebarBrand() -> Font {
        .custom("IBMPlexSansArabic-SemiBold", size: 16)
    }

    static func settingsArabic(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .medium: name = "IBMPlexSansArabic-Medium"
        case .semibold, .bold: name = "IBMPlexSansArabic-SemiBold"
        default: name = "IBMPlexSansArabic-Regular"
        }
        return .custom(name, size: size)
    }
}

// MARK: - Button styles

struct CoralPrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.settingsLabel())
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(configuration.isPressed ? ClaudeRTLColors.coralDark : ClaudeRTLColors.coral)
            .clipShape(RoundedRectangle(cornerRadius: SettingsMetrics.primaryButtonRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

struct CoralSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.settingsLabel())
            .foregroundStyle(SettingsSemantic.primaryText(colorScheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: SettingsMetrics.primaryButtonRadius, style: .continuous)
                    .strokeBorder(SettingsSemantic.cardBorder(colorScheme), lineWidth: 1)
            )
            .background(
                RoundedRectangle(cornerRadius: SettingsMetrics.primaryButtonRadius, style: .continuous)
                    .fill(configuration.isPressed ? SettingsSemantic.hoverFill(colorScheme) : .clear)
            )
    }
}

struct CoralQuietButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.settingsLabel())
            .foregroundStyle(SettingsSemantic.secondaryText(colorScheme))
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? SettingsSemantic.hoverFill(colorScheme) : .clear)
            )
    }
}

// MARK: - Shared components

struct SettingsCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            content
        }
        .padding(SettingsMetrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(SettingsSemantic.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: SettingsMetrics.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SettingsMetrics.cardRadius, style: .continuous)
                .strokeBorder(SettingsSemantic.cardBorder(colorScheme), lineWidth: 1)
        )
    }
}

struct SidebarVisualEffect: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct SettingsToggleRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Toggle(isOn: $isOn) {
                Text(title)
                    .font(.settingsLabel())
                    .foregroundStyle(SettingsSemantic.primaryText(colorScheme))
            }
            .toggleStyle(.switch)
            .tint(ClaudeRTLColors.coral)
        }
        .frame(minHeight: SettingsMetrics.rowHeight)
    }
}

struct ModeRadioRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? ClaudeRTLColors.coral : SettingsSemantic.cardBorder(colorScheme),
                            lineWidth: 2
                        )
                        .frame(width: 18, height: 18)
                    if isSelected {
                        Circle()
                            .fill(ClaudeRTLColors.coral)
                            .frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text(title)
                        .font(.settingsLabel())
                        .foregroundStyle(SettingsSemantic.primaryText(colorScheme))
                    Text(subtitle)
                        .font(.settingsCaption())
                        .foregroundStyle(SettingsSemantic.secondaryText(colorScheme))
                }

                Spacer(minLength: 0)
            }
            .frame(minHeight: SettingsMetrics.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ThemeChoiceButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.settingsLabel())
                .foregroundStyle(isSelected ? .white : SettingsSemantic.primaryText(colorScheme))
                .frame(maxWidth: .infinity)
                .frame(height: SettingsMetrics.navButtonHeight)
                .background(isSelected ? ClaudeRTLColors.coral : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: SettingsMetrics.navButtonRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: SettingsMetrics.navButtonRadius, style: .continuous)
                        .strokeBorder(
                            isSelected ? ClaudeRTLColors.coral : SettingsSemantic.cardBorder(colorScheme),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
