//
//  AdminOrdersView.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/8/26.
//

import SwiftUI

struct AdminOrdersView: View {
    
    @StateObject private var viewModel = AdminOrdersViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Загрузка продаж...")
                } else if viewModel.orders.isEmpty {
                    ContentUnavailableView("Продаж пока нет", systemImage: "cart.badge.minus")
                } else {
                    List(viewModel.orders, id: \.id) { order in
                        OrderCard(order: order) {
                            viewModel.callClient(phone: order.clientPhone)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadOrders()
                    }
                }
            }
            .navigationTitle("Продажи 💰")
            .task {
                await viewModel.loadOrders()
            }
        }
    }
}

// Карточка Заказа
struct OrderCard: View {
    let order: Components.Schemas.AdminOrderResponse
    let onCall: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Заголовок: ID и Дата
            HStack {
                Text("Заказ #\(order.id ?? 0)")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(formatDate(order.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Клиент
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
                Text(order.clientName ?? "Клиент")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Кнопка звонка
                Button(action: onCall) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                        .padding(8)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Список товаров (используем строки, которые прислал бэк)
            VStack(alignment: .leading, spacing: 4) {
                if let items = order.itemsSummary {
                    ForEach(items, id: \.self) { item in
                        Text("• \(item)")
                            .font(.callout)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(8)
            
            Divider()
            
            // Итого и Статус
            HStack {
                Text("Итого: \(order.totalPrice ?? 0, format: .number) сом")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(order.status?.rawValue ?? "NEW")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale(identifier: "ru_RU")
        return f.string(from: date)
    }
}

#Preview {
    AdminOrdersView()
}
