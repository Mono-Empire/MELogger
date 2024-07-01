import XCTest
@testable import MELogger

class MELoggerTests: XCTestCase {

    enum FakeError: Error {
        case fake1, fake2
    }

    var mockLogger: MELogger!
    let mockLogDestination = MockLoggerDestination()

    private var existingSharedEnabled: Bool!
    private var existingSharedDestinations: [MELoggerDestination]!

    override func setUpWithError() throws {

        super.setUp()

        let localLogDestinations = MELoggerDestinationManager(
            destinations: [self.mockLogDestination]
        )


        self.mockLogger = MELogger(label: "Mock logger", destinationManager: localLogDestinations)
        self.mockLogDestination.reset()

        self.existingSharedEnabled = MELoggerDestinationManager.shared.isEnabled()
        self.existingSharedDestinations = MELoggerDestinationManager.shared.getDestinations()
        MELoggerDestinationManager.shared.removeAll()
        MELoggerDestinationManager.shared.enable(true)
    }

    override func tearDownWithError() throws {

        // Reset and disable log
        self.mockLogDestination.reset()
        self.mockLogDestination.settings.isEnabled = false
        MELoggerDestinationManager.shared.removeAll()
        MELoggerDestinationManager.shared.add(self.existingSharedDestinations)
        MELoggerDestinationManager.shared.enable(self.existingSharedEnabled)
    }

    func testLoggerSettings() {
        
        // Minimum level
        self.mockLogDestination.settings.minimumLevel = .info
        
        XCTAssertFalse(self.mockLogDestination.settings.allowsLogging(at: .trace))
        XCTAssertTrue(self.mockLogDestination.settings.allowsLogging(at: .critical))
        
        self.mockLogger.debug("A debug message")
        XCTAssertNil(self.mockLogDestination.lastLoggedMessage)
        XCTAssertFalse(self.mockLogDestination.lastLogWasAllowed!)
        
        let msg = "A warning message"
        self.mockLogger.warning(msg)
        XCTAssertEqual(self.mockLogDestination.lastLoggedMessage, msg)
        XCTAssertTrue(self.mockLogDestination.lastLogWasAllowed!)
        
        // Now try with timestamp
        self.mockLogDestination.settings.isTimestampEnabled = true
        self.mockLogger.warning(msg)
        XCTAssertNotEqual(self.mockLogDestination.lastLoggedMessage, msg)
        self.mockLogDestination.settings.isTimestampEnabled = false
        self.mockLogDestination.reset()
        
        // Enable/disable
        self.mockLogDestination.settings.isEnabled = false
        XCTAssertFalse(self.mockLogDestination.settings.allowsLogging(at: .critical))
        self.mockLogDestination.settings.isEnabled = true
        XCTAssertTrue(self.mockLogDestination.settings.allowsLogging(at: .critical))
    }

    func testLoggerError() {

        self.mockLogger.error("Error", error: FakeError.fake1)
        guard let lastLoggedError = self.mockLogDestination.lastLoggedError, case FakeError.fake1 = lastLoggedError else {
            XCTFail("Error fail!")
            return
        }

        self.mockLogger.error("Error with nil")
        XCTAssertNil(self.mockLogDestination.lastLoggedError)

        self.mockLogger.critical("Critical error", error: FakeError.fake2)
        guard let lastLoggedError = self.mockLogDestination.lastLoggedError, case FakeError.fake2 = lastLoggedError else {
            XCTFail("Error fail!")
            return
        }
    }
    
    func testLoggerSharedDestinations() {
        
        let anotherMockLogDestination = MockLoggerDestination(
            settings: MockLoggerDestination.Settings(
                isEnabled: true,
                isTimestampEnabled: true,
                minimumLevel: .warning
            )
        )
        MELoggerDestinationManager.shared.add(anotherMockLogDestination)
        
        // None sent to another; but one sent to log destination
        self.mockLogger.debug("Another debug message")
        XCTAssertNil(anotherMockLogDestination.lastLoggedMessage)
        XCTAssertFalse(anotherMockLogDestination.lastLogWasAllowed!)
        XCTAssertNotNil(self.mockLogDestination.lastLoggedMessage)
        XCTAssertEqual(1, self.mockLogDestination.loggedMessages.count)
        
        // Send to both
        self.mockLogger.warning("Another warning message")
        XCTAssertNotNil(anotherMockLogDestination.lastLoggedMessage)
        XCTAssertTrue(anotherMockLogDestination.lastLogWasAllowed!)
        XCTAssertEqual(1, anotherMockLogDestination.loggedMessages.count)
        XCTAssertNotNil(self.mockLogDestination.lastLoggedMessage)
        XCTAssertEqual(2, self.mockLogDestination.loggedMessages.count)
        
    }
    
    func testConsoleLoggerDestination() {

        let settings = ConsoleLoggerDestination.Settings(isEnabled: true)
        let consoleLoggerDestination = ConsoleLoggerDestination(settings: settings)
        MELoggerDestinationManager.shared.add(consoleLoggerDestination)
        
        consoleLoggerDestination.log(.notice, label: "console.destination.test", with: "Testing a notice console message", metadata: ["metadatakey": "Meta data value"], error: nil, file: "MELoggerTests.swift", line: 83, function: "testConsoleLoggerDestination")
        
        // Nothing was sent to mock destination...
        XCTAssertNil(self.mockLogDestination.lastLoggedMessage)
    }
    
    func testFileLoggerDestination() {

        let settings = FileLoggerDestination.Settings(logFileSizeLimit: 300, logFileRotationsKept: 2)
        let fileLoggerDestination = FileLoggerDestination(settings: settings)
        fileLoggerDestination.clearLogFiles()
        XCTAssertEqual(1, fileLoggerDestination.getLogFiles().count)

        MELoggerDestinationManager.shared.add(fileLoggerDestination)
        self.mockLogger.warning("Warning message to file")
        
        guard let currentUrl = FileLoggerDestination.File.current.getUrl(for: settings), let firstRotationUrl = FileLoggerDestination.File.rotation(number: 1).getUrl(for: settings) else {

            XCTFail("Could not get url for settings!")
            return
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: currentUrl.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: firstRotationUrl.path))
        XCTAssertEqual(1, fileLoggerDestination.getLogFiles().count)

        // Now log a few more for rotation to trigger
        self.mockLogger.warning("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.")
        fileLoggerDestination.log(.warning, label: "file.destination.test", with: "Some longer messages so as to trigger rotation", metadata: [:], error: nil, file: "MELoggerTests.swift", line: 109, function: "testFileLoggerDestination")
        XCTAssertTrue(FileManager.default.fileExists(atPath: currentUrl.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: firstRotationUrl.path))
        XCTAssertEqual(2, fileLoggerDestination.getLogFiles().count)

        fileLoggerDestination.clearLogFiles()
        XCTAssertEqual(1, fileLoggerDestination.getLogFiles().count)
    }
    
    func testFileLoggerEquatable() {
        
        let dest1 = FileLoggerDestination()
        let dest2 = FileLoggerDestination()
        let dest3 = dest1
        
        XCTAssertNotEqual(dest1, dest2)
        XCTAssertEqual(dest1, dest3)
    }
}
