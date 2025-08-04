//
//  NetworkMonitor.swift
//  BananaClock
//
//  Monitors network connectivity status for intelligent fallback decisions
//

import Network
import Foundation
import SwiftUI

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    // MARK: - Published Properties
    
    @Published var isConnected = true
    @Published var isExpensive = false  // Cellular or personal hotspot
    @Published var isConstrained = false  // Low data mode
    @Published var connectionType: NWInterface.InterfaceType?
    @Published var currentPath: NWPath?
    
    // MARK: - Private Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .background)
    nonisolated private let hasStartedLock = NSLock()
    nonisolated private let _hasStarted = AtomicBool(false)
    
    nonisolated private var hasStarted: Bool {
        get {
            return _hasStarted.value
        }
        set {
            _hasStarted.value = newValue
        }
    }
    
    // Connection quality estimation
    @Published var connectionQuality: ConnectionQuality = .unknown
    
    enum ConnectionQuality: String, CaseIterable {
        case excellent = "Excellent"  // WiFi, good signal
        case good = "Good"           // Cellular 4G/5G
        case fair = "Fair"           // Cellular 3G or constrained
        case poor = "Poor"           // Very slow or unstable
        case offline = "Offline"     // No connection
        case unknown = "Unknown"
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            case .offline: return .gray
            case .unknown: return .gray
            }
        }
        
        var shouldAttemptDownload: Bool {
            switch self {
            case .excellent, .good, .fair:
                return true
            case .poor, .offline, .unknown:
                return false
            }
        }
        
        var downloadTimeout: TimeInterval {
            switch self {
            case .excellent: return 30.0
            case .good: return 20.0
            case .fair: return 15.0
            case .poor: return 10.0
            case .offline, .unknown: return 5.0
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Network Monitoring
    
    private func startMonitoring() {
        guard !hasStarted else { return }
        hasStarted = true
        
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                self.currentPath = path
                self.isConnected = path.status == .satisfied
                self.isExpensive = path.isExpensive
                self.isConstrained = path.isConstrained
                
                // Determine connection type
                if let interface = path.availableInterfaces.first {
                    self.connectionType = interface.type
                } else {
                    self.connectionType = nil
                }
                
                // Update connection quality
                self.connectionQuality = self.evaluateConnectionQuality(path: path)
                
                // Log status change
                self.logNetworkStatus()
            }
        }
        
        monitor.start(queue: queue)
        print("🌐 Network monitoring started")
    }
    
    nonisolated private func stopMonitoring() {
        guard hasStarted else { return }
        monitor.cancel()
        hasStarted = false
        print("🌐 Network monitoring stopped")
    }
    
    // MARK: - Connection Quality Evaluation
    
    private func evaluateConnectionQuality(path: NWPath) -> ConnectionQuality {
        guard path.status == .satisfied else {
            return .offline
        }
        
        // Check if we're on WiFi
        let isWiFi = path.usesInterfaceType(.wifi)
        let isCellular = path.usesInterfaceType(.cellular)
        let isWired = path.usesInterfaceType(.wiredEthernet)
        
        // Excellent: WiFi or Wired, not constrained
        if (isWiFi || isWired) && !path.isConstrained {
            return .excellent
        }
        
        // Good: WiFi (constrained) or Cellular (not constrained)
        if isWiFi || (isCellular && !path.isConstrained && !path.isExpensive) {
            return .good
        }
        
        // Fair: Cellular (expensive or constrained)
        if isCellular {
            return .fair
        }
        
        // Poor: Other connection types or heavily constrained
        if path.status == .satisfied {
            return .poor
        }
        
        return .unknown
    }
    
    // MARK: - Network Status Helpers
    
    /// Check if we should attempt to download content
    func shouldAttemptContentDownload() -> Bool {
        return isConnected && connectionQuality.shouldAttemptDownload
    }
    
    /// Get recommended timeout for network operations
    func recommendedTimeout() -> TimeInterval {
        return connectionQuality.downloadTimeout
    }
    
    /// Check if we're on WiFi
    var isOnWiFi: Bool {
        return connectionType == .wifi
    }
    
    /// Check if we're on cellular
    var isOnCellular: Bool {
        return connectionType == .cellular
    }
    
    /// Get human-readable connection description
    var connectionDescription: String {
        guard isConnected else {
            return "No Connection"
        }
        
        var description = ""
        
        switch connectionType {
        case .wifi:
            description = "Wi-Fi"
        case .cellular:
            description = "Cellular"
        case .wiredEthernet:
            description = "Ethernet"
        case .loopback:
            description = "Loopback"
        case .other:
            description = "Other"
        case nil:
            description = "Unknown"
        @unknown default:
            description = "Unknown"
        }
        
        if isExpensive {
            description += " (Expensive)"
        }
        
        if isConstrained {
            description += " (Low Data Mode)"
        }
        
        return description
    }
    
    // MARK: - Logging
    
    private func logNetworkStatus() {
        print("🌐 Network Status Update:")
        print("  - Connected: \(isConnected)")
        print("  - Type: \(connectionDescription)")
        print("  - Quality: \(connectionQuality.rawValue)")
        print("  - Should Download: \(shouldAttemptContentDownload())")
    }
    
    // MARK: - Testing Support
    
    #if DEBUG
    /// Override connection status for testing
    func setTestConnectionQuality(_ quality: ConnectionQuality) {
        self.connectionQuality = quality
        self.isConnected = quality != .offline
        print("🧪 Test mode: Connection quality set to \(quality.rawValue)")
    }
    
    /// Simulate connection change
    func simulateConnectionChange(connected: Bool, type: NWInterface.InterfaceType? = nil) {
        self.isConnected = connected
        self.connectionType = type
        self.connectionQuality = connected ? .good : .offline
        print("🧪 Test mode: Simulated connection change - Connected: \(connected)")
    }
    #endif
}

// MARK: - NWPath Extension

extension NWPath {
    /// Check if path uses a specific interface type
    func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool {
        return availableInterfaces.contains { $0.type == type }
    }
}

// MARK: - Thread-Safe Atomic Bool

/// Thread-safe atomic boolean for nonisolated contexts
private final class AtomicBool: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Bool
    
    init(_ initialValue: Bool) {
        _value = initialValue
    }
    
    var value: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }
}