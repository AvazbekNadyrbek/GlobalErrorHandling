//
//  AdminDashboardView.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/6/26.
//

import SwiftUI

struct AdminDashboardView: View {
    
    @StateObject private var viewModel = AdminViewModel()
    @Environment(\.showError) private var showError
    @State private var showingCreateNews = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. ВЫБОР ДИАПАЗОНА
            rangePickerSection
            
            // 2. СПИСОК
            contentSection
        }
        .navigationTitle("Кабинет Отца 🛠️")
        .background(Color(uiColor: .systemGroupedBackground))
        .task {
            // При старте грузим только сегодня
            await viewModel.loadAppointments()
        }
        .toolbar {
            // 👇 Кнопка добавления новости
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showingCreateNews = true
                }) {
                    Image(systemName: "megaphone.fill") // Иконка громкоговорителя
                        .foregroundColor(.blue)
                }
            }
        }
        // 👇 Открытие экрана
        .sheet(isPresented: $showingCreateNews) {
            AdminNewsCreateView()
        }
    }
    
    // Секция с двумя датами
    private var rangePickerSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Период:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                // ОТ
                VStack(alignment: .leading) {
                    Text("C")
                        .font(.caption)
                        .foregroundColor(.gray)
                    DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                        .labelsHidden()
                }
                
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                Spacer()
                
                // ДО
                VStack(alignment: .leading) {
                    Text("По")
                        .font(.caption)
                        .foregroundColor(.gray)
                    // Ограничиваем: Конец не может быть раньше начала
                    DatePicker("", selection: $viewModel.endDate, in: viewModel.startDate..., displayedComponents: .date)
                        .labelsHidden()
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        // Если даты меняются — грузим заново
        .onChange(of: viewModel.startDate) { refresh() }
        .onChange(of: viewModel.endDate) { refresh() }
    }
    
    private func refresh() {
        Task { await viewModel.loadAppointments() }
    }
    
    // Контент с секциями
    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isLoading {
            ProgressView("Загрузка...")
                .frame(maxHeight: .infinity)
        } else if viewModel.sortedDays.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("Нет записей в этот период")
                    .foregroundColor(.secondary)
            }
            .frame(maxHeight: .infinity)
        } else {
            List {
                // Пробегаем по дням (Секциям)
                ForEach(viewModel.sortedDays, id: \.self) { day in
                    Section(header: Text(formatSectionDate(day))) {
                        // Достаем записи для конкретного дня
                        if let dayAppointments = viewModel.groupedAppointments[day] {
                            // Сортируем внутри дня по времени
                            ForEach(dayAppointments.sorted { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) }, id: \.id) { appointment in
                                AppointmentCard(
                                    appointment: appointment,
                                    onCall: { viewModel.callClient(phone: $0) }
                                )
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable { await viewModel.loadAppointments() }
        }
    }
    
    // Красивая дата для заголовка (например: "15 Января, Среда")
    private func formatSectionDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM, EEEE" // День Месяц, ДеньНедели
        f.locale = Locale(identifier: "ru_RU")
        return f.string(from: date).capitalized
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
