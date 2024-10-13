//
//  NetworkViewModel.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 16.03.24.
//

import Foundation
import Network

final class NetworkManager: ObservableObject, @unchecked Sendable {
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @MainActor
    @Published var hasInternet: Bool = true

    init() {
        startMonitoring()
    }

    deinit {
        stopMonitoringSync()
    }

    private func startMonitoring() {
        stopMonitoringSync() // Synchronous cleanup before starting again

        monitor = NWPathMonitor()
        monitor?.start(queue: queue)

        monitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let currentlyHasInternet = path.status == .satisfied
                if self?.hasInternet != currentlyHasInternet {
                    self?.hasInternet = currentlyHasInternet
                }
            }
        }
    }

    // Actor-isolated function for async contexts
    func stopMonitoring() async {
        monitor?.cancel()
        monitor = nil
    }

    // Synchronous cleanup method for deinit
    private func stopMonitoringSync() {
        monitor?.cancel()
        monitor = nil
    }
}
