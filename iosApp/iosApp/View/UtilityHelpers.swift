//
//  UtilityHelpers.swift
//  iosApp
//
//  Created by Michał Lisicki on 30/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import Foundation
import Shared

extension LessonDto {
    var statusText: String {
        switch lessonStatus {
        case .past: return "Past"
        case .near: return "Near"
        case .future: return "Future"
        default: return "Unknown"
        }
    }
}

struct EmailHelper {
    static func trimCharacters(_ email: String) -> String {
        return email.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func isEmailValid(_ email: String, emails: Array<String>? = nil) -> Bool {
        let email = trimCharacters(email)
        return !email.isEmpty && email.range(of: #"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$"#, options: .regularExpression) != nil && !(emails?.contains(email) ?? false)
    }
}

extension Set<ExerciseDto> {
    func sortedByNumber() -> Array<ExerciseDto> {
        self.sorted { $0.exerciseNumber < $1.exerciseNumber || ($0.exerciseNumber == $1.exerciseNumber && $0.subpoint ?? "z" < $1.subpoint ?? "z") }
    }
}

import Combine

class RefreshController: ObservableObject {
    let refreshSignalExercises = PassthroughSubject<Void, Never>()
    let refreshSignalActivity = PassthroughSubject<Void, Never>()
    
    func triggerRefreshExercises() {
        refreshSignalExercises.send()
    }
    
    func triggerRefreshActivity() {
        refreshSignalActivity.send()
    }
}
