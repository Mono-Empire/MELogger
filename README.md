# MELogger

Basic usage
--------------

Provides a generalized logging interface very similar to `SwiftLog`.  Allows logging to console, to a file, or to any other custom destination (such as a cloud service, Slack, etc.). 

Usage is simple:

    // Instantiate a Logger (perhaps as a global constant, but that's up to you)
    let logger = Logger(label: "com.example.mybundle")
    // ...by default messages will be logged to the console.
    
    // Log a message, specifying the log-level with the appropriate method:
    logger.warning("This is a warning")
    // ...you can add some meta-data too:
    logger.notice("This is just a notice", metadata: ['class': 'MyClassName'])
    
    // For error and critical, you can also pass an optional `Error`
    logger.error("Something bad happened!", error: err)

You have the following available levels:

* trace
* debug
* info
* notice
* warning
* error
* critical

By default error and critical will also trigger assertionFailure(), but this behavior can be changed by modifying the `throwAssertionFailureLogLevels` parameter when you create a `MELogger` instance.

Specify log destinations
----------------------------

Each logger instance can be set up with one or more logging destinations - so for example, log messages can be sent to both the console and to a log file. For each destination you can set what level to log, and also a number of other destination-specific settings like log file size and rotation preferences.

Here's an example of setting up logging to a file:

    // Create a file logger (see the in-code documentation for more settings)
    let settings = FileLoggerDestination.Settings(logFileSizeLimit: 300, logFileRotationsKept: 2)
    let fileLoggerDestination = FileLoggerDestination(settings: settings)
    
    // Add the destination to an existing logger instance...
    logger.destinations.append(fileLoggerDestination)
    
    // ...or you can add the destination to all logger instances:
    Logger.sharedDestinations.append(fileLoggerDestination)
    
The destination object also provides useful methods to manage log files:

    // Get all the log files
    let logFiles = fileLoggerDestination.getLogFiles()
    
    // Clear the log files
    fileLoggerDestination.clearLogFiles()



Custom log destinations
----------------------------

You can also write your own custom logging destinations, such as logging to a cloud service. Simply implement a new `struct` that conforms to `LoggerDestination`. See the existing destinations in this package as examples.

If generally useful, consider contributing it to this package.

Testing with MockLoggerDestination
------------------------------------------

In certain cases it may be useful to test error cases in your code using the `MockLoggerDestination`.  This log destination allows you to access any previous log messages for your assertions. For example in your tests: 

    // ExampleTests.swift
    
    // Create and add mock destination
    let mockLogDestination = MockLogDestination()
    Logger.sharedDestinations.append(mockLogDestination)
    
    // Do something illegal
    let myExample = Example()
    myExample.doSomethingThatTriggersWarning()
    
    // Check if it was illegal
    XCTAssertEqual(anotherMockLogDestination.lastLoggedLevel, .warning)
    XCTAssertFalse(anotherMockLogDestination.loggedMessages.isEmpty)
    XCTAssertEqual(anotherMockLogDestination.lastLoggedMessage, "Something illegal")

Changelog
-------------

**1.0**

Initial release

**1.1**

- Moved assertion failure configuration to the logger instance initializer (console logger destination config is now deprecated)
- All log levels now accept an optional `error` parameter (it used to be limited to `.error` and up)
