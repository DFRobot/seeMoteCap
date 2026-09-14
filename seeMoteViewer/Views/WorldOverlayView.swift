//
//  WorldOverlayView.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import SwiftUI
import ARKit
import RealityKit
import os.log

/// 混合沉浸空间视图。
///
/// 显示配件锚点、参考模型，并在触发时放置数字复制品。
struct WorldOverlayView: View {
    @Environment(AppState.self) private var appState

    @State private var anchorRoot = Entity()
    @State private var referenceRoot = Entity()
    @State private var replicaRoot = Entity()
    @State private var renderTask: Task<Void, Never>?
    @State private var spatialTrackingSession: SpatialTrackingSession?

    private let maxReplicaCount = 50
    private let logger = Logger(category: "WorldOverlayView")

    var body: some View {
        RealityView { content in
            content.add(anchorRoot)
            content.add(referenceRoot)
            content.add(replicaRoot)
        }
        .onChange(of: appState.accessoryTracker.enabledLocations, initial: true) {
            recreateAnchors()
        }
        .onChange(of: appState.accessoryTracker.trackingMode) {
            recreateAnchors()
        }
        .onChange(of: previewEntityID, initial: true) {
            recreateAnchors()
        }
        .onDisappear {
            renderTask?.cancel()
            renderTask = nil
            anchorRoot.removeFromParent()
            referenceRoot.removeFromParent()
            replicaRoot.removeFromParent()
            Task {
                await spatialTrackingSession?.stop()
                spatialTrackingSession = nil
            }
        }
        .task {
            await observeReplicaPlacements()
        }
        .task {
            await observeReplicaClear()
        }
        .task {
            let session = SpatialTrackingSession()
            spatialTrackingSession = session
            let configuration = SpatialTrackingSession.Configuration(tracking: [.accessory])
            await session.run(configuration)
        }
    }

    private var previewEntityID: ObjectIdentifier? {
        appState.accessoryTracker.previewEntityID
    }

    private func recreateAnchors() {
        renderTask?.cancel()
        renderTask = Task { [weak appState] in
            guard let appState else { return }
            await recreateAnchorsOnMainActor(appState: appState)
        }
    }

    @MainActor
    private func recreateAnchorsOnMainActor(appState: AppState) async {
        let tracker = appState.accessoryTracker

        guard let source = await tracker.createAnchorSource() else {
            logger.error("No anchor source available.")
            anchorRoot.children.removeAll()
            referenceRoot.children.removeAll()
            return
        }

        guard !Task.isCancelled else { return }

        anchorRoot.children.removeAll()
        for location in tracker.enabledLocations {
            let entity = AnchorManager.createAnchorEntity(
                for: source,
                at: location,
                trackingMode: tracker.trackingMode
            )
            anchorRoot.addChild(entity)
        }

        referenceRoot.children.removeAll()
        if let previewEntity = tracker.previewEntity {
            let reference = AnchorManager.createReferenceAnchorEntity(
                for: source,
                trackingMode: tracker.trackingMode,
                previewEntity: previewEntity,
                scale: tracker.previewModel.displayScale
            )
            referenceRoot.addChild(reference)
        }
    }

    private func observeReplicaClear() async {
        for await _ in appState.accessoryTracker.clearReplicaSignal {
            replicaRoot.children.removeAll()
        }
    }

    private func observeReplicaPlacements() async {
        for await _ in appState.accessoryTracker.replicaPlacementSignal {
            placeReplica()
            await appState.accessoryTracker.playHaptic(multiPulse: false)
        }
    }

    private func placeReplica() {
        guard let referenceAnchor = referenceRoot.children.first as? AnchorEntity else {
            logger.warning("No reference anchor available for replica placement.")
            return
        }
        guard let previewEntity = appState.accessoryTracker.previewEntity else {
            logger.warning("Preview entity is not ready; skipping replica placement.")
            return
        }

        if replicaRoot.children.count >= maxReplicaCount {
            replicaRoot.children.first?.removeFromParent()
        }

        let replica = AnchorManager.makePreviewClone(
            from: previewEntity,
            scale: appState.accessoryTracker.previewModel.displayScale
        )

        guard let transform = AnchorManager.referenceModelWorldTransform(from: referenceAnchor) else {
            logger.warning("Failed to compute reference model world transform.")
            return
        }
        replica.transform = transform

        if let arkitComponent = referenceAnchor.components[ARKitAnchorComponent.self],
           let anchor = arkitComponent.anchor as? AccessoryAnchor {
            logger.debug("Placed replica for anchor: \(anchor)")
        }

        replicaRoot.addChild(replica)
    }
}

#Preview(immersionStyle: .mixed) {
    WorldOverlayView()
        .environment(AppState())
}
