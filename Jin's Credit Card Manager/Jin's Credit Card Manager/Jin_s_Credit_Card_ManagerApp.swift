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
        
        // Enable iCloud sync with CloudKit using the private database
        // Use .automatic to automatically use the default iCloud container from entitlements
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ Successfully initialized ModelContainer with iCloud sync")
            print("📦 Using container identifier: iCloud.kehan.jin.JDue")
            return container
        } catch {
            print("❌ Failed to initialize ModelContainer with CloudKit: \(error.localizedDescription)")
            print("❌ Full error: \(error)")
            
            // Fallback: If CloudKit fails, use local-only storage
            // This can happen if:
            // - User is not signed into iCloud
            // - iCloud Drive is disabled
            // - There's a CloudKit schema mismatch
            do {
                let fallbackConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none  // Disable CloudKit to use local storage only
                )
                
                let container = try ModelContainer(for: schema, configurations: [fallbackConfiguration])
                print("⚠️ Using local-only storage (CloudKit disabled)")
                return container
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
