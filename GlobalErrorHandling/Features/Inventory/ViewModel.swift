//
//  ViewModel.swift
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
final class TireShopViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var tires: [Components.Schemas.TireResponse] = []
    @Published var filteredTires: [Components.Schemas.TireResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Success feedback
    @Published var showSuccessAlert = false
    @Published var lastPurchasedItemName = ""
    
    // Filter properties
    @Published var selectedSeason: Components.Schemas.TireResponse.seasonPayload?
    @Published var minPrice: Double = 0
    @Published var maxPrice: Double = 100000
    @Published var searchText: String = ""
    @Published var selectedBrands: Set<String> = []
    
    // Computed properties
    var availableBrands: [String] {
        let brands = Set(tires.compactMap { $0.brand })
        return brands.sorted()
    }
    
    var priceRange: ClosedRange<Double> {
        let prices = tires.compactMap { $0.price }
        guard !prices.isEmpty else { return 0...100000 }
        let min = prices.min() ?? 0
        let max = prices.max() ?? 100000
        return min...max
    }
    
    private let client = ClientFactory.createClient()
    private var cancellables = Set<AnyCancellable>()
    
    // Task management
    private var loadTask: Task<Void, Never>?
    
    // MARK: - Task Management
    
    private var activeTasks: [String: Task<Void, Never>] = [:]
    
    /// Выполняет задачу с автоматической отменой предыдущей
      private func performTask(
          id: String,
          operation: @escaping () async -> Void
      ) async {
          // Отменяем предыдущую задачу с таким же ID
          activeTasks[id]?.cancel()
          
          // Создаём новую задачу
          let task = Task {
              await operation()
          }
          
          activeTasks[id] = task
          await task.value
          
          // Убираем из активных после завершения
          activeTasks.removeValue(forKey: id)
      }

    
    // MARK: - Initialization
    init() {
        setupFilterObservers()
    }
    
    // MARK: - Setup
    private func setupFilterObservers() {
        // Наблюдаем за изменениями фильтров и автоматически применяем их
        Publishers.CombineLatest4(
            $selectedSeason,
            $searchText,
            $selectedBrands,
            Publishers.CombineLatest($minPrice, $maxPrice)
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _, _, _, _ in
            self?.applyFilters()
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    func loadTires(force: Bool = false) async {
        await performTask(id: "loadTires") { [weak self] in
            guard let self = self else { return }
            guard !self.isLoading || force else { return }
            
            self.isLoading = true
            self.errorMessage = nil
            
            defer {
                self.isLoading = false
            }
            
            do {
                let response = try await self.client.getAllTires()
                
                guard !Task.isCancelled else { return }
                
                switch response {
                case .ok(let okResponse):
                    switch okResponse.body {
                    case .json(let list):
                        self.tires = list
                        self.applyFilters()
                    }
                case .undocumented(statusCode: let code, _):
                    self.errorMessage = "Ошибка сервера: \(code)"
                }
                
            } catch {
                guard !Task.isCancelled else { return }
                
                if (error as NSError).code != NSURLErrorCancelled {
                    self.errorMessage = "Ошибка сети: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Filtering
    private func applyFilters() {
        var result = tires
        
        // Фильтр по сезону
        if let season = selectedSeason {
            result = result.filter { $0.season == season }
        }
        
        // Фильтр по цене
        result = result.filter { tire in
            guard let price = tire.price else { return false }
            return price >= minPrice && price <= maxPrice
        }
        
        // Фильтр по брендам
        if !selectedBrands.isEmpty {
            result = result.filter { tire in
                guard let brand = tire.brand else { return false }
                return selectedBrands.contains(brand)
            }
        }
        
        // Поиск по названию
        if !searchText.isEmpty {
            result = result.filter { tire in
                let brand = tire.brand?.lowercased() ?? ""
                let model = tire.model?.lowercased() ?? ""
                let size = tire.size?.lowercased() ?? ""
                let query = searchText.lowercased()
                
                return brand.contains(query) || 
                       model.contains(query) || 
                       size.contains(query)
            }
        }
        
        filteredTires = result
    }
    
    func resetFilters() {
        selectedSeason = nil
        minPrice = priceRange.lowerBound
        maxPrice = priceRange.upperBound
        searchText = ""
        selectedBrands.removeAll()
        applyFilters()
    }
    
    // MARK: - Purchase Logic
    /// Покупаем комплект шин (4 штуки)
    func buyTires(tire: Components.Schemas.TireResponse) async {
        guard let id = tire.id else {
            errorMessage = "Неверный идентификатор товара"
            return
        }
        
        // Оптимистичная проверка
        if (tire.stockQuantity ?? 0) < 4 {
            errorMessage = "Недостаточно товара на складе (нужно минимум 4 шт. для комплекта)"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // OpenAPI forces dictionary keys to be strings in JSON
            // Convert Int64 id to String key
            let itemsPayload = Components.Schemas.CreateOrderRequest.itemsPayload(
                additionalProperties: ["\(id)": 4]
            )
            
            let request = Components.Schemas.CreateOrderRequest(items: itemsPayload)
            
            let response = try await client.createOrder(body: .json(request))
            
            switch response {
            case .ok(let okResponse):
                // Успешно создан заказ
                switch okResponse.body {
                case .json(let orderId):
                    lastPurchasedItemName = "\(tire.brand ?? "Unknown") \(tire.model ?? "")"
                    showSuccessAlert = true
                    // Обновляем список для отображения актуального остатка
                    await loadTires()
                }
                
            case .undocumented(statusCode: let code, _):
                if code == 400 {
                    errorMessage = "Недостаточно товара на складе"
                } else {
                    errorMessage = "Не удалось создать заказ. Код ошибки: \(code)"
                }
            }
            
        } catch {
            errorMessage = "Ошибка при создании заказа: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    func getTireById(_ id: Int64) -> Components.Schemas.TireResponse? {
        return tires.first(where: { $0.id == id })
    }
    
    func formatPrice(_ price: Double?) -> String {
        guard let price = price else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₽"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: price)) ?? "\(Int(price)) ₽"
    }
    
    func formatSeason(_ season: Components.Schemas.TireResponse.seasonPayload?) -> String {
        guard let season = season else { return "" }
        switch season {
        case .SUMMER:
            return "☀️ Летние"
        case .WINTER_STUDDED:
            return "❄️ Зимние шипованные"
        case .WINTER_VELCRO:
            return "❄️ Зимние липучка"
        }
    }
    
    func isInStock(_ tire: Components.Schemas.TireResponse) -> Bool {
        return (tire.stockQuantity ?? 0) >= 4
    }
}
