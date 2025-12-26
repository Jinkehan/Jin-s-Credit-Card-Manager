//
//  AppSettings.swift
//  Jin's Credit Card Manager
//
//  Created by Kehan Jin on 12/25/25.
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    var reminderDaysAhead: Int
    
    init(reminderDaysAhead: Int = 7) {
        self.reminderDaysAhead = reminderDaysAhead
    }
}

