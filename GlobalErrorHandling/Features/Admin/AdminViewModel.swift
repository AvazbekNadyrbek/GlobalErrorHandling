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

@MainActor
final class AdminViewModel: ObservableObject {
    
    // MARK: - Published state
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date()

    @Published var appointments: [Components.Schemas.AppointmentDetailResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties

    /// Группировка записей по дням
    var groupedAppointments: [Date: [Components.Schemas.AppointmentDetailResponse]] {
        Dictionary(grouping: appointments) { appointment in
            guard let startTime = appointment.startTime else { return Date() }
            return Calendar.current.startOfDay(for: startTime)
        }
    }

    /// Отсортированные дни для отображения секций
    var sortedDays: [Date] {
        Array(groupedAppointments.keys).sorted()
    }
    
    // MARK: - Private
    private let client: Client
    private var loadTask: Task<Void, Never>?
    
    private let queryDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX") // Надежно!
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // MARK: - Lifecycle
    init(client: Client = ClientFactory.createClient()) {
        self.client = client
    }
    
    deinit {
        // Корректная отмена активной задачи
        loadTask?.cancel()
    }
    
    // MARK: - Public API
    
    /// Загружает список записей (на день или диапазон).
    func loadAppointments() async {
        // отменяем возможную старую задачу
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.loadAppointmentsInternal()
        }
    }
    
    // MARK: - Call Client
    
    @MainActor
    private func loadAppointmentsInternal() async {
        isLoading = true
        errorMessage = nil
        appointments = []
        
        defer { isLoading = false }
        
        let startString = queryDateFormatter.string(from: startDate)
        let endString = queryDateFormatter.string(from: endDate)
        
        do {
            let response = try await client.getAdminAppointments(
                query: .init(startDate: startString, endDate: endString)
            )
            
            guard !Task.isCancelled else { return }
            
            // Ответ API
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let items):
                    // ➡️ сортировка по времени старта (или любая твоя)
                    appointments = items.sorted { 
                        guard let time1 = $0.startTime, let time2 = $1.startTime else { return false }
                        return time1 < time2
                    }
                }
            case .undocumented(statusCode: let code, _):
                errorMessage = "Ошибка сервера: \(code)"
            }
        } catch {
            if (error as NSError).code == NSURLErrorCancelled { return }
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - callClient: вызов по номеру (осталась как есть)
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
    
    private func cleanPhoneNumber(_ phone: String) -> String {
        let hasPlus = phone.hasPrefix("+")
        let digitsOnly = phone.filter { $0.isNumber }
        return hasPlus ? "+\(digitsOnly)" : digitsOnly
    }
}