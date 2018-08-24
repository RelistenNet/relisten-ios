//
//  Logging.swift
//  RelistenShared
//
//  Created by Jacob Farkas on 8/24/18.
//  Copyright © 2018 Alec Gorge. All rights reserved.
//

import Foundation
import CleanroomLogger

public func SetupLogging() {
    var configs : [LogConfiguration] = []
    
#if DEBUG
    let severity : LogSeverity = .debug
    configs.append(XcodeLogConfiguration(debugMode: true))
#else
    let severity : LogSeverity = .info
#endif
    
    let logDir = RelistenApp.sharedApp.logDirectory
    let rotatingConfig = RotatingLogFileConfiguration(minimumSeverity: severity,
                                                      daysToKeep: 3,
                                                      directoryPath: logDir,
                                                      formatters: [ReadableLogFormatter()])
    do {
        try rotatingConfig.createLogDirectory()
    } catch {
        print("Couldn't create log directory at \"\(logDir)\": \(error)")
        return
    }
    
    configs.append(rotatingConfig)
    
    Log.enable(configuration: configs)
}

// (farkas) I've intentionally omitted the info level here. In my experience the distinction between debug and info is too fuzzy and I'm never consistent about separating the two levels. It's simpler to just have three levels with the following meanings:
//   Error: Something went really wrong and the app is about to crash (or would be better off crashing)
//   Warning: Something is wrong but the app can recover and keep going. This is a bug that should be fixed.
//   Debug: Nothing is wrong, these messages exist to trace state to help debug problems that might come up.
//
// I also intentionally omitted the value logs because those can get too cryptic when reading a log message.
// If you need to log out a value it's better to add a quick descriptive string around it and log it as a message.

public func LogError(_ msg: String, function: String = #function, filePath: String = #file, fileLine: Int = #line) {
    Log.error?.message(msg, function: function, filePath: filePath, fileLine: fileLine)
}

public func LogWarn(_ msg: String, function: String = #function, filePath: String = #file, fileLine: Int = #line) {
    Log.warning?.message(msg, function: function, filePath: filePath, fileLine: fileLine)
}
public func LogWarning(_ msg: String, function: String = #function, filePath: String = #file, fileLine: Int = #line) {
    Log.warning?.message(msg, function: function, filePath: filePath, fileLine: fileLine)
}

public func LogDebug(_ msg: String, function: String = #function, filePath: String = #file, fileLine: Int = #line) {
    Log.debug?.message(msg, function: function, filePath: filePath, fileLine: fileLine)
}

public func Trace(_ function: String = #function, filePath: String = #file, fileLine: Int = #line) {
    Log.debug?.trace(function, filePath: filePath, fileLine: fileLine)
}
