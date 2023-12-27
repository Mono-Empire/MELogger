import Foundation

/// Logs messages to the console in Xcode
public struct ConsoleLoggerDestination: MELoggerDestination {

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
        
        /// The minimum level at which we throw assertion failures
        ///
        /// Useful for development because high level log messages require immediate attention. The recommended value is `.error`, but can also be set to nil to disable this feature for all levels.
        public var minimumLevelForAssertionFailures: MELogger.Level?

        /// Limits console messages to this many characters
        ///
        /// If set to nil, no limit is enforced.
        public var maximumMessageLength: Int?
        
        /// Default settings
        public init(
            isEnabled: Bool = true,
            isTimestampEnabled: Bool = true,
            minimumLevel: MELogger.Level = .info,
            minimumLevelForAssertionFailures: MELogger.Level? = .error,
            maximumMessageLength: Int? = 1000
        ) {

            self.isEnabled = isEnabled
            self.isTimestampEnabled = isTimestampEnabled
            self.minimumLevel = minimumLevel
            self.minimumLevelForAssertionFailures = minimumLevelForAssertionFailures
            self.maximumMessageLength = maximumMessageLength
        }
    }

    /// My settings
    public var settings: MELoggerDestinationSetting
    
    /// Initializer
    public init(settings: Settings = Settings()) {
        self.settings = settings
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

        guard self.settings.allowsLogging(at: level) else { return }

        // Concatenate meta data string
        var metadataString =
            "[location: \(file).\(function) line \(line)]"
            + metadata().map { "[\($0): \($1)]" }.joined(separator: " ")
            + "[label: \(label)]"

        // Add error description, if available
        if let error = error {
            metadataString += "[error: \(error.localizedDescription)]"
        }

        // Truncates the messages according to settings, if needed.
        var messageString = message()
        if let maximumMessageLength = (self.settings as? Settings)?.maximumMessageLength, messageString.count > maximumMessageLength {
            messageString = String(messageString[..<messageString.index(messageString.startIndex, offsetBy: maximumMessageLength)])
        }
        if let maximumMessageLength = (self.settings as? Settings)?.maximumMessageLength, metadataString.count > maximumMessageLength {
            metadataString = String(metadataString[..<metadataString.index(metadataString.startIndex, offsetBy: maximumMessageLength)])
        }

        print("\(level.prefix) \(messageString) \(metadataString)")
        
        // Throw assertion failure above level
        if let settings = self.settings as? ConsoleLoggerDestination.Settings,
           let minimumLevelForAssertionFailures = settings.minimumLevelForAssertionFailures,
           level.rawValue >= minimumLevelForAssertionFailures.rawValue {
            assertionFailure(message())
        }
    }
}
