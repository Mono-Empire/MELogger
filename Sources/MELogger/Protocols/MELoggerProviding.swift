import Foundation

/// A protocol that provides a static logger instance
public protocol MELoggerProviding {
    
    /// A static logger
    static var logger: MELogger { get }
}
