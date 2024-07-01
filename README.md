# MELogger

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMono-Empire%2FMELogger%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Mono-Empire/MELogger)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMono-Empire%2FMELogger%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Mono-Empire/MELogger)

## Installation

You can install the package under your `Project / Package Dependencies` settings. Or if you are specifying it as a dependency for another package you can add the dependency in `Package.swift`:

    //...
    dependencies: [
        .package(
            url: "git@github.com:Mono-Empire/MELogger.git",
            from: Version("2.0.2")
        )
    ],
    targets: [
        .target(
            name: "YourProject",
            dependencies: [
                .product(
                    name: "MELogger",
                    package: "MELogger"
                ),
            ]
        ),
        //...
    ]
    //...

## Basic usage

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

By default, error will also trigger assertionFailure() and critical will trigger a fatalError(), but this behavior can be changed by modifying the default console log destination (see below).

## Specify log destinations

Each logger instance can be set up with one or more logging destinations - so for example, log messages can be sent to both the console and to a log file. For each destination you can set what level to log, and also a number of other destination-specific settings like log file size and rotation preferences.

Here's an example of setting up logging to a file:

    // Create a file logger (see the in-code documentation for more settings)
    let settings = FileLoggerDestination.Settings(logFileSizeLimit: 300, logFileRotationsKept: 2)
    let fileLoggerDestination = FileLoggerDestination(settings: settings)
    
    // Add the destination to an existing logger instance...
    logger.destinationManager.add(fileLoggerDestination)
    
    // ...or you can add the destination to all logger instances:
    MELoggerDestinationManager.shared.add(fileLoggerDestination)
    
The destination object also provides useful methods to manage log files:

    // Get all the log files
    let logFiles = fileLoggerDestination.getLogFiles()
    
    // Clear the log files
    fileLoggerDestination.clearLogFiles()



## Custom log destinations

You can also write your own custom logging destinations, such as logging to a cloud service. Simply implement a new `struct` that conforms to `MELoggerDestination`.

As an example, see `CrashlyticsLoggerDestination` here. Not all of your packages will have Crashlytics dependencies, but it is enough to just to add the `CrashlyticsLoggerDestination` once to your shared destinations:

    // For example, in your AppDelegate's didFinishLaunchingWithOptions...
    
    // Initialize Firebase
    FirebaseApp.configure()

    // Add Crashlytics destination
    MELoggerDestinationManager.shared.add(CrashlyticsLoggerDestination())

Now that you have `CrashlyticsLoggerDestination` as a shared destination even the relevant log messages from sub-packages that do not have Firebase dependencies will be sent to Crashlytics.

## Testing with MockLoggerDestination

In certain cases it may be useful to test error cases in your code using the `MockLoggerDestination`.  This log destination allows you to access any previous log messages for your assertions. For example in your tests: 

    // ExampleTests.swift
    
    // Create and add mock destination
    let mockLogDestination = MockLogDestination()
    MELoggerDestinationManager.shared.removeAll()
    MELoggerDestinationManager.shared.add(mockLogDestination)
    
    // Do something illegal
    let myExample = Example()
    myExample.doSomethingThatTriggersWarning()
    
    // Check if it was illegal
    XCTAssertEqual(anotherMockLogDestination.lastLoggedLevel, .warning)
    XCTAssertFalse(anotherMockLogDestination.loggedMessages.isEmpty)
    XCTAssertEqual(anotherMockLogDestination.lastLoggedMessage, "The warning message")
