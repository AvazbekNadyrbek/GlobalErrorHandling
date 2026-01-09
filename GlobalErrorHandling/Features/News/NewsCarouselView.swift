//
//  NewsCarouselView.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/8/26.
//

import SwiftUI

struct NewsCarouselView: View {
    @StateObject private var viewModel = NewsViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal)
            
            if let error = viewModel.errorMessage {
                errorView(error)
            } else if viewModel.news.isEmpty && !viewModel.isLoading {
                emptyStateView
            } else {
                newsScrollView
            }
        }
        .task {
            await viewModel.loadNews()
        }
    }
    
    // MARK: - Subviews
    
    private var newsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(viewModel.news, id: \.id) { newsItem in
                    NewsCardView(newsItem: newsItem)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "newspaper")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("Новостей пока нет")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Повторить") {
                Task {
                    await viewModel.loadNews(force: true)
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - NewsCardView

struct NewsCardView: View {
    let newsItem: Components.Schemas.NewsEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Section
            newsImage
            
            // Content Section
            VStack(alignment: .leading, spacing: 8) {
                Text(newsItem.title ?? "Без заголовка")
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                Text(newsItem.content ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                
                Spacer()
                
                if let createdAt = newsItem.createdAt {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(formatDate(createdAt))
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }
            }
            .padding(12)
        }
        .frame(width: 280, height: 220)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var newsImage: some View {
        Group {
            // ВАЖНО: используйте правильное поле после исправления OpenAPI
            // Если в OpenAPI было "umageUrl", то генератор создал свойство umageUrl
            // После исправления на "imageUrl" будет newsItem.imageUrl
            
            if let imageUrl = newsItem.imageUrl, // ← Если исправили OpenAPI
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(height: 120)
        .clipped()
    }
    
    private var placeholderImage: some View {
        ZStack {
            Color(.systemGray5)
            
            VStack(spacing: 8) {
                Image(systemName: "newspaper")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
                
                Text("Нет изображения")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}

#Preview {
    NewsCarouselView()
}
