//
//  seeMoteViewerApp.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import SwiftUI

@main
struct seeMoteViewerApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup(id: "seeMoteMainWindow") {
            ControlPanelView()
                .environment(appState)
                .environment(\.locale, appState.localeManager.currentLocale)
        }
        .defaultSize(
            width: AppConfiguration.mainWindowSize.width,
            height: AppConfiguration.mainWindowSize.height
        )
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.automatic)

        ImmersiveSpace(id: AppConfiguration.immersiveSpaceID) {
            WorldOverlayView()
                .environment(appState)
                .environment(\.locale, appState.localeManager.currentLocale)
                .onAppear {
                    appState.sceneState.immersiveSpaceState = .open
                }
                .onDisappear {
                    appState.sceneState.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
