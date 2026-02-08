import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab?
    @AppStorage("appearance") private var appearance = AppAppearance.auto.rawValue

    init(initialTab: SettingsTab = .general) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Section("Settings") {
                    ForEach(SettingsTab.settingsTabs) { tab in
                        Label {
                            Text(tab.title)
                        } icon: {
                            SettingsIconView(systemImage: tab.icon)
                        }
                        .tag(tab)
                    }
                }

                Section(Bundle.main.appName) {
                    ForEach(SettingsTab.appTabs) { tab in
                        Label {
                            Text(tab.title)
                        } icon: {
                            SettingsIconView(systemImage: tab.icon)
                        }
                        .tag(tab)
                    }
                }
            }
            .navigationSplitViewColumnWidth(200)
        } detail: {
            if let selectedTab {
                selectedTab.view()
                    .navigationTitle(selectedTab.title)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(width: 660, height: 420)
        .onChange(of: appearance, initial: true) { _, newValue in
            NSApp.appearance = AppAppearance(rawValue: newValue)?.nsAppearance
        }
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
