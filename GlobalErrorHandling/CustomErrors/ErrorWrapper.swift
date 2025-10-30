//
//  ErrorWrapper.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 29.10.25.
//

import Foundation

struct ErrorWrapper: Identifiable {
    let id: UUID = UUID()
    let error: Error
    let guidance: String
}
