//
//  BookingListViewModel.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/5/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class BookingListViewModel: ObservableObject {
    
    @Published var bookings: [AppointmentItem] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    
    private let client = ClientFactory.createClient()
    private var loadTask: Task<Void, Never>?
    
    func loadBookings(isRefresh: Bool = false) async {
        if isRefresh {
            guard !isRefreshing else { return }
            isRefreshing = true
        } else {
            guard !isLoading else { return }
            isLoading = true
        }
        
        loadTask?.cancel()
        
        loadTask = Task {
            errorMessage = nil
            
            do {
                let response = try await client.getMyAppointments()
                
                guard !Task.isCancelled else { return }
                
                switch response {
                case .ok(let okResponse):
                    switch okResponse.body {
                    case .json(let appointments):
                        // Сортируем по ID (последние добавленные = больший ID)
                        let sortedBookings = appointments
                            .map { AppointmentItem(from: $0) }
                            .sorted { $0.startTime > $1.startTime } 
                        
                        self.bookings = sortedBookings
                    }
                    
                case .undocumented(statusCode: let code, _):
                    if !isRefresh {
                        errorMessage = "Ошибка сервера: \(code)"
                    }
                    print("❌ HTTP \(code)")
                }
                
            } catch is CancellationError {
                print("⚠️ Запрос отменён")
            } catch {
                if !isRefresh {
                    errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
                }
                print("❌ Error: \(error)")
            }
            
            if isRefresh {
                isRefreshing = false
            } else {
                isLoading = false
            }
        }
        
        await loadTask?.value
    }
    
    func cancelBooking(_ booking: AppointmentItem) async {
        // TODO: Добавить API метод для отмены записи
        print("🗑️ Отменить запись #\(booking.id)")
        
        // Пока просто удаляем из списка
        bookings.removeAll { $0.id == booking.id }
    }
}

// MARK: - Model

struct AppointmentItem: Identifiable {
    let id: Int64
    let serviceName: String
    let startTime: Date
    let status: String
    let notes: String?
    
    init(from response: Components.Schemas.AppointmentDetailResponse) {
        self.id = response.id ?? 0
        self.serviceName = response.serviceName ?? "Неизвестная услуга"
        self.status = response.status?.rawValue ?? "PENDING"
        self.notes = response.comment
        // response.startTime — это уже Date (благодаря нашему транскодеру).
        // Просто берем его или ставим текущую дату, если nil.
        self.startTime = response.startTime ?? Date()
    }
}
