import SwiftyBeaver

final class Logger: SwiftyBeaver {
    static func configurations() {
        var minLevel: (console: Level, file: Level, nelo: Level) {
            switch Environment.currentPhase {
            case .real:
                return (console: .error, file: .error, nelo: .error)
            default:
                return (console: .debug, file: .debug, nelo: .info)
            }
        }
        
        let consoleDestination = ConsoleDestination()
        consoleDestination.minLevel = minLevel.console
        
        let fileDestination = FileDestination()
        fileDestination.minLevel = minLevel.file
        
        Logger.addDestination(consoleDestination)
        Logger.addDestination(fileDestination)
    }
}
