//
//  Route.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/5/26.
//

import Foundation

/// Все возможные маршруты в приложении
enum Route: Hashable {
    // MARK: - Services
    case servicesList
    case serviceDetail(id: Int64)
    
    // MARK: - Booking
    case bookingList
    case timeSlotPicker(date: Date, serviceId: Int64)
    
    // MARK: - Inventory
    case tireList
    case tireDetail(id: Int64)
    case tireFilter
    
    // MARK: - Profile
    case profile
    case settings
    case admin
}

// MARK: - Route Metadata

extension Route {
    /// Название экрана для навигации
    var title: String {
        switch self {
        case .servicesList:
            return "Услуги"
        case .serviceDetail:
            return "Детали услуги"
        case .bookingList:
            return "Мои записи"
        case .timeSlotPicker:
            return "Выбор времени"
        case .tireList:
            return "Каталог шин"
        case .tireDetail:
            return "Детали шины"
        case .tireFilter:
            return "Фильтры"
        case .profile:
            return "Профиль"
        case .settings:
            return "Настройки"
        case .admin:
            return "Админка"
        }
    }
}
