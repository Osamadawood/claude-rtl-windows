import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            WhereItWorksTab()
                .tabItem {
                    Label("أين يعمل", systemImage: "location")
                }

            AppearanceTab()
                .tabItem {
                    Label("المظهر", systemImage: "paintbrush")
                }

            GeneralTab()
                .tabItem {
                    Label("عام", systemImage: "gearshape")
                }
        }
        .padding(20)
    }
}

// MARK: - Where it works

private struct WhereItWorksTab: View {
    @EnvironmentObject private var model: SettingsModel

    var body: some View {
        Form {
            Section {
                Toggle("مُفعّل", isOn: $model.isEnabled)
            }

            Section {
                Picker("وضع التشغيل", selection: $model.triggerMode) {
                    ForEach(TriggerMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section {
                switch model.triggerMode {
                case .allApps:
                    AppListSection(
                        title: "التطبيقات المستثناة",
                        apps: model.excludedApps,
                        emptyMessage: "لا توجد تطبيقات مستثناة.",
                        onRemove: model.removeExcluded,
                        onAdd: model.addExcludedApp
                    )
                case .customList:
                    AppListSection(
                        title: "التطبيقات المسموح بها",
                        apps: model.includedApps,
                        emptyMessage: "لا توجد تطبيقات في القائمة.",
                        onRemove: model.removeIncluded,
                        onAdd: model.addIncludedApp
                    )
                case .claudeOnly:
                    Text("يعمل في Claude فقط — لا حاجة لإدارة قائمة.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Appearance

private struct AppearanceTab: View {
    @EnvironmentObject private var model: SettingsModel

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("حجم خط البابل")
                    Slider(value: $model.fontSize, in: 12 ... 22, step: 1)
                    Text("\(Int(model.fontSize))")
                        .monospacedDigit()
                        .foregroundStyle(ClaudeRTLColors.coral)
                        .frame(minWidth: 28)
                    Button("إعادة تعيين") {
                        model.resetFontSize()
                    }
                }
            }

            Section {
                Picker("المظهر", selection: $model.themeMode) {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - General

private struct GeneralTab: View {
    @EnvironmentObject private var model: SettingsModel
    @State private var showResetConfirm = false

    var body: some View {
        Form {
            Section {
                Toggle("تشغيل عند بدء النظام", isOn: $model.launchAtLogin)
            }

            Section {
                Button("إعادة عرض الشرح") {
                    model.showOnboarding()
                }

                Button("إعادة تعيين كل الإعدادات") {
                    showResetConfirm = true
                }
                .foregroundStyle(.red)
            }

            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("الإصدار \(Settings.versionLabel()) — GRW Lab")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Link("grwlab.net", destination: URL(string: "https://grwlab.net")!)
                            .font(.caption)
                    }
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
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
}

// MARK: - App list

private struct AppListSection: View {
    let title: String
    let apps: [AppRecord]
    let emptyMessage: String
    let onRemove: (String) -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if apps.isEmpty {
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                List {
                    ForEach(apps, id: \.bundleId) { app in
                        AppListRow(app: app) {
                            onRemove(app.bundleId)
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                .frame(minHeight: min(CGFloat(apps.count) * 44 + 8, 180))
            }

            Button("إضافة تطبيق…", action: onAdd)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

private struct AppListRow: View {
    let app: AppRecord
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if let icon = AppIconHelper.icon(forBundleIdentifier: app.bundleId) {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text(app.name)
                    .lineLimit(1)
                Text(app.bundleId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .environment(\.layoutDirection, .leftToRight)
            }

            Spacer(minLength: 8)

            Button("إزالة", action: onRemove)
                .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Root wrapper (theme)

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
