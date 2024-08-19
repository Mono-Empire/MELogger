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
    let destinations: [MELoggerDestination]

    /// Shared destinations enabled
    let sharedDestinationsEnabled: Bool
    
    /// An assertion failure (which triggers a crash for debug builds) will be thrown for these log levels
    let throwAssertionFailureLogLevels: [Level]
    
    /// Destinations shared among all loggers
    ///
    /// Defaults to logging to console.
    public static var sharedDestinations: [MELoggerDestination] = [ConsoleLoggerDestination()]
    
    // MARK: - Public Methods

    /// Initializer
    /// - Parameter label: The label displayed when logging (can be the name of the component)
    /// - Parameter destinations: An optional list of log destinations such as the console, a file, etc. specific to this logger
    /// - Parameter sharedDestinationsEnabled: If set to true (the default) log messages will be sent to shared destinations as well. You should leave this true unless you want something specific or are for example using a logger for unit tests.
    /// - Parameter throwAssertionFailureLogLevels: An assertion failure (which triggers a crash for debug builds) will be thrown for these log levels. Defaults to everything above `error`.
    public init(
        label: String,
        destinations: [MELoggerDestination] = [],
        sharedDestinationsEnabled: Bool = true,
        throwAssertionFailureLogLevels: [Level] = [.error, .critical]
    ) {
        
        self.label = label
        self.destinations = destinations
        self.sharedDestinationsEnabled = sharedDestinationsEnabled
        self.throwAssertionFailureLogLevels = throwAssertionFailureLogLevels
    }

    /// Appropriate for messages that contain information normally of use only when tracing the execution
    /// - Parameter message: The text that will be displayed in the console
    /// - Parameter metadata: A key/value (both strings) dictionary of metadata to send along with the message
    /// - Parameter error: Optionally you can also pass an `Error` which may be processed by some destinations
    public func trace(
        _ message: @autoclosure () -> Message,
        metadata: @autoclosure () -> Metadata = [:],
        error: Error? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
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
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        self.log(.debug, with: message(), metadata: metadata(), error: error, file: file, line: line, function: function)
    }
    
    /// Appropriate for informational messages
    /// - Parameter message: The text that will be displayed in the console
    /// - Parameter metadata: A key/value (both strings) dictionary of metadata to send along with the message
    /// - Parameter error: Optionally you can also pass an `Error` which may be processed by some destinations
    public func info(
        _ message: @autoclosure () -> Message,
        metadata: @autoclosure () -> Metadata = [:],
        error: Error? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
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
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
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
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
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
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        self.log(.error, with: message(), metadata: metadata(), error: error, file: file, line: line, function: function)
    }
    
    /// Appropriate for critical error conditions that usually require immediate attention
    ///
    /// The default console destination will also perform a `fatalError()` (which will crash the application, even in production).
    /// - Parameter message: The text that will be displayed in the console
    /// - Parameter metadata: A key/value (both strings) dictionary of metadata to send along with the message
    /// - Parameter error: Optionally you can also pass an `Error` which may be processed by some destinations
    public func critical(
        _ message: @autoclosure () -> Message,
        metadata: @autoclosure () -> Metadata = [:],
        error: Error? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
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
        file: String,
        line: Int,
        function: String
    ) {
                
        // Shared destinations
        if self.sharedDestinationsEnabled {

            MELogger.sharedDestinations.forEach {
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
        self.destinations.forEach {
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
        
        // Throw assertion failures?
        if self.throwAssertionFailureLogLevels.contains(level) {
            assertionFailure(message())
        }
    }
}
