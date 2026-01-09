//
//  AdminNewsCreateView.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/9/26.
//

import SwiftUI

struct AdminNewsCreateView: View {
    
    
    @StateObject private var viewModel = AdminNewsViewModel()
    @Environment(\.dismiss) var dismiss
    
    
    var body: some View {
        NavigationStack {
            Form {
                
                // Section 1
                Section("Содержание") {
                    TextField("Заголовок например (Акция)", text: $viewModel.title)
                    
                    ZStack(alignment: .topLeading) {
                        if viewModel.content.isEmpty {
                            Text("Текс новости...")
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.top, 8)
                        }
                        TextEditor(text: $viewModel.content)
                            .frame(minHeight: 100)
                    }
                }
                
                // Секция 2: Картинка
                Section("Картинка (URL)") {
                    TextField("Ссылка на фото (http://...)", text: $viewModel.imageUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    // Предпросмотр картинки
                    if let url = URL(string: viewModel.imageUrl), !viewModel.imageUrl.isEmpty {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .cornerRadius(10)
                                .listRowInsets(EdgeInsets()) // Убираем отступы
                        } placeholder: {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    }
                }
                
                // Секция 3: Кнопка
                Section {
                    Button(action: {
                        Task { await viewModel.publishNews() }
                    }) {
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Опубликовать")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(viewModel.isValid ? Color.blue : Color.gray)
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
            }
            .navigationTitle("Новая запись")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .alert("Готово", isPresented: $viewModel.showSuccess) {
                Button("Ok") {
                    dismiss()
                }
            } message: {
                Text("Новость успешно опубликована и видна всем клиентам.")
            }
        }
        // Алерт ошибки
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("ОК", role: .cancel) {
                
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
}
