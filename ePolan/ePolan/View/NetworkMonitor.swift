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
class NetworkMonitor {
    private let networkMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "Monitor")
    var isConnected = false

    init() {
        networkMonitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
        }
        networkMonitor.start(queue: workerQueue)
    }
}
