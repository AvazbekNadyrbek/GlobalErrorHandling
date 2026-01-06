//
//  AdminDashboardView.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/6/26.
//

import SwiftUI

/// Административная панель для просмотра и управления записями клиентов
/// Позволяет фильтровать по дате и звонить клиентам напрямую
struct AdminDashboardView: View {
    
    @StateObject private var viewModel = AdminViewModel()

    // MARK: - Глобальная система обработки ошибок
    @Environment(\.showError) private var showError
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Date Picker Section
                datePickerSection
                
                // MARK: - Content Section
                contentSection
            }
            .navigationTitle("Кабинет Отца 🛠️")
            .task {
                await loadAppointmentsWithErrorHandling()
            }
        }
    }
    
    // MARK: - View Components
    
    /// Секция выбора даты
    private var datePickerSection: some View {
        DatePicker(
            "Дата",
            selection: $viewModel.selectedDate,
            displayedComponents: .date
        )
        .datePickerStyle(.compact)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .onChange(of: viewModel.selectedDate) {
            // Новый синтаксис onChange - без параметров
            Task {
                await loadAppointmentsWithErrorHandling()
            }
        }
    }
    
    /// Основной контент в зависимости от состояния
    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.appointments.isEmpty {
            emptyStateView
        } else {
            appointmentsList
        }
    }
    
    /// Индикатор загрузки
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Загрузка расписания...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Пустое состояние (нет записей)
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("На этот день записей нет")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text(formattedSelectedDate)
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Список записей
    private var appointmentsList: some View {
        List(viewModel.appointments, id: \.id) { appointment in
            AppointmentCard(
                appointment: appointment,
                onCall: { phone in
                    viewModel.callClient(phone: phone)
                }
            )
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .refreshable {
            await loadAppointmentsWithErrorHandling()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Загружает записи с глобальной обработкой ошибок через Environment
    private func loadAppointmentsWithErrorHandling() async {
        do {
            try await viewModel.loadAppointments()
        } catch let apiError as APIError {
            // Используем глобальную систему обработки ошибок
            // APIError уже содержит errorDescription и recoverySuggestion
            showError(
                apiError,
                apiError.recoverySuggestion ?? "Попробуйте снова"
            )
        } catch {
            // На случай других неожиданных ошибок
            showError(
                error,
                "Произошла неожиданная ошибка"
            )
        }
    }
    
    /// Форматированная выбранная дата для отображения
    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: viewModel.selectedDate)
    }
}

// MARK: - Appointment Card Component

/// Карточка отдельной записи клиента
/// Отображает время, статус, информацию о клиенте и кнопку звонка
struct AppointmentCard: View {
    let appointment: Components.Schemas.AppointmentDetailResponse
    let onCall: (String?) -> Void
    
    // Статический форматтер времени (создается один раз для всех карточек)
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            
            Divider()
            
            contentSection
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Card Sections
    
    /// Заголовок карточки (время и статус)
    private var headerSection: some View {
        HStack {
            // Время начала
            Label(
                formatTime(appointment.startTime),
                systemImage: "clock.fill"
            )
            .font(.headline)
            .foregroundColor(.blue)
            
            Spacer()
            
            // Статус
            statusBadge
        }
    }
    
    /// Бейдж статуса с цветовой индикацией
    private var statusBadge: some View {
        let status = appointment.status?.rawValue ?? "N/A"
        let backgroundColor = statusColor(for: appointment.status)
        
        return Text(status)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundColor.opacity(0.2))
            .foregroundColor(backgroundColor)
            .cornerRadius(8)
    }
    
    /// Основной контент карточки
    private var contentSection: some View {
        HStack(alignment: .top, spacing: 12) {
            clientInfoSection
            
            Spacer()
            
            callButton
        }
    }
    
    /// Информация о клиенте и услуге
    private var clientInfoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Название услуги
            Text(appointment.serviceName ?? "Услуга не указана")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Имя клиента
            Label(
                appointment.clientName ?? "Клиент",
                systemImage: "person.fill"
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            // Комментарий (если есть)
            if let comment = appointment.comment,
               !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                commentView(comment)
            }
        }
    }
    
    /// Отображение комментария
    private func commentView(_ comment: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Image(systemName: "bubble.left.fill")
                .font(.caption2)
                .foregroundColor(.orange)
            
            Text(comment)
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(.top, 2)
    }
    
    /// Кнопка для звонка клиенту
    private var callButton: some View {
        Button(action: {
            onCall(appointment.clientPhone)
        }) {
            ZStack {
                Circle()
                    .fill(Color.green.gradient)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "phone.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Methods
    
    /// Форматирует время для отображения
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "--:--" }
        return Self.timeFormatter.string(from: date)
    }
    
    /// Определяет цвет для статуса
    private func statusColor(for status: Components.Schemas.AppointmentDetailResponse.statusPayload?) -> Color {
        guard let status = status else { return .gray }
        
        switch status {
        case .PENDING:
            return .orange
        case .CONFIRMED:
            return .green
        case .CANCELLED:
            return .red
        case .COMPLETED:
            return .blue
        }
    }
}

// MARK: - Preview

#Preview {
    AdminDashboardView()
}
