import Foundation

@available(*, deprecated, renamed: "MELoggerDestinationManager")
typealias LoggerDestinationManager = MELoggerDestinationManager

/// Managers the log destinations to be used throughout your app
final public class MELoggerDestinationManager: @unchecked Sendable {

    private static let instanceId = UUID()

    private let loggerDestinationEnabledMutatingLock = DispatchQueue(
        label: "melogger.destination.\(instanceId).enabled.lock"
    )

    private let loggerDestinationListMutatingLock = DispatchQueue(
        label: "melogger.destination.\(instanceId).list.lock"
    )

    /// The shared instance of the destination manager
    ///
    /// This manages shared log destinations.
    static let shared = MELoggerDestinationManager(
        destinations: []
    )

    /// Set to true if these destinations are enabled
    private var enabled: Bool

    /// The list of destinations
    private var destinations: [MELoggerDestination] = []

    /// Initializer
    public init(enabled: Bool = true, destinations: [MELoggerDestination]) {
        self.enabled = enabled
        self.destinations = destinations
    }

    /// Get all of the destinations
    /// - Returns: The logger destinations for this destination manager.
    public func getDestinations() -> [MELoggerDestination] {
        self.loggerDestinationListMutatingLock.sync {
            return self.destinations
        }
    }

    /// Add a destination to the list of log destinations
    /// - Parameter destination: The logger destination to add to the list of destinations.
    public func add(_ destination: MELoggerDestination) {
        self.loggerDestinationListMutatingLock.sync {
            self.destinations.append(destination)
        }
    }

    /// Add multiple destinations to the list of log destinations
    /// - Parameter destinations: A list of logger detsinations to add to the existing list of destinations.
    public func add(_ destinations: [MELoggerDestination]) {
        self.loggerDestinationListMutatingLock.sync {
            self.destinations.append(contentsOf: destinations)
        }
    }

    /// Remove a destination
    /// - Parameter destinationType: The class of the destination to remove.
    public func remove(type destinationType: MELoggerDestination.Type) {
        self.loggerDestinationListMutatingLock.sync {
            self.destinations = []
        }
    }

    /// Remove all of the destinations
    public func removeAll() {
        self.loggerDestinationListMutatingLock.sync {
            self.destinations = []
        }
    }

    /// Enable or disable shared destinations
    /// - Parameter enable: True if you want to enable this set of destinations, false if you want to disable it.
    public func enable(_ enable: Bool) {
        self.loggerDestinationEnabledMutatingLock.sync {
            self.enabled = enable
        }
    }

    /// Returns the enabled state of the destination list
    /// - Returns: True if the list is enabled.
    public func isEnabled() -> Bool {
        self.loggerDestinationEnabledMutatingLock.sync {
            return self.enabled
        }
    }
}
