//
//  UtilityHelpers.swift
//  ePolan
//
//  Created by Michał Lisicki on 30/04/2025.
//

import Foundation
import SwiftUI

@Observable
final class Navigator {
    static var shared = Navigator()
    private init() {}
    
    var path = NavigationPath()
    
}

enum EmailHelper {
    static func trimCharacters(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isEmailValid(_ email: String, emails: [String]? = nil) -> Bool {
        let email = trimCharacters(email)
        return !email.isEmpty && email.range(of: #"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$"#, options: .regularExpression) != nil && !(emails?.contains(email) ?? false)
    }
}

extension Set<ExerciseDto> {
    func sortedByNumber() -> [ExerciseDto] {
        sorted { $0.exerciseNumber < $1.exerciseNumber || ($0.exerciseNumber == $1.exerciseNumber && $0.subpoint ?? "z" < $1.subpoint ?? "z") }
    }
}

import Combine

@Observable
final class RefreshController {
    let refreshSignalLessons = PassthroughSubject<Void, Never>()
    let refreshSignalActivity = PassthroughSubject<Void, Never>()
    let refreshSignalCourses = PassthroughSubject<Void, Never>()

    func triggerRefreshActivity() {
        refreshSignalActivity.send()
    }

    func triggerRefreshLessons() {
        refreshSignalLessons.send()
    }

    func triggerRefreshCourses() {
        refreshSignalCourses.send()
    }
}
