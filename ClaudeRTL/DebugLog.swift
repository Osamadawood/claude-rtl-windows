import Foundation

enum DebugLog {
    static func print(
        _ items: Any...,
        separator: String = " ",
        terminator: String = "\n"
    ) {
        #if DEBUG
        let message = items.map { String(describing: $0) }.joined(separator: separator)
        Swift.print(message, terminator: terminator)
        #endif
    }
}
