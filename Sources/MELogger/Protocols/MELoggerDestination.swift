import Foundation

/// A list of basic settings for a given destination
public protocol MELoggerDestinationSetting {
    
    /// Set to true if it is enabled
    var isEnabled: Bool { get set }
    
    /// If set to true, the timestamp will also be logged
    ///
    /// Useful for log files or time sensitive console logging.
    var isTimestampEnabled: Bool { get set }
    
    /// Determines the minimum log level at which this destination is triggered
    ///
    /// The level this is set to is included in the log, but anything below it will not be shown.
    var minimumLevel: MELogger.Level { get set }

    /// Do the settings permit log messages?
    /// - Parameter level: The level at which to check
    func allowsLogging(at level: MELogger.Level) -> Bool
}

/// Default implementation
public extension MELoggerDestinationSetting {
    
    /// Do the settings permit log messages?
    /// - Parameter level: The level at which to check
    func allowsLogging(at level: MELogger.Level) -> Bool {

        guard self.isEnabled else { return false }
        guard self.minimumLevel.rawValue <= level.rawValue else { return false }
        return true
    }
}

/// A protocol for a logging destination (such as console, a file, Slack, etc.)
public protocol MELoggerDestination {
    
    /// Returns a timestamp string that can be used in log outputs
    var currentTimestamp: String { get }

    /// Settings for this destination
    var settings: MELoggerDestinationSetting { get set }
    
    /// Log a message with the given log level
    ///
    /// - Parameters:
    ///   - level: The log level
    ///   - label: A helpful label to display for the log message (usually the bundle id)
    ///   - message: The text that will be displayed in the console
    ///   - metadata: A dictionary of string key/value pairs to log
    ///   - error: An optional `Error`. Only available for levels `.error` and `.critical`.
    ///   - file: The file name
    ///   - line: Line number
    ///   - function: Function name
    func log(_ level: MELogger.Level, label: String, with message: @autoclosure () -> MELogger.Message, metadata: @autoclosure () -> MELogger.Metadata, error: Error?, file: String, line: Int, function: String)
    
}

/// Internal implementation for logger destination
public extension MELoggerDestination {

    /// Returns a timestamp string that can be used in log outputs
    var currentTimestamp: String {

        var buffer = [Int8](repeating: 0, count: 255)
        var timestamp = time(nil)
        let localTime = localtime(&timestamp)
        strftime(&buffer, buffer.count, "%Y-%m-%dT%H:%M:%S%z", localTime)

        return buffer.withUnsafeBufferPointer {

            $0.withMemoryRebound(to: CChar.self) {
                String(cString: $0.baseAddress!)
            }
        }
    }
}
