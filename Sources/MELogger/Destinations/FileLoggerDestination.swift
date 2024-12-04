import Foundation

/// Logs messages to a file stored on the local device
///
/// - Warning: Use this with care; if not handled properly unauthorized users could gain access to these log file. This may or may not be a problem, but you should definitely keep that in mind! Generally I'd recommend allowing this only on internal builds.
public class FileLoggerDestination: MELoggerDestination {

    // MARK: - Properties
    
    /// An id used for equatable comparison
    private let uuid = UUID()

    // MARK: - File handling

    /// The output stream
    struct FileOutputStream: TextOutputStream {
        
        /// Possible errors
        enum FileOutputStreamError: Error {
            
            /// When the documents directory is not available
            case couldNotAccessDocumentsDirectory
            
            /// When the file could not be created
            case couldNotCreateFile
            
            /// When the file is too big (needs rotation)
            case fileTooBig
        }
        
        /// The file handle
        private let fileHandle: FileHandle
        
        /// The encoding
        let encoding: String.Encoding
        
        /// Bytes remaining before hitting file size limit
        var bytesRemaining: Int64

        /// Initializer
        init(with settings: Settings) throws {

            guard let url = File.current.getUrl(for: settings) else {
                throw FileOutputStreamError.couldNotAccessDocumentsDirectory
            }
            
            // Create file and handle
            if !FileManager.default.fileExists(atPath: url.path) {

                guard FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil) else {
                    throw FileOutputStreamError.couldNotCreateFile
                }
            }
            let fileHandle = try FileHandle(forWritingTo: url)
            fileHandle.seekToEndOfFile()
            self.fileHandle = fileHandle

            // Calculate size
            let fileAttributes: [FileAttributeKey: Any] =  try FileManager.default.attributesOfItem(atPath: url.path)
            let currentFileSize = (fileAttributes[FileAttributeKey.size] as? NSNumber )?.int64Value ?? 0
            self.bytesRemaining = settings.logFileSizeLimit - currentFileSize

            self.encoding = settings.logFileEncoding
        }

        /// Write a line to the file
        ///
        /// Will throw an error if we no longer have enough space.
        mutating func write(_ string: String) {

            if let data = string.data(using: encoding) {

                self.bytesRemaining -= Int64(data.count)
                self.fileHandle.write(data)
            }
        }
        
        /// Close the file
        func close() {
            self.fileHandle.closeFile()
        }
    }
    
    /// References a type of log file
    enum File {
        
        /// References the currently active log file
        case current
        
        /// Refrences a rotation of the log file, specified by number
        case rotation(number: Int)
        
        /// Returns the file name
        func getFileName(for settings: Settings) -> String {

            switch self {
            case .current:
                return "\(settings.logFileName).log"
            case .rotation(let number):
                return "\(settings.logFileName).\(number).log"
            }
        }
        
        /// Get the file url, if available
        func getUrl(for settings: Settings) -> URL? {
            
            // Create folders
            guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return nil }
            guard let writePath = NSURL(fileURLWithPath: path).appendingPathComponent(settings.logFileFolder) else { return nil }
            try? FileManager.default.createDirectory(atPath: writePath.path, withIntermediateDirectories: true)
            
            // Add file name
            return writePath.appendingPathComponent(self.getFileName(for: settings))
        }
        
    }
    
    /// The shared output stream
    private var sharedStream: FileOutputStream?

    /// Rotation semaphore
    private static let logFileActivitySemaphore = DispatchSemaphore(value: 1)

    // MARK: - Settings

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
        
        /// Location of the log file
        ///
        /// Relative to the `documentDirectory`.
        public var logFileFolder: String
        
        /// Name of the file, without .log extension
        ///
        /// If set to "application" (the default) then messages logged to application.log, while rotations are named application.1.log, application.2.log, etc.
        public var logFileName: String
        
        /// Maximum file size, expressed in bytes
        ///
        /// Upon reaching this size the file is rotated (to a specific backup which is then overwritten). Defaults to 1 MB.
        public var logFileSizeLimit: Int64
        
        /// Keep rotations
        ///
        /// The number of rotated files to keep (in addition to the active log file).
        public var logFileRotationsKept: Int
        
        /// Log file encoding
        public var logFileEncoding: String.Encoding
        
        /// Default settings
        public init(
            isEnabled: Bool = true,
            isTimestampEnabled: Bool = true,
            minimumLevel: MELogger.Level = .info,
            logFileFolder: String = "logs",
            logFileName: String = "application",
            logFileSizeLimit: Int64 = 1024 * 1024,
            logFileRotationsKept: Int = 10,
            logFileEncoding: String.Encoding = .utf8
        ) {

            self.isEnabled = isEnabled
            self.isTimestampEnabled = isTimestampEnabled
            self.minimumLevel = minimumLevel
            self.logFileFolder = logFileFolder
            self.logFileName = logFileName
            self.logFileSizeLimit = logFileSizeLimit
            self.logFileRotationsKept = logFileRotationsKept
            self.logFileEncoding = logFileEncoding
        }
    }

    /// My settings
    public var settings: MELoggerDestinationSetting
    
    /// Internal settings
    private var internalSettings: Settings {
        guard let settings = self.settings as? Settings else {

            assertionFailure("File Logger was passed incompatible settings. Using defaults!")
            return Settings()
        }
        return settings
    }
     
    // MARK: - Public methods
    
    /// Initializers
    public init(settings: Settings = Settings()) {

        self.settings = settings
        self.createStream()
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
        
        // Concatenate additional data string
        var metadataString = metadata().map { "[\($0): \($1)]" }.joined(separator: " ") + "[label: \(label)]"

        // Add error description, if available
        if let error = error {
            metadataString += "[error: \(error.localizedDescription)]"
        }

        // Rotate logs if needed
        self.rotateLogsIfNeeded()
        
        // Write to file
        self.sharedStream?.write("\(level.prefix) \(message()) \(metadataString)\n")
    }
    
    /// Get URLs for each log file that exists on the file system
    ///
    /// Current files and rotated files.
    public func getLogFiles() -> [URL] {
        
        var logFiles: [URL?] = []
        
        // Active
        logFiles.append(File.current.getUrl(for: self.internalSettings))
        
        // Rotated
        if self.internalSettings.logFileRotationsKept > 0 {

            for fileRotationNumber in 1...self.internalSettings.logFileRotationsKept {
                logFiles.append(File.rotation(number: fileRotationNumber).getUrl(for: self.internalSettings))
            }
        }
        
        // Check if exists
        return logFiles.compactMap {
            
            guard let path = $0?.path, FileManager.default.fileExists(atPath: path) else { return nil }
            return $0
        }
    }
    
    /// Remove all log files
    public func clearLogFiles() {
        
        // Wait for other threads...
        FileLoggerDestination.logFileActivitySemaphore.wait()
        
        guard let stream = self.sharedStream else {

            FileLoggerDestination.logFileActivitySemaphore.signal()
            return
        }
        stream.close()
        self.sharedStream = nil

        // Remove all
        for fileToRemove in self.getLogFiles() {
            try? FileManager.default.removeItem(at: fileToRemove)
        }
                
        // Create new stream
        self.createStream()
        FileLoggerDestination.logFileActivitySemaphore.signal()
    }
    
}

// MARK: - Private methods

private extension FileLoggerDestination {
    
    /// Create my logger stream
    func createStream() {

        guard self.sharedStream == nil else { return }
        do {

            let stream = try FileOutputStream(with: self.internalSettings)
            self.sharedStream = stream
        } catch let error {
            assertionFailure("File Logger could not initialize the file: \(error.localizedDescription)")
        }
    }
        
    /// Rotates all files
    func rotateLogsIfNeeded() {
        
        // Wait for other threads...
        FileLoggerDestination.logFileActivitySemaphore.wait()
        
        guard let stream = self.sharedStream else {

            FileLoggerDestination.logFileActivitySemaphore.signal()
            return
        }
        guard stream.bytesRemaining <= 0 else {

            FileLoggerDestination.logFileActivitySemaphore.signal()
            return
        }
        stream.close()
        self.sharedStream = nil

        // Delete the last rotation
        if let fileToRemove = File.rotation(number: self.internalSettings.logFileRotationsKept).getUrl(for: self.internalSettings) {
            try? FileManager.default.removeItem(at: fileToRemove)
        }
        
        // Move all others
        var fileRotationNumber = self.internalSettings.logFileRotationsKept
        while fileRotationNumber > 1 {

            guard let toUrl = File.rotation(number: fileRotationNumber).getUrl(for: self.internalSettings), let fromUrl = File.rotation(number: fileRotationNumber - 1).getUrl(for: self.internalSettings) else {

                assertionFailure("File Logger could not rotate files")
                continue
            }
            try? FileManager.default.moveItem(at: fromUrl, to: toUrl)
            fileRotationNumber -= 1
        }
        
        // Move current
        guard let toUrl = File.rotation(number: 1).getUrl(for: self.internalSettings), let fromUrl = File.current.getUrl(for: self.internalSettings) else {

            assertionFailure("File Logger could not rotate files")
            FileLoggerDestination.logFileActivitySemaphore.signal()
            return
        }
        try? FileManager.default.moveItem(at: fromUrl, to: toUrl)

        // Now create a new stream
        self.createStream()
        FileLoggerDestination.logFileActivitySemaphore.signal()
    }
}

// MARK: - Equatable
extension FileLoggerDestination: Equatable {

    public static func == (
        lhs: FileLoggerDestination,
        rhs: FileLoggerDestination
    ) -> Bool {
        lhs.uuid == rhs.uuid
    }
}
