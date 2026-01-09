import SwiftUI

struct TireDetailView: View {
    let tire: Components.Schemas.TireResponse?
    let tireId: Int64?
    
    @StateObject private var viewModel = TireShopViewModel()
    @State private var showingPurchaseConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initializers
    
    /// Initialize with a tire object (from list navigation)
    init(tire: Components.Schemas.TireResponse, viewModel: TireShopViewModel) {
        self.tire = tire
        self.tireId = tire.id
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    /// Initialize with just an ID (from deep linking or route)
    init(tireId: Int64) {
        self.tire = nil
        self.tireId = tireId
    }
    
    // MARK: - Computed Property
    
    private var currentTire: Components.Schemas.TireResponse? {
        if let tire = tire {
            return tire
        }
        if let id = tireId {
            return viewModel.getTireById(id)
        }
        return nil
    }
    
    var body: some View {
        Group {
            if let tire = currentTire {
                contentView(for: tire)
            } else if viewModel.isLoading {
                ProgressView("Загрузка...")
            } else {
                ContentUnavailableView {
                    Label("Шина не найдена", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("Не удалось загрузить информацию о шине")
                } actions: {
                    Button("Вернуться") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            // Load tires if we only have an ID and no tire object
            if tire == nil && tireId != nil && viewModel.tires.isEmpty {
                await viewModel.loadTires()
            }
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private func contentView(for tire: Components.Schemas.TireResponse) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero Image
                tireImageSection(for: tire)
                
                // Main Info
                mainInfoSection(for: tire)
                
                // Specifications
                specificationsSection(for: tire)
                
                // Stock Status
                stockSection(for: tire)
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .navigationTitle("Детали")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            purchaseButton(for: tire)
        }
        .confirmationDialog(
            "Подтверждение покупки",
            isPresented: $showingPurchaseConfirmation,
            titleVisibility: .visible
        ) {
            Button("Купить комплект за \(viewModel.formatPrice(totalPrice(for: tire)))") {
                Task {
                    await viewModel.buyTires(tire: tire)
                    if viewModel.errorMessage == nil {
                        dismiss()
                    }
                }
            }
            
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Вы покупаете комплект из 4 шин \(tire.brand ?? "") \(tire.model ?? "")")
        }
        .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Subviews
    
    private func tireImageSection(for tire: Components.Schemas.TireResponse) -> some View {
        Group {
            if let urlString = tire.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
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
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var placeholderImage: some View {
        VStack(spacing: 12) {
            Image(systemName: "car.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            
            Text("Изображение недоступно")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private func mainInfoSection(for tire: Components.Schemas.TireResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(tire.brand ?? "") \(tire.model ?? "")")
                .font(.title)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                Label(tire.size ?? "—", systemImage: "ruler")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text(viewModel.formatSeason(tire.season))
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(seasonColor(for: tire).opacity(0.2))
                    .foregroundStyle(seasonColor(for: tire))
                    .clipShape(Capsule())
            }
            
            Divider()
            
            HStack(alignment: .firstTextBaseline) {
                Text("Цена за шт:")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(viewModel.formatPrice(tire.price))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text("Комплект (4 шт):")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(viewModel.formatPrice(totalPrice(for: tire)))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func specificationsSection(for tire: Components.Schemas.TireResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Характеристики")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                SpecRow(title: "Бренд", value: tire.brand ?? "—")
                SpecRow(title: "Модель", value: tire.model ?? "—")
                SpecRow(title: "Размер", value: tire.size ?? "—")
                SpecRow(title: "Сезон", value: seasonName(for: tire))
                SpecRow(title: "Цена", value: viewModel.formatPrice(tire.price))
            }
        }
    }
    
    private func stockSection(for tire: Components.Schemas.TireResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Наличие на складе")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: stockIcon(for: tire))
                    .font(.title2)
                    .foregroundStyle(stockColor(for: tire))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(tire.stockQuantity ?? 0) шт. в наличии")
                        .font(.headline)
                    
                    Text(stockMessage(for: tire))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(stockColor(for: tire).opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func purchaseButton(for tire: Components.Schemas.TireResponse) -> some View {
        Button {
            showingPurchaseConfirmation = true
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "cart.fill")
                    Text("Купить комплект")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isInStock(tire) ? Color.blue : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!viewModel.isInStock(tire) || viewModel.isLoading)
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Computed Properties
    
    private func totalPrice(for tire: Components.Schemas.TireResponse) -> Double {
        (tire.price ?? 0) * 4
    }
    
    private func seasonColor(for tire: Components.Schemas.TireResponse) -> Color {
        switch tire.season {
        case .SUMMER:
            return .orange
        case .WINTER_STUDDED, .WINTER_VELCRO:
            return .blue
        case .none:
            return .gray
        }
    }
    
    private func seasonName(for tire: Components.Schemas.TireResponse) -> String {
        switch tire.season {
        case .SUMMER:
            return "Летние"
        case .WINTER_STUDDED:
            return "Зимние (шипованные)"
        case .WINTER_VELCRO:
            return "Зимние (липучка)"
        case .none:
            return "—"
        }
    }
    
    private func stockColor(for tire: Components.Schemas.TireResponse) -> Color {
        let stock = tire.stockQuantity ?? 0
        if stock >= 4 {
            return .green
        } else if stock > 0 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func stockIcon(for tire: Components.Schemas.TireResponse) -> String {
        let stock = tire.stockQuantity ?? 0
        if stock >= 4 {
            return "checkmark.circle.fill"
        } else if stock > 0 {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    private func stockMessage(for tire: Components.Schemas.TireResponse) -> String {
        let stock = tire.stockQuantity ?? 0
        if stock >= 4 {
            return "Достаточно для комплекта"
        } else if stock > 0 {
            return "Недостаточно для комплекта (нужно 4 шт)"
        } else {
            return "Товар отсутствует"
        }
    }
}

// MARK: - SpecRow

struct SpecRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        TireDetailView(
            tire: Components.Schemas.TireResponse(
                id: 1,
                brand: "Michelin",
                model: "Pilot Sport 4",
                size: "225/45 R17",
                season: .SUMMER,
                price: 8500,
                stockQuantity: 12,
                imageUrl: nil
            ),
            viewModel: TireShopViewModel()
        )
    }
}