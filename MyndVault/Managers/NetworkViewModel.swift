//
//  NetworkViewModel.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 16.03.24.
//

import Foundation
import Network

final class NetworkManager: ObservableObject {
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var hasInternet: Bool = true

    init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    private func startMonitoring() {

        stopMonitoring()

        monitor = NWPathMonitor()
        monitor?.start(queue: queue)

        monitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                // Update hasInternet only if there's a change
                let currentlyHasInternet = path.status == .satisfied
                if self?.hasInternet != currentlyHasInternet {
                    self?.hasInternet = currentlyHasInternet
                }
            }
        }
    }

    private func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
    }
}

