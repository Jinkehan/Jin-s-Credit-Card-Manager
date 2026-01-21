//
//  CloudKitStatusService.swift
//  J Due
//
//  Created by Kehan Jin on 1/20/26.
//

import Foundation
import CloudKit
import SwiftUI

@Observable
class CloudKitStatusService {
    static let shared = CloudKitStatusService()
    
    var isAvailable: Bool = false
    var accountStatus: CKAccountStatus = .couldNotDetermine
    var statusMessage: String = "Checking iCloud status..."
    var isCheckingStatus: Bool = false
    
    private let container = CKContainer(identifier: "iCloud.kehan.jin.JDue")
    
    private init() {
        Task {
            await checkAccountStatus()
        }
    }
    
    @MainActor
    func checkAccountStatus() async {
        isCheckingStatus = true
        
        print("🔍 Checking CloudKit account status...")
        print("📦 Container ID: iCloud.kehan.jin.JDue")
        
        do {
            let status = try await container.accountStatus()
            accountStatus = status
            
            print("✅ CloudKit account status: \(status.rawValue)")
            
            switch status {
            case .available:
                isAvailable = true
                statusMessage = "iCloud is enabled and syncing"
                print("✅ iCloud is available and ready for sync")
            case .noAccount:
                isAvailable = false
                statusMessage = "Not signed into iCloud. Sign in to enable sync."
                print("❌ No iCloud account signed in")
            case .restricted:
                isAvailable = false
                statusMessage = "iCloud is restricted on this device"
                print("❌ iCloud is restricted")
            case .couldNotDetermine:
                isAvailable = false
                statusMessage = "Could not determine iCloud status"
                print("⚠️ Could not determine iCloud status")
            case .temporarilyUnavailable:
                isAvailable = false
                statusMessage = "iCloud is temporarily unavailable"
                print("⚠️ iCloud temporarily unavailable")
            @unknown default:
                isAvailable = false
                statusMessage = "Unknown iCloud status"
                print("❓ Unknown iCloud status")
            }
        } catch {
            isAvailable = false
            statusMessage = "Error checking iCloud: \(error.localizedDescription)"
            print("❌ Error checking CloudKit status: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
        
        isCheckingStatus = false
    }
    
    var statusColor: Color {
        switch accountStatus {
        case .available:
            return .green
        case .noAccount, .restricted:
            return .red
        case .couldNotDetermine, .temporarilyUnavailable:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    var statusIcon: String {
        switch accountStatus {
        case .available:
            return "checkmark.icloud.fill"
        case .noAccount:
            return "xmark.icloud.fill"
        case .restricted:
            return "exclamationmark.icloud.fill"
        case .couldNotDetermine, .temporarilyUnavailable:
            return "questionmark.circle.fill"
        @unknown default:
            return "icloud.slash.fill"
        }
    }
}
