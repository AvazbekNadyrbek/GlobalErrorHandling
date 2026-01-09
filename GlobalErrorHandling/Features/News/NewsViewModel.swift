//
//  NewsViewModel.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/8/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class NewsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var news: [Components.Schemas.NewsEntity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let client = ClientFactory.createClient()
    private var activeTasks: [String: Task<Void, Never>] = [:]
    
    // MARK: - Task Management
    private func performTask(id: String, operation: @escaping () async -> Void) async {
        activeTasks[id]?.cancel()
        let task = Task { await operation() }
        activeTasks[id] = task
        await task.value
        activeTasks.removeValue(forKey: id)
    }
    
    // MARK: - Data Loading
    func loadNews(force: Bool = false) async {
        await performTask(id: "loadNews") { [weak self] in
            guard let self = self else { return }
            guard !self.isLoading || force else { return }
            
            self.isLoading = true
            self.errorMessage = nil
            
            defer {
                self.isLoading = false
            }
            
            do {
                let response = try await self.client.getNews()
                
                guard !Task.isCancelled else { return }
                
                switch response {
                case .ok(let okResponse):
                    switch okResponse.body {
                    case .json(let list):
                        self.news = list
                    }
                    
                case .undocumented(statusCode: let code, _):
                    self.errorMessage = "Ошибка сервера: \(code)"
                }
                
            } catch {
                guard !Task.isCancelled else { return }
                
                if (error as NSError).code != NSURLErrorCancelled {
                    self.errorMessage = "Ошибка загрузки новостей: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}