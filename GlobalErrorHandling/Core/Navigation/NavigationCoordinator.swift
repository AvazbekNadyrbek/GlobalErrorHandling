//
//  NavigationCoordinator.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/5/26.
//

import SwiftUI

/// Координатор навигации - преобразует Route в View
struct NavigationCoordinator: View {
    
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack(path: $router.path) {
            // 🏠 Корневой экран - список услуг
            VStack {
                ServiceView()
                    .navigationDestination(for: Route.self) { route in
                        viewForRoute(route)
                    }
                    .sheet(item: $router.sheet) { route in
                        NavigationStack {
                            viewForRoute(route)
                        }
                    }
                    .fullScreenCover(item: $router.fullScreenCover) { route in
                        NavigationStack {
                            viewForRoute(route)
                        }
                    }
                

            }
            
        }
    }
    
    // MARK: - Route → View Mapping
    
    @ViewBuilder
    private func viewForRoute(_ route: Route) -> some View {
        switch route {
        // MARK: Services
        case .servicesList:
            ServicesListView()
            
        case .serviceDetail(let id):
            ServiceDetailView(serviceId: id)
            
        // MARK: Booking
        case .bookingList:
            BookingListView()
            
        case .timeSlotPicker(let date, let serviceId):
            TimeSlotPickerView(date: date, serviceId: serviceId)
            
        // MARK: Inventory
        case .tireList:
            TireListView()
            
        case .tireDetail(let id):
            TireDetailView(tireId: id)
            
        case .tireFilter:
            TireFilterView(viewModel: TireShopViewModel())
            
        // MARK: Profile
        case .profile:
            ProfileView()
            
        case .settings:
            SettingsView()
            
        case .admin:
            AdminDashboardView()
        }
        
    }
}

// MARK: - Route должен быть Identifiable для sheet/fullScreenCover

extension Route: Identifiable {
    var id: String {
        switch self {
        case .servicesList: return "servicesList"
        case .serviceDetail(let id): return "serviceDetail_\(id)"
        case .bookingList: return "bookingList"
        case .timeSlotPicker(let date, let serviceId):
            return "timeSlotPicker_\(date)_\(serviceId)"
        case .tireList: return "tireList"
        case .tireDetail(let id): return "tireDetail_\(id)"
        case .tireFilter: return "tireFilter"
        case .profile: return "profile"
        case .settings: return "settings"
        case .admin: return "admin"
        }
    }
}
