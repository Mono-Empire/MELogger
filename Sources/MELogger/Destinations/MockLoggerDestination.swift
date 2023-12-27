import Foundation

/// Mock logging, useful for testing error cases in unit tests
public class MockLoggerDestination: MELoggerDestination {

    /// Settings
    public struct Settings: MELoggerDestinationSetting {

        /// Set to true means this destination is enabled; false means logs are not sent to the destination
        public var isEnabled: Bool
                
        /// If set to true, the timestamp will also be logged
        ///
        /// Useful for log files or time sensitive destination logging.
        public var isTimestampEnabled: Bool

        /// The minimum level at which we log to the destination
        public var minimumLevel: MELogger.Level
        
        /// Default settings, with the lowest level
        public init(
            isEnabled: Bool = true,
            isTimestampEnabled: Bool = false,
            minimumLevel: MELogger.Level = .trace
        ) {
            self.isEnabled = isEnabled
            self.isTimestampEnabled = isTimestampEnabled
            self.minimumLevel = minimumLevel
        }
    }

    /// My settings
    public var settings: MELoggerDestinationSetting
    
    /// Store the log levels and messages
    public var loggedLevels: [MELogger.Level] = []
    public var loggedMessages: [MELogger.Message] = []
    public var loggedMetadata: [MELogger.Metadata] = []
    public var loggedFiles: [String] = []
    public var loggedLines: [Int] = []
    public var loggedFunctions: [String] = []
    public var loggedLabels: [String] = []
    public var loggedErrors: [Error?] = []
    public var lastLoggedLevel: MELogger.Level? { self.loggedLevels.last }
    public var lastLoggedMessage: MELogger.Message? { self.loggedMessages.last }
    public var lastLoggedMetadata: MELogger.Metadata? { self.loggedMetadata.last }
    public var lastLoggedFile: String? { self.loggedFiles.last }
    public var lastLoggedLine: Int? { self.loggedLines.last }
    public var lastLoggedFunction: String? { self.loggedFunctions.last }
    public var lastLoggedLabels: String? { self.loggedLabels.last }
    public var lastLoggedError: Error? { self.loggedErrors.last ?? nil }
    public var lastLogWasAllowed: Bool?

    /// Initializer
    public init(settings: Settings = Settings()) {

        self.settings = settings
        // By default, mock logger disables shared destinations
        MELogger.sharedDestinations = []
    }
    
    /// Logs to the destination
    public func log(
        _ level: MELogger.Level,
        label: String,
        with message: @autoclosure () -> MELogger.Message,
        metadata: @autoclosure () -> MELogger.Metadata,
        error: Error?,
        file: String,
        line: Int,
        function: String
    ) {

        guard self.settings.allowsLogging(at: level) else {
            self.lastLogWasAllowed = false
            return
        }

        // Store this log message
        self.lastLogWasAllowed = true
        self.loggedMessages.append(message())
        self.loggedLevels.append(level)
        self.loggedMetadata.append(metadata())
        self.loggedFiles.append(file)
        self.loggedLines.append(line)
        self.loggedFunctions.append(function)
        self.loggedLabels.append(label)
        self.loggedErrors.append(error)
    }
    
    /// Resets all of my log stores
    public func reset() {
        
        self.lastLogWasAllowed = nil
        self.loggedMessages = []
        self.loggedLevels = []
        self.loggedMetadata = []
        self.loggedFiles = []
        self.loggedLines = []
        self.loggedFunctions = []
        self.loggedLabels = []
        self.loggedErrors = []
    }
}
