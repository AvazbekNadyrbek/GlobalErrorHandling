//
//  ShowErrorEnviromentKey.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 29.10.25.
//

import Foundation
import SwiftUI

// Protocol EnvironmentKey this is how we are creating custom EnviromentValues

// showError(Error, String)

struct ShowErrorAction {
    typealias Action = (Error, String) -> Void
    let action: Action
    func callAsFunction(_ error: Error, _ guidance: String) {
        action(error, guidance)
    }
}

struct ShowErrorEnviromentKey: EnvironmentKey {
    static var defaultValue: ShowErrorAction = ShowErrorAction { _ ,_ in }
}

extension EnvironmentValues {
    var showError: (ShowErrorAction) {
        get {self[ShowErrorEnviromentKey.self]}
        set {self[ShowErrorEnviromentKey.self] = newValue}
    }
}
