//
//  AuthViewModel.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/5/26.
//

import Foundation
import SwiftUI
import OpenAPIURLSession
import OpenAPIRuntime
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Состояние авторизации
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var role: String? = nil
    
    // MARK: - Private Properties
    
    private let client: Client
    private var onError: ((APIError) -> Void)?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(client: Client? = nil) {
        if let client = client {
            self.client = client
        } else {
            self.client = ClientFactory.createClient()
        }
        
        checkLoginStatus()
        loadSavedRole()
        setupUnauthorizedListener()
    }
    
    // MARK: - Public Methods
    
    /// Устанавливает обработчик ошибок
    func setErrorHandler(_ handler: @escaping (APIError) -> Void) {
        self.onError = handler
    }
    
    /// Проверка: есть ли сохранённый токен?
    func checkLoginStatus() {
        isAuthenticated = AuthService.shared.isAuthenticated
        loadSavedRole()
    }
    
    /// ВХОД (Login)
    /// Spring: @Operation(operationId = "authenticate")
    /// Swift: client.authenticate()
    func login(phone: String, password: String) async {
        isLoading = true
        
        do {
            // Создаем тело запроса
            let body = Components.Schemas.AuthenticationRequest(
                phone: phone,
                password: password
            )
            
            // 👇 Используем метод authenticate (из operationId)
            let response = try await client.authenticate(body: .json(body))
            
            switch response {
            case .ok(let okResponse):
                // Теперь с produces = "application/json" будет .json case!
                switch okResponse.body {
                case .json(let authResponse):
                    if let token = authResponse.token {
                        let userRole = authResponse.role?.rawValue ?? "CLIENT"
                        AuthService.shared.saveCredentials(token: token, role: userRole)
                        role = userRole
                        isAuthenticated = true
                        print("✅ Успешный вход! Токен сохранен.")
                    } else {
                        onError?(APIError.unknown("Токен не получен от сервера"))
                    }
                }
                
            case .undocumented(statusCode: let code, _):
                let error = APIError.serverError(statusCode: code)
                onError?(error)
                print("❌ Ошибка входа: \(code)")
            }
            
        } catch {
            let apiError = APIError.networkError(underlying: error)
            onError?(apiError)
            print("❌ Ошибка сети при входе: \(error)")
        }
        
        isLoading = false
    }
    
    /// РЕГИСТРАЦИЯ (Register)
    /// Spring: @Operation(operationId = "register")
    /// Swift: client.register()
    func register(phone: String, name: String, password: String) async {
        isLoading = true
        
        do {
            // Создаем тело запроса для регистрации
            let body = Components.Schemas.RegisterRequest(
                phone: phone,
                name: name,
                password: password
            )
            
            let response = try await client.register(body: .json(body))
            
            switch response {
            case .ok(let okResponse):
                // С produces = "application/json" будет .json case
                switch okResponse.body {
                case .json(let authResponse):
                    if let token = authResponse.token, let role = authResponse.role {
                        AuthService.shared.saveCredentials(token: token, role: role.rawValue)
                        isAuthenticated = true
                        print("✅ Успешная регистрация! Токен сохранен.")
                    } else {
                        onError?(APIError.unknown("Токен не получен от сервера"))
                    }
                }
                
            case .undocumented(statusCode: let code, _):
                let error = APIError.serverError(statusCode: code)
                onError?(error)
                print("❌ Ошибка регистрации: \(code)")
            }
            
        } catch {
            let apiError = APIError.networkError(underlying: error)
            onError?(apiError)
            print("❌ Ошибка сети при регистрации: \(error)")
        }
        
        isLoading = false
    }
    
    /// ВЫХОД (Logout)
    func logout() {
        AuthService.shared.logout()
        self.role = nil
        isAuthenticated = false
        print("🔓 Выход выполнен")
    }
    
    // MARK: - Helper Methods
    
    /// Подписка на 401 Unauthorized (истёк токен)
    private func setupUnauthorizedListener() {
        NotificationCenter.default.publisher(for: .unauthorizedError)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.logout()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Загружает сохранённую из UserDefaults роль пользователя
    func loadSavedRole() {
        role = UserDefaults.standard.string(forKey: "user_role")
    }
    
    /// Извлекает сообщение об ошибке из тела ответа
    private func extractErrorMessage(from body: HTTPBody?) async -> String {
        guard let body = body else {
            return "Нет тела ответа"
        }
        
        do {
            let data = try await Data(collecting: body, upTo: 1024 * 1024) // Максимум 1MB
            if let jsonString = String(data: data, encoding: .utf8) {
                return jsonString
            }
            return "Не удалось декодировать тело ответа"
        } catch {
            return "Ошибка чтения тела: \(error.localizedDescription)"
        }
    }
}
