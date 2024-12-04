import Foundation

/// A destination that triggers an assertion failure above a certain level.
public struct AssertionFailureDestination: MELoggerDestination {

    /// Settings
    public struct Settings: MELoggerDestinationSetting {

        /// Set to true means this destination is enabled; false means assertion failures are not thrown
        public var isEnabled: Bool

        /// Ignored for this destination
        public var isTimestampEnabled: Bool

        /// The minimum level at which we throw assertion failures
        ///
        /// Useful for development because high level log messages require immediate attention. The recommended value is `.error`, but can also be set to nil to disable this feature for all levels.
        public var minimumLevel: MELogger.Level

        /// Default settings
        public init(
            isEnabled: Bool = true,
            minimumLevel: MELogger.Level = .error
        ) {

            self.isEnabled = isEnabled
            self.isTimestampEnabled = true
            self.minimumLevel = minimumLevel
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
        file: StaticString,
        line: UInt,
        function: StaticString
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

        let fullString = message() + " " + metadataString
        assertionFailure(fullString, file: file, line: line)
    }
}
