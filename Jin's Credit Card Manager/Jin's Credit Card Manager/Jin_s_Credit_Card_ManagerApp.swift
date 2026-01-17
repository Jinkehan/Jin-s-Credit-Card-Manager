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
        
        // Enable iCloud sync with CloudKit
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Fallback: If CloudKit fails (usually due to schema mismatch or corrupted CloudKit data),
            // fall back to local-only storage. This preserves all local data but disables CloudKit sync.
            // Users can restore CloudKit sync by deleting and reinstalling the app (which resets CloudKit),
            // or by manually resetting their CloudKit container in iCloud settings.
            do {
                let fallbackConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none  // Disable CloudKit to preserve local data
                )
                
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even with fallback: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.light)
                .task {
                    // Request notification permissions when app launches
                    _ = await NotificationManager.shared.requestAuthorization()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
