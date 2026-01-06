//
//  FatherTireShopApp.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 29.10.25.
//

import SwiftUI
import OpenAPIURLSession
import OpenAPIRuntime

@main
struct FatherTireShopApp: App {
    
    // MARK: - State
    
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var router: AppRouter
    // MARK: - Initialization
    
    init() {
        let client = ClientFactory.createClient()
        _authViewModel = StateObject(wrappedValue: AuthViewModel(client: client))
        _router = StateObject(wrappedValue: AppRouter()) // <--- добавь эту строку
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(router)
                .modifier(ErrorModifier()) // 👈 Глобальный обработчик ошибок
        }
    }
    
//    // MARK: - Client Factory
//    
//    /// Создаёт настроенный API клиент с Middleware
//    static func createClient() -> Client {
//        #if targetEnvironment(simulator)
//        // На симуляторе используем localhost
//        let url = URL(string: "http://localhost:8080")!
//        #else
//        // На реальном устройстве используй IP твоего Mac
//        // Узнай свой IP: ifconfig | grep "inet " | grep -v 127.0.0.1
//        let url = URL(string: "http://192.168.1.100:8080")! // 👈 Замени на свой IP
//        #endif
//        
//        let transport = URLSessionTransport()
//        let middleware = AuthenticationMiddleware()
//        
//        return Client(
//            serverURL: url,
//            transport: transport,
//            middlewares: [middleware]
//        )
//    }
}
