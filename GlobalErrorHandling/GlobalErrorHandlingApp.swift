//
//  GlobalErrorHandlingApp.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 29.10.25.
//

import SwiftUI

@main
struct GlobalErrorHandlingApp: App {
    
    @State private var errorWrapper: ErrorWrapper?
    
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }.environment(\.showError, ShowErrorAction(action: showError))
                .overlay(alignment: .bottom) {
                    errorWrapper != nil ? ErrorView(errorWrapper: $errorWrapper) :  nil
                }
//            .sheet(item: $errorWrapper) { errorWrapper in
//                    Text(errorWrapper.guidance)
//            }
        }
    }
    
    private func showError( error: Error, guidence: String) {
        errorWrapper = ErrorWrapper(error: error, guidance: guidence)
    }
}
