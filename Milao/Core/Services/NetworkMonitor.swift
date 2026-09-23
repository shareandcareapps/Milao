import Foundation
import Network

/// Tracks basic network reachability app-wide via NWPathMonitor — no special
/// entitlement or permission needed. Backs the offline banner in ContentView.swift;
/// screens don't need to read this directly, since their own fetch error states
/// already handle a failed request either way.
@Observable
@MainActor
final class NetworkMonitor {
    private(set) var isConnected = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.taralabs.milao.network-monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor in self?.isConnected = connected }
        }
        monitor.start(queue: queue)
    }
}
