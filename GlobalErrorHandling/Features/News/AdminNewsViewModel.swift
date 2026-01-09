//
//  AdminNewsViewModel.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/9/26.
//

import Foundation
import SwiftUI
import OpenAPIURLSession
import OpenAPIRuntime
import Combine


@MainActor
final class AdminNewsViewModel: ObservableObject {
    
    // Поля ввода
    @Published var title: String = ""
    @Published var content: String = ""
    @Published var imageUrl: String = "" // Пока просто ссылка текстом
    
    @Published var isLoading = false
    @Published var showSuccess = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let client = ClientFactory.createClient()
    
    // Проверка валидности
    var isValid: Bool {
        !title.isEmpty && !content.isEmpty
    }
    
    func publishNews() async {
        guard isValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Создаем объект новости (DTO)
            // Структура сгенерирована Xcode на основе Swagger
            let newsItem = Components.Schemas.NewsEntity(
                title: title,
                content: content,
                imageUrl: imageUrl.isEmpty ? nil : imageUrl
            )
            
            // Отправляем POST запрос
            let response = try await client.createNews(body: .json(newsItem))
            
            switch response {
            case .ok:
                // Успех!
                showSuccess = true
                clearForm()
                
            case .undocumented(statusCode: let code, _):
                errorMessage = "Ошибка сервера: \(code)"
                showError = true
            }
            
        } catch {
            errorMessage = "Ошибка сети: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    private func clearForm() {
        title = ""
        content = ""
        imageUrl = ""
    }
}
