//
//  MainTabView.swift
//  GlobalErrorHandling
//
//  Created by Авазбек Надырбек уулу on 1/5/26.
//

import SwiftUI

struct MainTabView: View {
    
    // Нам не нужен здесь Router, если мы используем NavigationStack внутри табов
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // 1. Услуги (NavigationCoordinator уже содержит NavigationStack)
            NavigationCoordinator()
                .tabItem {
                    Label("Услуги", systemImage: "wrench.and.screwdriver")
                }
                .tag(0)
            
            // 2. Мои записи
            // Оберни в NavigationStack, если внутри BookingListView его нет
            NavigationStack {
                BookingListView()
            }
            .tabItem {
                Label("Записи", systemImage: "calendar")
            }
            .tag(1)
            
            // 3. Админка (ТОЛЬКО ДЛЯ ADMIN)
            if authViewModel.role == "ADMIN" {
                // AdminDashboardView уже содержит NavigationStack внутри себя?
                // Если да - ок. Если нет - добавь сюда.
                AdminDashboardView()
                    .tabItem {
                        Label("Мастерская", systemImage: "chart.bar.doc.horizontal")
                    }
                    .tag(2)
            }
            
            // 4. Профиль
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Профиль", systemImage: "person.circle")
            }
            .tag(3)
        }
    }
}
