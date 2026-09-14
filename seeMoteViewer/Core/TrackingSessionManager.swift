//
//  TrackingSessionManager.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import ARKit
import RealityKit
@unsafe @preconcurrency import GameController
import os.log

/// 管理 ARKit 授权、session 与 `AccessoryTrackingProvider` 生命周期。
@MainActor
@Observable
final class TrackingSessionManager {
    private let logger = Logger(category: "TrackingSessionManager")
    private let arkitSession = ARKitSession()

    private(set) var authorizationStatus: ARKitSession.AuthorizationStatus = .notDetermined
    private(set) var trackingProviderState: DataProviderState?
    private(set) var heldChirality: Accessory.Chirality?
    private(set) var isTracked: Bool = false
    private(set) var trackingState: AccessoryAnchor.TrackingState?
    private(set) var latestAnchor: AccessoryAnchor?

    private var trackingProvider: AccessoryTrackingProvider? {
        didSet { trackingProviderState = trackingProvider?.state }
    }
    private let providerTask = CancellableTask()
    private let authTask = CancellableTask()

    init() {
        authTask.set(Task { [weak self] in
            await self?.observeAuthorizationStatus()
        })
    }

    func fetchLatestAnchor(trackingMode: AnchoringComponent.TrackingMode) -> AccessoryAnchor? {
        guard let provider = trackingProvider,
              provider.state == .running,
              let latest = provider.latestAnchors.first else {
            return nil
        }

        if trackingMode == .predicted {
            return provider.predictAnchor(
                for: latest,
                at: CACurrentMediaTime() + 0.01
            )
        }
        return latest
    }

    func startTracking(for device: GCSpatialAccessory?) async {
        providerTask.cancel()
        guard let device else {
            trackingProvider = nil
            resetTrackingMetrics()
            return
        }

        do {
            let accessory = try await Accessory(device: device)
            let provider = AccessoryTrackingProvider(accessories: [accessory])
            trackingProvider = provider
            try await arkitSession.run([provider])
            trackingProviderState = provider.state
            logger.info("Accessory tracking provider is running.")

            providerTask.set(Task { [weak self] in
                await self?.observeTrackingUpdates(provider: provider)
            })
        } catch {
            logger.error("Failed to start tracking: \(error)")
            trackingProvider = nil
        }
    }

    func stopTracking() async throws {
        providerTask.cancel()
        trackingProvider = nil
        resetTrackingMetrics()
        do {
            try await arkitSession.run([])
        } catch {
            logger.error("Failed to stop tracking: \(error)")
            throw error
        }
    }

    private func observeAuthorizationStatus() async {
        authorizationStatus = await arkitSession.queryAuthorization(for: [.accessoryTracking])[.accessoryTracking] ?? .notDetermined

        for await event in arkitSession.events {
            switch event {
            case .authorizationChanged(.accessoryTracking, let status):
                authorizationStatus = status
                if status != .allowed {
                    do {
                        try await stopTracking()
                    } catch {
                        logger.error("Stop failed after auth change: \(error)")
                    }
                }
            case .dataProviderStateChanged(let providers, let state, let error):
                if providers.contains(where: { $0 is AccessoryTrackingProvider }) {
                    trackingProviderState = state
                    if let error {
                        logger.error("Accessory tracking provider failed: \(error)")
                    }
                }
            default:
                break
            }
        }
    }

    private func observeTrackingUpdates(provider: AccessoryTrackingProvider) async {
        for await update in provider.anchorUpdates {
            trackingProviderState = provider.state
            let anchor = update.anchor
            latestAnchor = anchor
            heldChirality = anchor.heldChirality
            isTracked = anchor.isTracked
            trackingState = anchor.trackingState
        }
    }

    private func resetTrackingMetrics() {
        heldChirality = nil
        isTracked = false
        trackingState = nil
        latestAnchor = nil
    }
}
