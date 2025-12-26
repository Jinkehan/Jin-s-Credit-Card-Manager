//
//  ContentView.swift
//  Jin's Credit Card Manager
//
//  Created by Kehan Jin on 12/25/25.
//
//  Note: This file is kept for compatibility but MainTabView is now the main entry point.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [CreditCard.self, AppSettings.self], inMemory: true)
}
