//
//  NewsEntity+Identifiable.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/8/26.
//

import Foundation

extension Components.Schemas.NewsEntity: Identifiable {
    // OpenAPI уже генерирует свойство id: Int64?
    // Но для Identifiable нужен non-optional id
    public var safeId: Int64 {
        return id ?? 0
    }
}