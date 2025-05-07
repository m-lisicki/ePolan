//
//  NetworkMonitor.swift
//  ePolan
//
//  Created by Michał Lisicki on 06/05/2025.
//  Copyright © 2025 orgName. All rights reserved.
//


import Foundation
import Network

@Observable
final class NetworkMonitor: Sendable {
    private let networkMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "Monitor")
    
    @MainActor
    var isConnected = false

    init() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: workerQueue)
    }
}
