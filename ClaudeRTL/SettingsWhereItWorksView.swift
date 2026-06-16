import SwiftUI

struct SettingsWhereItWorksView: View {
    @EnvironmentObject private var model: SettingsModel
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: SettingsAlign.horizontal, spacing: SettingsMetrics.cardSpacing) {
            SettingsCard {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: SettingsAlign.horizontal, spacing: 3) {
                        Text("تفعيل Claude RTL")
                            .font(.settingsRowLabel())
                            .foregroundStyle(palette.textPrimary)
                        Text("إظهار التصحيح عند نسخ نص عربي")
                            .font(.settingsRowDesc())
                            .foregroundStyle(palette.textSecondary)
                    }
                    Spacer(minLength: 0)
                    CoralSwitch(isOn: $model.isEnabled)
                }
            }

            SettingsCard {
                SettingsCardLabel(text: "وضع التشغيل")
                VStack(spacing: 4) {
                    SettingsOptionRow(
                        title: TriggerMode.allApps.label,
                        subtitle: "يعمل في أي تطبيق على جهازك",
                        isSelected: model.triggerMode == .allApps
                    ) { model.triggerMode = .allApps }

                    SettingsOptionRow(
                        title: TriggerMode.claudeOnly.label,
                        subtitle: "يظهر داخل تطبيق Claude فقط",
                        isSelected: model.triggerMode == .claudeOnly
                    ) { model.triggerMode = .claudeOnly }

                    SettingsOptionRow(
                        title: TriggerMode.customList.label,
                        subtitle: "تطبيقات محددة فقط",
                        isSelected: model.triggerMode == .customList
                    ) { model.triggerMode = .customList }
                }
            }

            contextualAppsCard
        }
    }

    @ViewBuilder
    private var contextualAppsCard: some View {
        switch model.triggerMode {
        case .allApps:
            SettingsAppListCard(
                label: "التطبيقات المستثناة",
                apps: model.excludedApps,
                emptyMessage: "لا توجد تطبيقات مستثناة بعد",
                onRemove: model.removeExcluded,
                onAdd: model.addExcludedApp
            )
        case .customList:
            SettingsAppListCard(
                label: "التطبيقات المسموح بها",
                apps: model.includedApps,
                emptyMessage: "لا توجد تطبيقات مسموح بها بعد",
                onRemove: model.removeIncluded,
                onAdd: model.addIncludedApp
            )
        case .claudeOnly:
            SettingsCard {
                Text("يعمل Claude RTL داخل تطبيق Claude فقط — لا حاجة لإدارة قائمة تطبيقات.")
                    .font(.settingsRowDesc())
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.leading)
                    .settingsContentWidth()
            }
        }
    }
}

struct SettingsAppListCard: View {
    @Environment(\.palette) private var palette
    let label: String
    let apps: [AppRecord]
    let emptyMessage: String
    let onRemove: (String) -> Void
    let onAdd: () -> Void

    var body: some View {
        SettingsCard {
            SettingsCardLabel(text: label)

            if apps.isEmpty {
                Text(emptyMessage)
                    .font(.settingsEmpty())
                    .foregroundStyle(palette.textMuted)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(apps, id: \.bundleId) { app in
                        SettingsAppListRow(app: app) {
                            onRemove(app.bundleId)
                        }
                    }
                }
            }

            BorderedAddButton(title: "إضافة تطبيق", action: onAdd)
                .frame(maxWidth: .infinity, alignment: SettingsAlign.frame)
                .padding(.top, apps.isEmpty ? 4 : 12)
        }
    }
}

private struct SettingsAppListRow: View {
    @Environment(\.palette) private var palette
    let app: AppRecord
    let onRemove: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            if let icon = AppIconHelper.icon(forBundleIdentifier: app.bundleId) {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            Text(app.name)
                .font(.settingsRowLabel())
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.textMuted)
                    .frame(width: 28, height: 28)
                    .background(isHovered ? palette.navHoverBg : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }
        }
        .padding(.vertical, 6)
    }
}
