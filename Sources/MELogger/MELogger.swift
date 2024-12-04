import Foundation

/// Implements a simplified version of Apple's swift-log API to log messages to various destinations in a consistent manner.
///
/// Clones the basic API with label and logging methods.
///
/// Usage:
///
/// Called from  main bundle:
///
///     Constants.logger.info("User logged in successfully")
///
/// Results in the following log messages:
///
///     [ INFO ] User logged in successfully [label: com.bundle.identifier]
///
/// - Link: https://github.com/apple/swift-log
public struct MELogger {
    
    // MARK: - Types

    /// An log message
    public typealias Message = String

    /// Metadata that can be passed along with a log message
    public typealias Metadata = [String: String]
 
    /// The available logging levels
    public enum Level: Int8 {
        case trace = 0
        case debug = 1
        case info = 2
        case notice = 3
        case warning = 4
        case error = 5
        case critical = 6
        
        /// Description
        public var string: String {
            return "\(self)"
        }
        
        /// Returns the prefix for the given level
        public var prefix: String {
            switch self {
            case .warning:
                return "[ ⚠️ \(self.string.uppercased()) ]"
            case .error, .critical:
                return "[ 🚨 \(self.string.uppercased()) ]"
            default:
                return "[ \(self.string.uppercased()) ]"
            }
        }
    }
    
    // MARK: - Properties

    /// The label for the logger
    let label: String
    
    /// Destinations for logging, specific to this logger
    ///
    /// If nil, it means there are no additional destinations.
    let destinationManager: MELoggerDestinationManager?

    // MARK: - Public Methods

    /// Initializer
    /// - Parameter label: The label displayed when logging (can be the name of the component).
    /// - Parameter destinationManager: An optional set of log destinations such as the console, a file, etc. specific to this logger. If left nil (the default) the shared destinations will be used.
    public init(
        label: String,
        destinationManager: MELoggerDestinationManager? = nil
    ) {
        
        self.label = label
        self.destinationManager = destinationManager
    }

    /// Appropriate for messages that contain information normally of use only when tracing the execution
    /// - Parameter message: The text that will be displayed in the console
    /// - Parameter metadata: A key/value (both strings) dictionary of metadata to send along with the message
    /// - Parameter error: Optionally you can also pass an `Error` which may be processed by some destinations
    public func trace(
        _ message: @autoclosure () -> Message,
        metadata: @autoclosure () -> Metadata = [:],
        error: Error? = nil,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) {
        self.log(.trace, with: message(), metadata: metadata(), error: error, file: file, line: line, function: function)
    }

    /// Appropriate for messages that contain information normally of use only when debugging
    /// - Parameter message: The text that will be displayed in the console
    /// - Parameter metadata: A key/value (both strings) dictionary of metadata to send along with the message
    /// - Parameter error: Optionally you can also pass an `Error` which may be processed by some destinations
    public func debug(
        _ message: @autoclosure () -> Message,
        metadata: @autoclosure () -> Metadata = [:],
        error: Error? = nil,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) {
        self.log(.debug, with: message(), metadata: metadata(), error: error, file: file, line: line, function: function)
    }
    
    /// Appropriate for informational messages
    /// - Parameter message: The text that will be displayed in the console
    /// - Parameter metadata: A key/value (both strings) dictionary of metadata to send along with the message
    public func info(
        _ message: @autoclosure () -> Message,
        metadata: @autoclosure () -> Metadata = [:],
        error: Error? = nil,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) {
        self.log(.info, with: message(), metadata: metadata(), error: error, file: file, line: line, function: function)
    }
    
    /// Appropriate for conditions that are not error conditions, but that may require special handling
    /// - Parameter message: The text that will be displayed in the console
    /// - Parameter metadata: A key/value (both strings) dictionary of metadata to send along with the message
    /// - Parameter error: Optionally you can also pass an `Error` which may be processed by some destinations
    public func notice(
        _ message: @autoclosure () -> Message,
        metadata: @autoclosure () -> Metadata = [:],
        error: Error? = nil,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) {
        self.log(.notice, with: message(), metadata: metadata(), error: error, file: file, line: line, function: function)
    }
    
    /// Appropriate for messages that are not error conditions, but more severe than notice
    /// - Parameter message: The text that will be displayed in the console
    /// - Parameter metadata: A key/value (both strings) dictionary of metadata to send along with the message
    /// - Parameter error: Optionally you can also pass an `Error` which may be processed by some destinations
    public func warning(
        _ message: @autoclosure () -> Message,
        metadata: @autoclosure () -> Metadata = [:],
        error: Error? = nil,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) {
        self.log(.warning, with: message(), metadata: metadata(), error: error, file: file, line: line, function: function)
    }
    
    /// Appropriate for error conditions
    ///
    /// The default console destination will also perform an `assertionFailure()` (which will stop execution during debug).
    /// - Parameter message: The text that will be displayed in the console
    /// - Parameter metadata: A key/value (both strings) dictionary of metadata to send along with the message
    /// - Parameter error: Optionally you can also pass an `Error` which may be processed by some destinations
    public func error(
        _ message: @autoclosure () -> Message,
        metadata: @autoclosure () -> Metadata = [:],
        error: Error? = nil,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) {
        self.log(.error, with: message(), metadata: metadata(), error: error, file: file, line: line, function: function)
    }
    
    /// Appropriate for critical error conditions that usually require immediate attention
    ///
    /// The default console destination will also perform an `assertionFailure()` (which will stop execution during debug).
    /// - Parameter message: The text that will be displayed in the console
    /// - Parameter metadata: A key/value (both strings) dictionary of metadata to send along with the message
    /// - Parameter error: Optionally you can also pass an `Error` which may be processed by some destinations
    public func critical(
        _ message: @autoclosure () -> Message,
        metadata: @autoclosure () -> Metadata = [:],
        error: Error? = nil,
        file: StaticString = #fileID,
        line: UInt = #line,
        function: StaticString = #function
    ) {
        self.log(.critical, with: message(), metadata: metadata(), error: error, file: file, line: line, function: function)
    }
    
    // MARK: - Private methods
    
    /// General logging method to log to each destination.
    ///
    /// - Parameters:
    ///   - level: The log level
    ///   - message: The text that will be displayed in the console
    ///   - metadata: A key/value (both strings) dictionary of metadata to send along with the message
    ///   - error: Optionally you can also pass an `Error` which may be processed by some destinations
    ///   - file: The file name
    ///   - line: Line number
    ///   - function: Function name
    private func log(
        _ level: Level,
        with message: @autoclosure () -> Message,
        metadata: @autoclosure () -> Metadata = [:],
        error: Error? = nil,
        file: StaticString,
        line: UInt,
        function: StaticString
    ) {
                
        // Shared destinations
        if MELoggerDestinationManager.shared.isEnabled() {
            MELoggerDestinationManager.shared.getDestinations().forEach {
                $0.log(
                    level,
                    label: self.label,
                    with: ($0.settings.isTimestampEnabled ? "[\($0.currentTimestamp)] " : "") + message(),
                    metadata: metadata(),
                    error: error,
                    file: file,
                    line: line,
                    function: function
                )
            }
        }
        
        // My destinations
        if let destinations = self.destinationManager, destinations.isEnabled() {
            destinations.getDestinations().forEach {
                $0.log(
                    level,
                    label: self.label,
                    with: ($0.settings.isTimestampEnabled ? "[\($0.currentTimestamp)] " : "") + message(),
                    metadata: metadata(),
                    error: error,
                    file: file,
                    line: line,
                    function: function
                )
            }
        }
    }
}
