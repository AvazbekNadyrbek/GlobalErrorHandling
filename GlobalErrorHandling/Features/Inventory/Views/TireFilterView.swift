import SwiftUI

struct TireFilterView: View {
    @ObservedObject var viewModel: TireShopViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initializer
    
    /// Initialize with an existing viewModel (from sheet in TireListView)
    init(viewModel: TireShopViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Season Filter
                seasonSection
                
                // Brand Filter
                brandSection
                
                // Price Range
                priceSection
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Сбросить") {
                        viewModel.resetFilters()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var seasonSection: some View {
        Section {
            ForEach([
                Components.Schemas.TireResponse.seasonPayload.SUMMER,
                Components.Schemas.TireResponse.seasonPayload.WINTER_STUDDED,
                Components.Schemas.TireResponse.seasonPayload.WINTER_VELCRO
            ], id: \.self) { season in
                Button {
                    if viewModel.selectedSeason == season {
                        viewModel.selectedSeason = nil
                    } else {
                        viewModel.selectedSeason = season
                    }
                } label: {
                    HStack {
                        Text(viewModel.formatSeason(season))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if viewModel.selectedSeason == season {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        } header: {
            Text("Сезон")
        }
    }
    
    private var brandSection: some View {
        Section {
            if viewModel.availableBrands.isEmpty {
                Text("Нет доступных брендов")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.availableBrands, id: \.self) { brand in
                    Toggle(brand, isOn: Binding(
                        get: { viewModel.selectedBrands.contains(brand) },
                        set: { isSelected in
                            if isSelected {
                                viewModel.selectedBrands.insert(brand)
                            } else {
                                viewModel.selectedBrands.remove(brand)
                            }
                        }
                    ))
                }
            }
        } header: {
            Text("Бренды")
        } footer: {
            if !viewModel.selectedBrands.isEmpty {
                Text("Выбрано: \(viewModel.selectedBrands.count)")
            }
        }
    }
    
    private var priceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("От:")
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.formatPrice(viewModel.minPrice))
                        .fontWeight(.medium)
                }
                
                Slider(
                    value: $viewModel.minPrice,
                    in: viewModel.priceRange,
                    step: 500
                )
                
                HStack {
                    Text("До:")
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.formatPrice(viewModel.maxPrice))
                        .fontWeight(.medium)
                }
                
                Slider(
                    value: $viewModel.maxPrice,
                    in: viewModel.priceRange,
                    step: 500
                )
            }
            .padding(.vertical, 8)
        } header: {
            Text("Диапазон цен")
        } footer: {
            Text("Цена за одну шину")
        }
    }
}

#Preview {
    TireFilterView(viewModel: TireShopViewModel())
}