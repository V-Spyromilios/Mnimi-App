//
//  NetworkViewModel.swift
//  Memory
//
//  Created by Evangelos Spyromilios on 16.03.24.
//

import Foundation
import Network
import Combine

@MainActor
final class NetworkManager: ObservableObject {
    @Published var hasInternet: Bool = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let status = path.status == .satisfied
            Task { @MainActor in
                self?.hasInternet = status
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
