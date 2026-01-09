//
//  AppLogger .swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/7/26.
//

import Foundation

enum AppLogger {
    /// Включить логирование только в DEBUG режиме
    static var isEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static func debug(_ message: String, file: String = #file, function: String = #function) {
        guard isEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        print("🔍 [\(fileName):\(function)] \(message)")
    }
    
    static func info(_ message: String) {
        guard isEnabled else { return }
        print("ℹ️ \(message)")
    }
    
    static func warning(_ message: String) {
        guard isEnabled else { return }
        print("⚠️ \(message)")
    }
    
    static func error(_ message: String) {
        // Ошибки показываем всегда!
        print("❌ \(message)")
    }
}
