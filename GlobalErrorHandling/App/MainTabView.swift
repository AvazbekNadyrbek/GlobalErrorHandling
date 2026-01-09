//
//  MainTabView.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/5/26.
//

import SwiftUI

struct MainTabView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                NavigationCoordinator()
            }
            .tabItem {
                Label("Услуги", systemImage: "wrench.and.screwdriver")
            }
            .tag(0)
            
            NavigationStack {
                BookingListView()
            }
            .tabItem {
                Label("Записи", systemImage: "calendar")
            }
            .tag(1)
            
            if authViewModel.role == "ADMIN" {
                NavigationStack {
                    AdminDashboardView()
                }
                .tabItem {
                    Label("Мастерская", systemImage: "chart.bar.doc.horizontal")
                }
                .tag(2)
                
                AdminOrdersView()
                        .tabItem {
                            Label("Продажи", systemImage: "banknote")
                        }
                        .tag(3)
            } else {
                NavigationStack {
                    ProfileView()
                }
                .tabItem {
                    Label("Профиль", systemImage: "person.circle")
                }
                .tag(4)
                
                NavigationStack {
                    TireListView()
                }
                .tabItem {
                    Label("Магазин", systemImage: "cart")
                }
                .tag(5)
            }
            
           
            
        }
    }
}
