import AppKit
import CoreText
import SwiftUI

enum ClaudeRTLColors {
    static let coral = Color(red: 217 / 255, green: 119 / 255, blue: 78 / 255)
    static let coralPressed = Color(red: 193 / 255, green: 95 / 255, blue: 60 / 255)
}

struct SettingsPalette {
    let scheme: ColorScheme

    var contentBg: Color { scheme == .dark ? Color(hex: 0x1A1512) : Color(hex: 0xF3EEE2) }
    var sidebarBg: Color { scheme == .dark ? Color(hex: 0x15110E) : Color(hex: 0xEBE4D6) }
    var cardBg: Color { scheme == .dark ? Color(hex: 0x221C17) : .white }
    var cardBorder: Color {
        scheme == .dark ? Color(hex: 0xF3EEE2).opacity(0.07) : Color(hex: 0x171109).opacity(0.08)
    }
    var windowBorder: Color { Color.white.opacity(scheme == .dark ? 0.08 : 0.06) }
    var sidebarDivider: Color { Color.white.opacity(0.05) }
    var textPrimary: Color { scheme == .dark ? Color(hex: 0xF3EEE2) : Color(hex: 0x171109) }
    var textSecondary: Color {
        scheme == .dark ? Color(hex: 0xF3EEE2).opacity(0.50) : Color(hex: 0x171109).opacity(0.55)
    }
    var textMuted: Color {
        scheme == .dark ? Color(hex: 0xF3EEE2).opacity(0.45) : Color(hex: 0x171109).opacity(0.45)
    }
    var navUnselected: Color {
        scheme == .dark ? Color(hex: 0xF3EEE2).opacity(0.62) : Color(hex: 0x171109).opacity(0.62)
    }
    var coralTextSelected: Color { scheme == .dark ? Color(hex: 0xE88A60) : Color(hex: 0xC15F3C) }
    var navSelectedBg: Color {
        scheme == .dark ? Color(hex: 0x342118) : Color(hex: 0xE8D3C0)
    }
    var optionSelectedBg: Color { ClaudeRTLColors.coral.opacity(0.09) }
    var radioOffBorder: Color {
        scheme == .dark ? Color.white.opacity(0.22) : Color(hex: 0x171109).opacity(0.25)
    }
    var switchOffTrack: Color {
        scheme == .dark ? Color.white.opacity(0.12) : Color(hex: 0x171109).opacity(0.12)
    }
    var segmentTrackBg: Color { scheme == .dark ? Color(hex: 0x15110E) : Color(hex: 0xEBE4D6) }
    var destructiveText: Color { Color(hex: 0xE0856A) }
    var borderedButtonBorder: Color {
        scheme == .dark ? Color(hex: 0xF3EEE2).opacity(0.18) : Color(hex: 0x171109).opacity(0.18)
    }
    var rowDivider: Color {
        scheme == .dark ? Color(hex: 0xF3EEE2).opacity(0.07) : Color(hex: 0x171109).opacity(0.07)
    }
    var navHoverBg: Color { Color.white.opacity(0.05) }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

private struct SettingsPaletteKey: EnvironmentKey {
    static let defaultValue = SettingsPalette(scheme: .dark)
}

extension EnvironmentValues {
    var palette: SettingsPalette {
        get { self[SettingsPaletteKey.self] }
        set { self[SettingsPaletteKey.self] = newValue }
    }
}

extension View {
    func settingsPalette(scheme: ColorScheme) -> some View {
        environment(\.palette, SettingsPalette(scheme: scheme))
    }
}

enum SettingsMetrics {
    static let windowWidth: CGFloat = 640
    static let windowHeight: CGFloat = 540
    static let windowMinWidth: CGFloat = 620
    static let windowMinHeight: CGFloat = 500
    static let sidebarWidth: CGFloat = 190
    static let contentPaddingH: CGFloat = 26
    static let contentPaddingV: CGFloat = 24
    static let sectionTitleBottom: CGFloat = 16
    static let windowTitleBottom: CGFloat = 8
    static let cardRadius: CGFloat = 13
    static let cardPaddingH: CGFloat = 18
    static let cardPaddingV: CGFloat = 16
    static let cardSpacing: CGFloat = 13
    static let lblBottom: CGFloat = 12
    static let sidebarTopPadding: CGFloat = 30
    static let sidebarHorizontalPadding: CGFloat = 12
    static let sidebarHeaderBottom: CGFloat = 22
    static let sidebarFooterBottom: CGFloat = 14
    static let navGap: CGFloat = 3
    static let optionRowRadius: CGFloat = 9
    static let previewRadius: CGFloat = 9
    static let addButtonRadius: CGFloat = 9
}

/// Physical-right alignment under `.rightToLeft` layout (SwiftUI `.leading`).
enum SettingsAlign {
    static let horizontal: HorizontalAlignment = .leading
    static let frame: Alignment = .leading
}

enum SettingsCopy {
    static let independenceDisclaimer =
        "Claude RTL أداة مستقلة من GRW Lab، غير تابعة لشركة Anthropic ولا مُعتمَدة منها. ‹Claude› علامة تجارية مملوكة لشركة Anthropic."

    static var independenceDisclaimerRTL: String {
        let lri = "\u{2066}"
        let rli = "\u{2067}"
        let pdi = "\u{2069}"
        let rlm = "\u{200F}"
        return rlm + rli
            + lri + "Claude RTL" + pdi
            + " أداة مستقلة من "
            + lri + "GRW Lab" + pdi
            + "، غير تابعة لشركة "
            + lri + "Anthropic" + pdi
            + " ولا مُعتمَدة منها."
            + pdi
            + "\n"
            + rli
            + lri + "‹Claude›" + pdi
            + " علامة تجارية مملوكة لشركة "
            + lri + "Anthropic" + pdi
            + "."
            + pdi
    }
}

struct SettingsDisclaimerText: View {
    @Environment(\.palette) private var palette

    var body: some View {
        Text(SettingsCopy.independenceDisclaimerRTL)
            .font(.settingsRowDesc())
            .foregroundStyle(palette.textMuted)
            .multilineTextAlignment(.leading)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: SettingsAlign.frame)
    }
}

extension View {
    func settingsContentWidth() -> some View {
        frame(maxWidth: .infinity, alignment: SettingsAlign.frame)
    }
}

enum SettingsFontRegistrar {
    static func register() {
        for name in [
            "IBMPlexSansArabic-Regular", "IBMPlexSansArabic-Medium",
            "IBMPlexSansArabic-SemiBold", "IBMPlexSansArabic-Bold",
        ] {
            guard let url = Bundle.main.url(
                forResource: name, withExtension: "woff2", subdirectory: "Resources/Fonts"
            ) else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Font {
    static func settingsWindowTitle() -> Font { .custom("IBMPlexSansArabic-SemiBold", size: 12) }
    static func settingsSectionTitle() -> Font { .custom("IBMPlexSansArabic-SemiBold", size: 18) }
    static func settingsRowLabel() -> Font { .custom("IBMPlexSansArabic-Medium", size: 13) }
    static func settingsRowDesc() -> Font { .custom("IBMPlexSansArabic-Regular", size: 11) }
    static func settingsCardLabel() -> Font { .custom("IBMPlexSansArabic-Regular", size: 11) }
    static func settingsNav() -> Font { .custom("IBMPlexSansArabic-Medium", size: 12) }
    static func settingsAppName() -> Font { .custom("IBMPlexSansArabic-SemiBold", size: 13) }
    static func settingsVersion() -> Font { .custom("IBMPlexSansArabic-Regular", size: 10) }
    static func settingsEmpty() -> Font { .custom("IBMPlexSansArabic-Regular", size: 12) }
    static func settingsAboutTitle() -> Font { .custom("IBMPlexSansArabic-Medium", size: 12) }
    static func settingsArabic(size: CGFloat) -> Font { .custom("IBMPlexSansArabic-Regular", size: size) }
}

struct SettingsCard<Content: View>: View {
    @Environment(\.palette) private var palette
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: SettingsAlign.horizontal, spacing: 0) { content }
            .padding(.horizontal, SettingsMetrics.cardPaddingH)
            .padding(.vertical, SettingsMetrics.cardPaddingV)
            .settingsContentWidth()
            .background(palette.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: SettingsMetrics.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SettingsMetrics.cardRadius, style: .continuous)
                    .strokeBorder(palette.cardBorder, lineWidth: 1)
            )
    }
}

struct SettingsCardLabel: View {
    @Environment(\.palette) private var palette
    let text: String

    var body: some View {
        Text(text)
            .font(.settingsCardLabel())
            .foregroundStyle(palette.textSecondary)
            .frame(maxWidth: .infinity, alignment: SettingsAlign.frame)
            .padding(.bottom, SettingsMetrics.lblBottom)
    }
}

struct CoralSwitch: View {
    @Environment(\.palette) private var palette
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? ClaudeRTLColors.coral : palette.switchOffTrack)
                    .frame(width: 42, height: 25)
                Circle()
                    .fill(Color.white)
                    .frame(width: 19, height: 19)
                    .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
                    .padding(3)
            }
        }
        .buttonStyle(.plain)
        .environment(\.layoutDirection, .leftToRight)
    }
}

struct CoralRadio: View {
    @Environment(\.palette) private var palette
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? ClaudeRTLColors.coral : palette.radioOffBorder, lineWidth: 2)
                .frame(width: 19, height: 19)
            if isSelected {
                Circle().fill(ClaudeRTLColors.coral).frame(width: 9, height: 9)
            }
        }
    }
}

struct SettingsOptionRow: View {
    @Environment(\.palette) private var palette
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: SettingsAlign.horizontal, spacing: 3) {
                    Text(title).font(.settingsRowLabel()).foregroundStyle(palette.textPrimary)
                    Text(subtitle).font(.settingsRowDesc()).foregroundStyle(palette.textSecondary)
                }
                Spacer(minLength: 0)
                CoralRadio(isSelected: isSelected)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(isSelected ? palette.optionSelectedBg : (isHovered ? palette.navHoverBg : .clear))
            .clipShape(RoundedRectangle(cornerRadius: SettingsMetrics.optionRowRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: SettingsMetrics.optionRowRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct CoralSegmentedControl: View {
    @Environment(\.palette) private var palette
    @Binding var selection: ThemeMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ThemeMode.allCases, id: \.self) { mode in
                Button {
                    selection = mode
                } label: {
                    Text(mode.label)
                        .font(.settingsRowLabel())
                        .foregroundStyle(selection == mode ? Color.white : palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(selection == mode ? ClaudeRTLColors.coral : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(palette.segmentTrackBg)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct BorderedAddButton: View {
    @Environment(\.palette) private var palette
    let title: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus").font(.system(size: 12, weight: .medium))
                Text(title).font(.settingsRowLabel())
            }
            .foregroundStyle(palette.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isHovered ? palette.navHoverBg : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: SettingsMetrics.addButtonRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SettingsMetrics.addButtonRadius, style: .continuous)
                    .strokeBorder(palette.borderedButtonBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct SettingsActionRow: View {
    @Environment(\.palette) private var palette
    let title: String
    var titleColor: Color?
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.settingsRowLabel())
                    .foregroundStyle(titleColor ?? palette.textPrimary)
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(palette.textMuted)
            }
            .padding(.vertical, 10)
            .background(isHovered ? palette.navHoverBg : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

enum SettingsAppIcon {
    @ViewBuilder
    static func view(size: CGFloat, radius: CGFloat) -> some View {
        if let img = NSApp.applicationIconImage ?? NSImage(named: "AppIcon") {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            Color.clear.frame(width: size, height: size)
        }
    }
}

struct CoralSlider: View {
    @Environment(\.palette) private var palette
    @Binding var value: Double
    var range: ClosedRange<Double> = 12 ... 22
    var step: Double = 1

    private var progress: Double {
        guard range.upperBound > range.lowerBound else { return 0 }
        return (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    var body: some View {
        GeometryReader { geo in
            let thumbSize: CGFloat = 18
            let trackHeight: CGFloat = 4
            let width = geo.size.width
            let height = geo.size.height
            let travel = max(0, width - thumbSize)
            let thumbCenterX = (width - thumbSize / 2) - progress * travel
            let fillWidth = min(width, max(trackHeight, width - thumbCenterX + thumbSize / 2))

            ZStack {
                Capsule()
                    .fill(palette.switchOffTrack)
                    .frame(height: trackHeight)

                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Capsule()
                        .fill(ClaudeRTLColors.coral)
                        .frame(width: fillWidth, height: trackHeight)
                }

                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.18), radius: 1.5, y: 1)
                    .position(x: thumbCenterX, y: height / 2)
            }
            .frame(width: width, height: height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { updateValue(at: $0.location.x, width: width, thumbSize: thumbSize) }
            )
            .environment(\.layoutDirection, .leftToRight)
        }
        .frame(height: 28)
        .environment(\.layoutDirection, .leftToRight)
    }

    private func updateValue(at x: CGFloat, width: CGFloat, thumbSize: CGFloat) {
        let travel = max(0, width - thumbSize)
        guard travel > 0 else { return }
        let clampedX = min(max(x, thumbSize / 2), width - thumbSize / 2)
        let normalized = 1 - (clampedX - thumbSize / 2) / travel
        let raw = range.lowerBound + normalized * (range.upperBound - range.lowerBound)
        let stepped = (raw / step).rounded() * step
        value = min(max(stepped, range.lowerBound), range.upperBound)
    }
}

struct CoralSliderRow: View {
    @Environment(\.palette) private var palette
    @Binding var value: Double
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CoralSlider(value: $value)
            Text("\(Int(value))")
                .font(.settingsRowLabel())
                .foregroundStyle(ClaudeRTLColors.coral)
                .monospacedDigit()
                .frame(minWidth: 24)
            Button("إعادة تعيين", action: onReset)
                .font(.settingsRowDesc())
                .foregroundStyle(palette.textMuted)
                .buttonStyle(.plain)
        }
    }
}

struct SettingsCoralLink: View {
    let title: String
    let url: URL
    @State private var isHovered = false

    var body: some View {
        Button {
            NSWorkspace.shared.open(url)
        } label: {
            Text(title)
                .font(.settingsRowDesc())
                .foregroundStyle(isHovered ? ClaudeRTLColors.coralPressed : ClaudeRTLColors.coral)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .environment(\.layoutDirection, .leftToRight)
    }
}

struct SettingsPreviewBox<Content: View>: View {
    @Environment(\.palette) private var palette
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: SettingsAlign.frame)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(palette.segmentTrackBg)
            .clipShape(RoundedRectangle(cornerRadius: SettingsMetrics.previewRadius, style: .continuous))
    }
}
