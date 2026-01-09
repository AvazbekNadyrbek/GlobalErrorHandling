
//
//  BookingView.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/5/26.
//

import SwiftUI
import Combine

struct BookingView: View {
    
    let serviceId: Int64
    let serviceName: String
    
    @StateObject private var viewModel: BookingViewModel
    @Environment(\.dismiss) var dismiss
    
    init(serviceId: Int64, serviceName: String) {
        self.serviceId = serviceId
        self.serviceName = serviceName
        _viewModel = StateObject(wrappedValue: BookingViewModel(serviceId: serviceId, serviceName: serviceName))
    }
    
    var body: some View {
        BookingViewContent(viewModel: viewModel)
            .alert("Успешно! ✅", isPresented: $viewModel.showSuccessAlert) {
                Button("Отлично!") {
                    dismiss()
                }
            } message: {
                Text("Вы успешно записались на \(viewModel.serviceName)")
            }
    }
}

// MARK: - Content (переиспользуемая часть)

struct BookingViewContent: View {
    
    @ObservedObject var viewModel: BookingViewModel
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // 1. ВЫБОР ДАТЫ
                DatePicker(
                    "Выберите дату",
                    selection: $viewModel.selectedDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 2)
                .onChange(of: viewModel.selectedDate) { oldValue, newValue in
                    Task { await viewModel.loadSlots() }
                }
                
                // 2. СПИСОК СЛОТОВ
                if viewModel.isLoading {
                    ProgressView("Ищем свободное время...")
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                } else {
                    Text("Доступное время:")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if viewModel.timeSlots.isEmpty {
                        Text("Нет свободных мест на этот день 😔")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(Array(viewModel.timeSlots.enumerated()), id: \.offset) { index, slot in
                                TimeSlotButton(
                                    slot: slot,
                                    isSelected: viewModel.selectedSlotIndex == index,
                                    action: {
                                        viewModel.selectSlot(at: index)
                                    }
                                )
                            }
                        }
                    }
                }
                
                Spacer()
                
                // 3. КНОПКА ЗАПИСИ
                Button(action: {
                    Task {
                        await viewModel.bookAppointment()
                    }
                }) {
                    Text("Записаться на \(viewModel.serviceName)")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.selectedSlotIndex == nil ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(viewModel.selectedSlotIndex == nil || viewModel.isLoading)
                
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Запись")
        .task {
            await viewModel.loadSlots()
        }
    }
}

// MARK: - TimeSlotButton Component

struct TimeSlotButton: View {
    let slot: Components.Schemas.TimeSlotResponse
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(timeString)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(isSelected ? .bold : .regular)
                
                if let isAvailable = slot.isAvailable {
                    Text(isAvailable ? "Свободно" : "Занято")
                        .font(.caption2)
                        .foregroundColor(isAvailable ? .green : .red)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .disabled(slot.isAvailable == false)
    }
    
    private var timeString: String {
        guard let time = slot.time else { return "—" }
        let hour = time.hour ?? 0
        let minute = time.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }
    
    private var backgroundColor: Color {
        if slot.isAvailable == false {
            return Color.gray.opacity(0.1)
        } else if isSelected {
            return Color.blue.opacity(0.2)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var foregroundColor: Color {
        if slot.isAvailable == false {
            return .gray
        } else if isSelected {
            return .blue
        } else {
            return .primary
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        } else if slot.isAvailable == false {
            return .gray.opacity(0.3)
        } else {
            return Color(.separator)
        }
    }
}


