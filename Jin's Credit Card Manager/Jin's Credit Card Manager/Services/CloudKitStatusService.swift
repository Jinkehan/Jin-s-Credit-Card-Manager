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
        
        do {
            let status = try await container.accountStatus()
            accountStatus = status
            
            switch status {
            case .available:
                isAvailable = true
                statusMessage = "iCloud is enabled and syncing"
            case .noAccount:
                isAvailable = false
                statusMessage = "Not signed into iCloud. Sign in to enable sync."
            case .restricted:
                isAvailable = false
                statusMessage = "iCloud is restricted on this device"
            case .couldNotDetermine:
                isAvailable = false
                statusMessage = "Could not determine iCloud status"
            case .temporarilyUnavailable:
                isAvailable = false
                statusMessage = "iCloud is temporarily unavailable"
            @unknown default:
                isAvailable = false
                statusMessage = "Unknown iCloud status"
            }
        } catch {
            isAvailable = false
            statusMessage = "Error checking iCloud: \(error.localizedDescription)"
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
