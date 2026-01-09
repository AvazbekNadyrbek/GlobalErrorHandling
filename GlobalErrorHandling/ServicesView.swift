//
//  ServicesView.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/5/26.
//

import SwiftUI

struct ServiceView: View {
    
    // 🎯 Получаем глобальный обработчик ошибок
    @Environment(\.showError) private var showError
    
    // Подключаем наш "Мозг"
    @StateObject private var viewModel = ServicesViewModel()
    
    // Отслеживаем, была ли первая загрузка
    @State private var hasLoadedOnce = false
    
    var body: some View {
        NavigationStack {
            
            VStack(spacing: 0) {
                List {
                    Section {
                        NewsCarouselView()
                            .listRowInsets(EdgeInsets())
                            .background(Color.clear)
                    } header: {
                        Text("Новости").font(.title2).bold()
                    }
                    Section {
                        ForEach(viewModel.services, id: \.id) { service in
                            ServiceRowView(service: service)
                        }
                    }
                }
                .listStyle(.grouped)

                // Контент
                Group {
                    if viewModel.isLoading && !hasLoadedOnce {
                        // Показываем спиннер только при первой загрузке
                        VStack {
                            Spacer()
                            ProgressView("Загрузка прайса...")
                            Spacer()
                        }
                    } else if viewModel.services.isEmpty && !viewModel.isLoading {
                        // Пустой список
                        ContentUnavailableView(
                            "Нет услуг",
                            systemImage: "list.bullet.clipboard",
                            description: Text("Список услуг пуст или сервер недоступен")
                        )
                    } else {
                        // СПИСОК УСЛУГ
                        List(viewModel.services, id: \.id) { service in
                            ServiceRowView(service: service)
                        }
                        .listStyle(.plain)
                        // Pull to refresh
                        .refreshable {
                            await refreshServices()
                        }
                    }
                }
                
                
            }
            .navigationTitle("Прайс-лист Отца")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Выйти") {  }
                    Button {
                        Task {
                            await refreshServices()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
                
                // 👇 Временная кнопка для теста
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // Сохраняем тестовый токен
                        AuthService.shared.saveToken("test-jwt-token-12345")
                        
                        // Перезагружаем
                        Task {
                            await viewModel.refresh()
                        }
                    } label: {
                        Label("Тест токена", systemImage: "key.fill")
                    }
                }
            }
            // Загружаем только один раз при открытии
            .task {
                guard !hasLoadedOnce else { return }
                
                // 🎯 Устанавливаем обработчик ошибок ДО загрузки
                viewModel.setErrorHandler { apiError in
                    // Используем глобальный error handler
                    showError(apiError, apiError.recoverySuggestion ?? "Попробуйте снова")
                }
                
                await loadInitialData()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Первая загрузка данных
    private func loadInitialData() async {
        await viewModel.loadServices()
        hasLoadedOnce = true
    }
    
    /// Обновление списка (refresh)
    private func refreshServices() async {
        // Добавляем небольшую задержку, чтобы не было конфликта
        try? await Task.sleep(for: .milliseconds(100))
        await viewModel.loadServices()
    }
}

// MARK: - ServiceRowView

struct ServiceRowView: View {
    let service: Components.Schemas.ServiceResponse
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Иконка
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(service.name ?? "Услуга")
                    .font(.headline)
                
                if let description = service.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 16) {
                    if let duration = service.durationMinutes {
                        Label("\(duration) мин", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let id = service.id {
                        Label("ID: \(id)", systemImage: "number")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Цена
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(service.price ?? 0, specifier: "%.0f")")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                Text("сом")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    ServiceView()
        .modifier(ErrorModifier()) // 👈 Добавляем для Preview
}
