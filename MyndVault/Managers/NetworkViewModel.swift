//
//  NetworkViewModel.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 16.03.24.
//

import Foundation
import Network
import Combine

final class NetworkManager: ObservableObject {
    @Published var hasInternet: Bool = true
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var cancellable: AnyCancellable?

    init() {
        startMonitoring()
        observeNetworkChanges()
    }

    deinit {
        stopMonitoring()
    }

    func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
        cancellable?.cancel()
    }

    private func startMonitoring() {
        stopMonitoring()

        monitor = NWPathMonitor()
        monitor?.start(queue: queue)

        monitor?.pathUpdateHandler = { path in
            let status = path.status == .satisfied
            NotificationCenter.default.post(
                name: .networkStatusChanged,
                object: nil,
                userInfo: ["status": status]
            )
        }
    }

    private func observeNetworkChanges() {
        cancellable = NotificationCenter.default.publisher(for: .networkStatusChanged)
            .compactMap { $0.userInfo?["status"] as? Bool }
            .receive(on: DispatchQueue.main)
            .assign(to: \.hasInternet, on: self)
    }
}

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}
