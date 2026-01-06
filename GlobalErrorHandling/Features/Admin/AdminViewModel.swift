//
//  AdminViewModel.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/6/26.
//

import Foundation
import SwiftUI
import OpenAPIURLSession
import OpenAPIRuntime
import Combine

/// ViewModel для управления административной панелью бронирований
/// Следует MVVM паттерну и использует async/await для асинхронных операций
@MainActor
final class AdminViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Выбранная дата для фильтрации записей (по умолчанию сегодня)
    @Published var selectedDate: Date = Date()
    
    /// Список записей на выбранную дату
    @Published var appointments: [Components.Schemas.AppointmentDetailResponse] = []
    
    /// Индикатор загрузки данных
    @Published var isLoading = false
    
    // MARK: - Private Properties
    
    private let client: Client
    
    /// Задача загрузки для возможности отмены
    private var loadTask: Task<Void, Error>?
    
    /// Форматтер для конвертации даты в формат API (yyyy-MM-dd)
    /// Создается один раз для оптимизации производительности
    private let queryDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX") // Предотвращает проблемы с локализацией
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // MARK: - Initialization
    
    /// Инициализация с возможностью dependency injection для тестирования
    /// - Parameter client: API клиент (по умолчанию использует фабрику)
    init(client: Client = ClientFactory.createClient()) {
        self.client = client
    }
    
    // MARK: - Public Methods
    
    /// Загружает список записей для выбранной даты
    /// Автоматически отменяет предыдущую загрузку если она еще выполняется
    /// - Throws: APIError при ошибках сети или сервера
    func loadAppointments() async throws {
        // Отменяем предыдущую загрузку, если она еще выполняется
        loadTask?.cancel()
        
        loadTask = Task {
            try await performLoadAppointments()
        }
        
        // Ждем завершения задачи и пробрасываем ошибку если есть
        try await loadTask?.value
    }
    
    /// Инициирует телефонный звонок клиенту
    /// - Parameter phone: Номер телефона в любом формате
    /// - Note: Автоматически очищает номер от лишних символов, сохраняя '+' и цифры
    func callClient(phone: String?) {
        guard let phone = phone?.trimmingCharacters(in: .whitespacesAndNewlines),
              !phone.isEmpty else {
            print("⚠️ Номер телефона пустой")
            return
        }
        
        let cleanPhone = cleanPhoneNumber(phone)
        
        guard let url = URL(string: "tel://\(cleanPhone)"),
              UIApplication.shared.canOpenURL(url) else {
            print("⚠️ Не удалось создать URL для звонка: \(phone)")
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    // MARK: - Private Methods
    
    /// Выполняет загрузку записей с обработкой ошибок
    /// - Throws: APIError с детальным описанием проблемы
    private func performLoadAppointments() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Очищаем список перед загрузкой для лучшего UX
        appointments = []
        
        do {
            let dateString = queryDateFormatter.string(from: selectedDate)
            
            let response = try await client.getAdminAppointments(
                query: .init(date: dateString)
            )
            
            // Проверяем, не была ли задача отменена
            guard !Task.isCancelled else {
                throw APIError.cancelled
            }
            
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let appointmentsList):
                    // Сортируем по времени начала: самые ранние записи сверху
                    self.appointments = appointmentsList.sorted { first, second in
                        guard let firstTime = first.startTime,
                              let secondTime = second.startTime else {
                            // Если у одной из записей нет времени, она идет в конец
                            return first.startTime != nil
                        }
                        return firstTime < secondTime
                    }
                }
                
            case .undocumented(statusCode: let code, _):
                // Пробрасываем типизированную ошибку
                throw APIError.serverError(statusCode: code)
            }
            
        } catch let apiError as APIError {
            // Уже типизированная ошибка - пробрасываем дальше
            throw apiError
            
        } catch {
            // Оборачиваем неизвестные ошибки в APIError
            if (error as NSError).code == NSURLErrorCancelled {
                throw APIError.cancelled
            }
            throw APIError.networkError(underlying: error)
        }
    }
    
    /// Очищает номер телефона от лишних символов
    /// - Parameter phone: Исходный номер телефона
    /// - Returns: Номер с только цифрами и '+' в начале (если был)
    private func cleanPhoneNumber(_ phone: String) -> String {
        let hasPlus = phone.hasPrefix("+")
        
        // Оставляем только цифры
        let digitsOnly = phone.filter { $0.isNumber }
        
        // Добавляем '+' обратно если был
        return hasPlus ? "+\(digitsOnly)" : digitsOnly
    }
    
    // MARK: - Deinitialization
    
    deinit {
        // Отменяем активные задачи при деинициализации
        loadTask?.cancel()
    }
}
