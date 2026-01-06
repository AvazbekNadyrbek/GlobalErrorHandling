//
//  AuthService.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/5/26.
//

import Foundation

/// Сервис для управления JWT токенами
final class AuthService {
    
    // MARK: - Singleton
    
    static let shared = AuthService()
    private init() {}
    
    // MARK: - Constants
    
    private let tokenKey = "jwt_token"
    private let roleKey = "user_role"
    
    // MARK: - Public Properties
    
    /// Проверяет, авторизован ли пользователь
    var isAuthenticated: Bool {
        token != nil
    }
    
    /// Проверка, является ли пользователь администратором
    var isAdmin: Bool {
        let role = UserDefaults.standard.string(forKey: roleKey)
        return role == "ADMIN"
    }
    
    /// Текущий токен (если есть)
    var token: String? {
        get {
            UserDefaults.standard.string(forKey: tokenKey)
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: tokenKey)
                print("🔐 AuthService: Токен сохранён")
            } else {
                UserDefaults.standard.removeObject(forKey: tokenKey)
                print("🔓 AuthService: Токен удалён")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Сохраняет токен и роль пользователя после успешной авторизации
    /// - Parameters:
    ///   - token: JWT токен
    ///   - role: Роль пользователя (например, "ADMIN" или "USER")
    func saveCredentials(token: String, role: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(role, forKey: roleKey)
        print("🔐 AuthService: Сохранены токен и роль: \(role)")
    }
    
    /// Сохраняет только токен (для обратной совместимости)
    /// - Parameter token: JWT токен
    func saveToken(_ token: String) {
        self.token = token
    }
    
    /// Удаляет токен и роль (выход из системы)
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: roleKey)
        print("🔓 AuthService: Пользователь вышел из системы")
    }
}