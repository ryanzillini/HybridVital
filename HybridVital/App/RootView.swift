//
//  RootView.swift
//  HybridVital
//
//  Created by Ryan Zillini on 5/6/26.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            Text("Log")
                .tabItem {
                    Label("Log", systemImage: "plus.circle.fill")
                }
            
            Text("AI Coach")
                .tabItem {
                    Label("Coach", systemImage: "sparkles")
                }
            
            Text("Progress")
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
        }
        .tint(.blue)
    }
}
