import SwiftUI

struct TireListView: View {
    @StateObject private var viewModel = TireShopViewModel()
    @State private var showingFilters = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.filteredTires.isEmpty {
                    ProgressView("Загрузка шин...")
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.filteredTires.isEmpty {
                    emptyStateView
                } else {
                    tireListContent
                }
            }
            .navigationTitle("Каталог шин")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFilters.toggle()
                    } label: {
                        Label("Фильтры", systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                TireFilterView(viewModel: viewModel)
            }
            .searchable(text: $viewModel.searchText, prompt: "Поиск по марке, модели...")
            .refreshable {
                await viewModel.loadTires(force: true)
            }
            .task {
                if viewModel.tires.isEmpty {
                    await viewModel.loadTires()
                }
            }
            .alert("Покупка успешна! 🎉", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") { }
            } message: {
                Text("Вы купили комплект шин \(viewModel.lastPurchasedItemName)")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var tireListContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if hasActiveFilters {
                    activeFiltersBar
                }
                
                ForEach(viewModel.filteredTires, id: \.id) { tire in
                    NavigationLink {
                        TireDetailView(tire: tire, viewModel: viewModel)
                    } label: {
                        TireRowView(tire: tire, viewModel: viewModel)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .overlay(alignment: .bottom) {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("Нет результатов", systemImage: "magnifyingglass")
        } description: {
            Text("Попробуйте изменить фильтры или поисковый запрос")
        } actions: {
            Button("Сбросить фильтры") {
                viewModel.resetFilters()
            }
        }
    }
    
    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Ошибка", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Повторить") {
                Task {
                    await viewModel.loadTires()
                }
            }
        }
    }
    
    private var activeFiltersBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Активные фильтры")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("Сбросить") {
                    viewModel.resetFilters()
                }
                .font(.caption)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let season = viewModel.selectedSeason {
                        FilterChip(title: viewModel.formatSeason(season)) {
                            viewModel.selectedSeason = nil
                        }
                    }
                    
                    if !viewModel.selectedBrands.isEmpty {
                        ForEach(Array(viewModel.selectedBrands), id: \.self) { brand in
                            FilterChip(title: brand) {
                                viewModel.selectedBrands.remove(brand)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private var hasActiveFilters: Bool {
        viewModel.selectedSeason != nil || 
        !viewModel.selectedBrands.isEmpty ||
        !viewModel.searchText.isEmpty
    }
}

// MARK: - TireRowView

struct TireRowView: View {
    let tire: Components.Schemas.TireResponse
    @ObservedObject var viewModel: TireShopViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Image
            tireImage
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text("\(tire.brand ?? "") \(tire.model ?? "")")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(tire.size ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Text(viewModel.formatSeason(tire.season))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(seasonColor.opacity(0.2))
                        .foregroundStyle(seasonColor)
                        .clipShape(Capsule())
                    
                    Label("\(tire.stockQuantity ?? 0) шт", systemImage: "cube.box")
                        .font(.caption)
                        .foregroundStyle(stockColor)
                }
            }
            
            Spacer()
            
            // Price
            VStack(alignment: .trailing, spacing: 4) {
                Text(viewModel.formatPrice(tire.price))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                if !viewModel.isInStock(tire) {
                    Text("Нет в наличии")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var tireImage: some View {
        Group {
            if let urlString = tire.imageUrl, let url = URL(string: urlString) {
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
        .frame(width: 80, height: 80)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var placeholderImage: some View {
        Image(systemName: "car.circle")
            .font(.system(size: 40))
            .foregroundStyle(.secondary)
    }
    
    private var seasonColor: Color {
        switch tire.season {
        case .SUMMER:
            return .orange
        case .WINTER_STUDDED, .WINTER_VELCRO:
            return .blue
        case .none:
            return .gray
        }
    }
    
    private var stockColor: Color {
        let stock = tire.stockQuantity ?? 0
        if stock >= 4 {
            return .green
        } else if stock > 0 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - FilterChip

struct FilterChip: View {
    let title: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.blue.opacity(0.2))
        .foregroundStyle(.blue)
        .clipShape(Capsule())
    }
}

#Preview {
    TireListView()
}