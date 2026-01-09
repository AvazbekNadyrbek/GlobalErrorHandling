import Foundation
import SwiftUI
import OpenAPIURLSession
import OpenAPIRuntime
import Combine

@MainActor
class BookingViewModel: ObservableObject {
    
    // MARK: - Properties
    let serviceId: Int64
    let serviceName: String
    
    @Published var selectedDate: Date = Date()
    @Published var timeSlots: [Components.Schemas.TimeSlotResponse] = []
    
    // Индекс выбранного слота
    @Published var selectedSlotIndex: Int?
    
    // Состояния UI
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    
    private let client: Client
    
    // MARK: - Init
    init(serviceId: Int64, serviceName: String) {
        self.serviceId = serviceId
        self.serviceName = serviceName
        self.client = ClientFactory.createClient()
    }
    
    // MARK: - Methods
    
    func selectSlot(at index: Int) {
        selectedSlotIndex = index
    }
    
    // Загрузка слотов (GET)
    func loadSlots() async {
        isLoading = true
        errorMessage = nil
        timeSlots = []
        selectedSlotIndex = nil
        
        do {
            let dateString = formatDateForServer(selectedDate)
            
            let response = try await client.getSlots(
                query: .init(date: dateString, serviceId: serviceId)
            )
            
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let slots):
                    withAnimation {
                        self.timeSlots = slots
                    }
                }
            case .undocumented(statusCode: let code, _):
                errorMessage = "Ошибка сервера: \(code)"
            }
            
        } catch {
            errorMessage = "Ошибка сети: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Создание бронирования (POST)
    func bookAppointment() async -> Bool {
        guard let index = selectedSlotIndex, index < timeSlots.count else {
            errorMessage = "Пожалуйста, выберите время"
            showErrorAlert = true
            return false
        }
        
        let slot = timeSlots[index]
        
        guard slot.isAvailable == true else {
            errorMessage = "Это время уже занято"
            showErrorAlert = true
            return false
        }
        
        guard let startDate = combineDateAndTime(date: selectedDate, timeSlot: slot) else {
            errorMessage = "Ошибка формирования времени"
            showErrorAlert = true
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let body = Components.Schemas.CreateAppointmentRequest(
                serviceId: serviceId,
                startTime: startDate
            )
            
            let response = try await client.createBooking(body: .json(body))
            
            isLoading = false
            
            switch response {
            case .ok:
                showSuccessAlert = true
                return true
                
            case .undocumented(statusCode: let code, let payload):
                let errorText = await extractErrorMessage(from: payload.body)
                
                if !errorText.isEmpty {
                    errorMessage = errorText
                } else {
                    errorMessage = "Ошибка сервера (код \(code))"
                }
                
                showErrorAlert = true
                
                if code == 400 || code == 409 {
                    await loadSlots()
                }
                return false
            }
            
        } catch {
            errorMessage = "Ошибка сети: \(error.localizedDescription)"
            showErrorAlert = true
            isLoading = false
            return false
        }
    }
    
    // MARK: - Helpers
    
    // Чтение тела ошибки
    private func extractErrorMessage(from body: OpenAPIRuntime.HTTPBody?) async -> String {
        guard let body = body else { return "" }
        do {
            let data = try await Data(collecting: body, upTo: 1024)
            // Пытаемся найти JSON {"error": "message"}
            if let json = try? JSONDecoder().decode([String: String].self, from: data),
               let msg = json["error"] {
                return msg
            }
            // Иначе возвращаем как текст
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
    
    // Дата для URL Query (yyyy-MM-dd)
    private func formatDateForServer(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    // Слияние даты из календаря и времени из слота
    private func combineDateAndTime(date: Date, timeSlot: Components.Schemas.TimeSlotResponse) -> Date? {
        guard let timeDetail = timeSlot.time else { return nil }
        
        var calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = Int(timeDetail.hour ?? 0)
        components.minute = Int(timeDetail.minute ?? 0)
        components.second = 0
        
        return calendar.date(from: components)
    }
}