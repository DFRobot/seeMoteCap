//
//  ControlPanelView.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import SwiftUI
import RealityKit
import os.log

/// 主控制面板视图。
///
/// 显示配件状态、追踪指标、配置选项与操作按钮。
struct ControlPanelView: View {
    @Environment(AppState.self) private var appState

    private let logger = Logger(category: "ControlPanelView")

    var body: some View {
        let tracker = appState.accessoryTracker
        VStack(spacing: 0) {
            TitleBar()

            Group {
                if tracker.accessorySourceLoadError != nil {
                    ContentUnavailableView {
                        Text(LocalizedStringResource("error.accessorySourceLoad"))
                    } description: {
                        Text(LocalizedStringResource("error.accessorySourceLoadDescription"))
                    }
                } else if tracker.failedToLoadReferenceAccessory {
                    ContentUnavailableView {
                        Text(LocalizedStringResource("error.referenceAccessory"))
                    } description: {
                        Text(LocalizedStringResource("error.referenceAccessoryDescription"))
                    }
                } else if tracker.isAccessoryConnected {
                    VStack {
                        AccessorySettingsForm(tracker: tracker, appState: appState)
                    }
                    .padding()
                    .background(.thinMaterial)
                } else {
                    ContentUnavailableView {
                        Text(LocalizedStringResource("status.noAccessoryTitle"))
                    } description: {
                        Text(LocalizedStringResource("status.noAccessoryDescription"))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: AppConfiguration.mainWindowSize.width, height: AppConfiguration.mainWindowSize.height)
        .background(.thinMaterial)
    }
}

/// 配件设置表单。
private struct AccessorySettingsForm: View {
    @Bindable var tracker: AccessoryTracker
    @Bindable var appState: AppState

    private let logger = Logger(category: "ControlPanelView")

    var body: some View {
        Form {
            Section(LocalizedStringResource("section.device")) {
                LabeledContent(LocalizedStringResource("label.name")) {
                    Text(LocalizedStringResource("deviceName.seeMoteCube"))
                }

                ToggleImmersiveSpaceSwitch()
            }

            Section(LocalizedStringResource("section.control")) {
                ForEach(tracker.availableLocations, id: \.self) { location in
                    Toggle(
                        location.localizedName,
                        isOn: binding(for: location)
                    )
                }

                Picker(LocalizedStringResource("section.trackingMode"), selection: $tracker.trackingMode) {
                    ForEach(tracker.availableTrackingModes, id: \.self) { mode in
                        Text(mode.localizedLabel).tag(mode)
                    }
                }

                Picker(LocalizedStringResource("section.selectModel"), selection: $tracker.previewModel) {
                    ForEach(PreviewLoader.PreviewModel.allCases) { model in
                        Text(model.localizedName).tag(model)
                    }
                }

                HStack {
                    Button(LocalizedStringResource("button.placeReplica")) {
                        tracker.triggerReplicaPlacement()
                    }
                    .disabled(!canPlaceReplica)

                    Button(LocalizedStringResource("button.clearScene")) {
                        tracker.clearReplicas()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }

            Section(LocalizedStringResource("section.metrics")) {
                LabeledContent(LocalizedStringResource("label.authorization")) {
                    Text(tracker.authorizationStatus.localizedDescription)
                }
                LabeledContent(LocalizedStringResource("label.providerState")) {
                    if let state = tracker.trackingProviderState {
                        Text(state.localizedDescription)
                    } else {
                        Text(LocalizedStringResource("status.unknown"))
                    }
                }
                LabeledContent(LocalizedStringResource("label.isTracked")) {
                    Text(tracker.isTracked.localizedYesNo)
                }
                LabeledContent(LocalizedStringResource("label.trackingState")) {
                    if let state = tracker.trackingState {
                        Text(state.localizedDescription)
                    } else {
                        Text(LocalizedStringResource("status.unknown"))
                    }
                }
                LabeledContent(LocalizedStringResource("label.heldChirality")) {
                    if let chirality = tracker.heldChirality {
                        Text(chirality.localizedDescription)
                    } else {
                        Text(LocalizedStringResource("status.unknown"))
                    }
                }
            }
        }
    }

    private func binding(for location: AnchoringComponent.AccessoryLocation) -> Binding<Bool> {
        Binding(
            get: { tracker.enabledLocations.contains(location) },
            set: { tracker.toggleLocation(location, enabled: $0) }
        )
    }

    private var canPlaceReplica: Bool {
        appState.sceneState.immersiveSpaceState == .open && tracker.authorizationStatus == .allowed
    }
}

/// 主窗口标题栏。
private struct TitleBar: View {
    var body: some View {
        HStack {
            Spacer()

            Text(LocalizedStringResource("window.title"))
                .font(.headline)

            Spacer()

            if let logoPath = Bundle.main.path(forResource: "logo", ofType: "png"),
               let logoImage = UIImage(contentsOfFile: logoPath) {
                Image(uiImage: logoImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 28)
                    .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                    .padding(.trailing, 12)
            }
        }
        .frame(height: 44)
        .background(.regularMaterial)
    }
}
