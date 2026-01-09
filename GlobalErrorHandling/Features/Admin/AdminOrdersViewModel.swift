//
//  AdminOrdersViewModel.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/8/26.
//

import Foundation
import SwiftUI
import OpenAPIURLSession
import OpenAPIRuntime
import Combine


@MainActor
final class AdminOrdersViewModel: ObservableObject {
    
    @Published var orders: [Components.Schemas.AdminOrderResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let client = ClientFactory.createClient()
    
    func loadOrders() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await client.getAdminOrders()
            
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let list):
                    self.orders = list
                }
            case .undocumented(statusCode: let code, _):
                errorMessage = "Ошибка сервера: \(code)"
            }
        } catch {
            errorMessage = "Ошибка сети: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Функция звонка (копируем из BookingViewModel или выносим в утилиты)
    func callClient(phone: String?) {
        guard let phone = phone else { return }
        let clean = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://+\(clean)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
