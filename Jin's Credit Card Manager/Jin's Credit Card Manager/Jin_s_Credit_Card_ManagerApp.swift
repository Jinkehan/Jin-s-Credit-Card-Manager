//
//  JDueApp.swift
//  J Due
//
//  Created by Kehan Jin on 12/25/25.
//

import SwiftUI
import SwiftData

@main
struct JDueApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CreditCard.self,
            CardBenefit.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .task {
                    // Request notification permissions when app launches
                    _ = await NotificationManager.shared.requestAuthorization()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
