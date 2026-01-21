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
        // .automatic uses the default iCloud container specified in entitlements
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.kehan.jin.JDue")
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ Successfully initialized ModelContainer with iCloud sync")
            return container
        } catch {
            print("❌ Failed to initialize ModelContainer with CloudKit: \(error.localizedDescription)")
            
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
