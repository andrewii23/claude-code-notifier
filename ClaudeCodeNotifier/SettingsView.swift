import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    @AppStorage("appearance") private var appearance = AppAppearance.auto.rawValue

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            contentPane
        }
        .ignoresSafeArea()
        .frame(width: 660, height: 420)
        .onChange(of: appearance, initial: true) { _, newValue in
            NSApp.appearance = AppAppearance(rawValue: newValue)?.nsAppearance
        }
    }

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SidebarSection(title: "Settings", tabs: SettingsTab.settingsTabs, selectedTab: $selectedTab)
                SidebarSection(title: Bundle.main.appName, tabs: SettingsTab.appTabs, selectedTab: $selectedTab)
            }
            .padding(.bottom, 12)
        }
        .padding(.top, 50)
        .padding(.horizontal, 12)
        .frame(width: 240)
    }

    private var contentPane: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                SettingsIconView(systemImage: selectedTab.icon)
                Text(selectedTab.title)
                    .font(.title2)
                Spacer()
            }
            .frame(height: 50)
            .padding(.horizontal, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    selectedTab.view()
                }
                .padding(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SidebarSection: View {
    let title: String
    let tabs: [SettingsTab]
    @Binding var selectedTab: SettingsTab

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.body, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.leading, 6)

            ForEach(tabs) { tab in
                SidebarTabButton(tab: tab, isSelected: selectedTab == tab) {
                    selectedTab = tab
                }
            }
        }
    }
}

struct SidebarTabButton: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                SettingsIconView(systemImage: tab.icon)
                Text(tab.title)
                    .font(.system(size: 13))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(minHeight: 30)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    private var backgroundColor: Color {
        if isSelected {
            return .white.opacity(0.15)
        } else if isHovering {
            return .white.opacity(0.07)
        }
        return .clear
    }
}

struct SettingsIconView: View {
    let systemImage: String

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .foregroundStyle(SettingsTab.iconColor.gradient)
            .opacity(0.8)
            .overlay {
                borderShine

                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 1)
            }
            .frame(width: 22, height: 22)
    }

    private var borderShine: some View {
        RoundedRectangle(cornerRadius: 6)
            .strokeBorder(.white, lineWidth: 1)
            .mask {
                LinearGradient(
                    colors: [
                        .white,
                        .clear,
                        .white.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .opacity(0.4)
    }
}

private extension Bundle {
    var appName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "App"
    }
}
