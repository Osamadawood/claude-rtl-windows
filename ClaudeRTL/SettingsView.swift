import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: SettingsModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var selection: SettingsSection = .whereItWorks

    var body: some View {
        HStack(spacing: 0) {
            contentArea
            SettingsSidebar(selection: $selection)
        }
        .background(SettingsSemantic.background(colorScheme))
    }

    private var contentArea: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: SettingsMetrics.sectionSpacing) {
                Text(selection.title)
                    .font(.settingsSectionTitle())
                    .foregroundStyle(SettingsSemantic.primaryText(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Group {
                    switch selection {
                    case .whereItWorks:
                        WhereItWorksContent()
                    case .appearance:
                        AppearanceContent()
                    case .general:
                        GeneralContent()
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }
            .padding(SettingsMetrics.contentPadding)
            .animation(.easeInOut(duration: 0.2), value: selection)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Where it works

private struct WhereItWorksContent: View {
    @EnvironmentObject private var model: SettingsModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .trailing, spacing: SettingsMetrics.sectionSpacing) {
            SettingsCard {
                SettingsToggleRow(title: "تفعيل Claude RTL", isOn: $model.isEnabled)
            }

            SettingsCard {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("وضع التشغيل")
                        .font(.settingsLabel())
                        .foregroundStyle(SettingsSemantic.primaryText(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    ModeRadioRow(
                        title: TriggerMode.allApps.label,
                        subtitle: "يعمل في أي تطبيق.",
                        isSelected: model.triggerMode == .allApps
                    ) { model.triggerMode = .allApps }

                    ModeRadioRow(
                        title: TriggerMode.claudeOnly.label,
                        subtitle: "يعمل في Claude فقط.",
                        isSelected: model.triggerMode == .claudeOnly
                    ) { model.triggerMode = .claudeOnly }

                    ModeRadioRow(
                        title: TriggerMode.customList.label,
                        subtitle: "تطبيقات محددة فقط.",
                        isSelected: model.triggerMode == .customList
                    ) { model.triggerMode = .customList }
                }
            }

            contextualCard
        }
    }

    @ViewBuilder
    private var contextualCard: some View {
        switch model.triggerMode {
        case .allApps:
            AppListCard(
                title: "التطبيقات المستثناة",
                apps: model.excludedApps,
                emptyMessage: "لا توجد تطبيقات مستثناة.",
                onRemove: model.removeExcluded,
                onAdd: model.addExcludedApp
            )
        case .customList:
            AppListCard(
                title: "التطبيقات المسموح بها",
                apps: model.includedApps,
                emptyMessage: "لا توجد تطبيقات في القائمة.",
                onRemove: model.removeIncluded,
                onAdd: model.addIncludedApp
            )
        case .claudeOnly:
            SettingsCard {
                Text("يعمل في Claude فقط — لا حاجة لإدارة قائمة.")
                    .font(.settingsCaption())
                    .foregroundStyle(SettingsSemantic.secondaryText(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

// MARK: - Appearance

private struct AppearanceContent: View {
    @EnvironmentObject private var model: SettingsModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .trailing, spacing: SettingsMetrics.sectionSpacing) {
            SettingsCard {
                VStack(alignment: .trailing, spacing: 10) {
                    Text("السمة")
                        .font(.settingsLabel())
                        .foregroundStyle(SettingsSemantic.primaryText(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    HStack(spacing: 8) {
                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                            ThemeChoiceButton(
                                title: mode.label,
                                isSelected: model.themeMode == mode
                            ) {
                                model.themeMode = mode
                            }
                        }
                    }
                }
            }

            SettingsCard {
                VStack(alignment: .trailing, spacing: 12) {
                    Text("حجم خط البابل")
                        .font(.settingsLabel())
                        .foregroundStyle(SettingsSemantic.primaryText(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    HStack(spacing: 12) {
                        Text("\(Int(model.fontSize))")
                            .font(.settingsLabel())
                            .foregroundStyle(ClaudeRTLColors.coral)
                            .monospacedDigit()
                            .frame(minWidth: 28)

                        Slider(value: $model.fontSize, in: 12 ... 22, step: 1)
                            .tint(ClaudeRTLColors.coral)

                        Button("إعادة تعيين") {
                            model.resetFontSize()
                        }
                        .buttonStyle(CoralSecondaryButtonStyle())
                    }

                    Text("مرحبًا — هذا حجم خط البابل")
                        .font(.settingsArabic(size: model.fontSize))
                        .foregroundStyle(SettingsSemantic.primaryText(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, 4)
                }
            }
        }
    }
}

// MARK: - General

private struct GeneralContent: View {
    @EnvironmentObject private var model: SettingsModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showResetConfirm = false

    var body: some View {
        VStack(alignment: .trailing, spacing: SettingsMetrics.sectionSpacing) {
            SettingsCard {
                SettingsToggleRow(title: "تشغيل عند بدء النظام", isOn: $model.launchAtLogin)
            }

            SettingsCard {
                VStack(alignment: .trailing, spacing: 10) {
                    Button("إعادة عرض الشرح") {
                        model.showOnboarding()
                    }
                    .buttonStyle(CoralSecondaryButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    Button("إعادة تعيين كل الإعدادات") {
                        showResetConfirm = true
                    }
                    .buttonStyle(CoralQuietButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .trailing)
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
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 6) {
                Text("Claude RTL \(Settings.versionLabel())")
                    .font(.settingsLabel())
                    .foregroundStyle(SettingsSemantic.primaryText(colorScheme))
                Link("grwlab.net", destination: URL(string: "https://grwlab.net")!)
                    .font(.settingsCaption())
                    .tint(ClaudeRTLColors.coral)
                Text("أداة مستقلة من GRW Lab، غير تابعة لـ Anthropic")
                    .font(.settingsCaption())
                    .foregroundStyle(SettingsSemantic.secondaryText(colorScheme))
                    .multilineTextAlignment(.trailing)
            }
            if let image = NSApp.applicationIconImage ?? NSImage(named: "AppIcon") {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - App list

private struct AppListCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let apps: [AppRecord]
    let emptyMessage: String
    let onRemove: (String) -> Void
    let onAdd: () -> Void

    var body: some View {
        SettingsCard {
            VStack(alignment: .trailing, spacing: 12) {
                Text(title)
                    .font(.settingsLabel())
                    .foregroundStyle(SettingsSemantic.primaryText(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if apps.isEmpty {
                    Text(emptyMessage)
                        .font(.settingsCaption())
                        .foregroundStyle(SettingsSemantic.secondaryText(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 0) {
                        ForEach(apps, id: \.bundleId) { app in
                            AppListRow(app: app) {
                                onRemove(app.bundleId)
                            }
                            if app.bundleId != apps.last?.bundleId {
                                Divider()
                                    .overlay(SettingsSemantic.cardBorder(colorScheme))
                            }
                        }
                    }
                }

                Button("إضافة تطبيق…", action: onAdd)
                    .buttonStyle(CoralSecondaryButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

private struct AppListRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let app: AppRecord
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button("إزالة", action: onRemove)
                .buttonStyle(CoralQuietButtonStyle())
                .font(.settingsCaption())

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(app.name)
                    .font(.settingsLabel())
                    .foregroundStyle(SettingsSemantic.primaryText(colorScheme))
                    .lineLimit(1)
                Text(app.bundleId)
                    .font(.settingsCaption())
                    .foregroundStyle(SettingsSemantic.secondaryText(colorScheme))
                    .lineLimit(1)
                    .environment(\.layoutDirection, .leftToRight)
            }

            if let icon = AppIconHelper.icon(forBundleIdentifier: app.bundleId) {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: SettingsMetrics.appIconListSize, height: SettingsMetrics.appIconListSize)
                    .clipShape(RoundedRectangle(cornerRadius: SettingsMetrics.appIconListRadius, style: .continuous))
            }
        }
        .frame(minHeight: SettingsMetrics.rowHeight)
    }
}

// MARK: - Root wrapper

struct SettingsRootView: View {
    @ObservedObject private var model = SettingsModel.shared

    var body: some View {
        SettingsView()
            .environmentObject(model)
            .environment(\.layoutDirection, .rightToLeft)
            .tint(ClaudeRTLColors.coral)
            .preferredColorScheme(model.preferredColorScheme)
    }
}
