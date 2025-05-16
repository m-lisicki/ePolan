//
//  UtilityHelpers.swift
//  ePolan
//
//  Created by Michał Lisicki on 30/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import Foundation

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

@Observable
final class RefreshController {
    let refreshSignalExercises = PassthroughSubject<Void, Never>()
    let refreshSignalActivity = PassthroughSubject<Void, Never>()
    
    func triggerRefreshExercises() {
        refreshSignalExercises.send()
    }
    
    func triggerRefreshActivity() {
        refreshSignalActivity.send()
    }
}

//import NotificationCenter
//
//struct NotificationCentre {
//    
//    static func scheduleCourseNotification(startDate: Date, endDate: Date, courseName: String, weekDay: Set<String>) {
//        let content = UNMutableNotificationContent()
//        content.title = "\(courseName) awaits"
//        content.body = "Don't forget to assign your declarations!"
//        content.sound = .default
//        
//        let formatter = DateFormatter()
//        formatter.locale = Locale.current
//        
//        let shortWeekdaySymbols = Calendar.current.shortWeekdaySymbols
//        
//        for day in weekDay {
//            guard let targetWeekdayIndex = shortWeekdaySymbols.firstIndex(where: { $0.caseInsensitiveCompare(day) == .orderedSame }) else {
//                continue
//            }
//            
//            let targetWeekday = targetWeekdayIndex + 1
//            
//            let notificationWeekday = targetWeekday == 1 ? 7 : targetWeekday - 1
//            
//            var dateComponents = DateComponents()
//            dateComponents.weekday = notificationWeekday
//            dateComponents.hour = 18
//            dateComponents.minute = 0
//            
//            let identifier = "\(courseName)_\(day)_notification"
//            
//            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
//            
//            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
//            UNUserNotificationCenter.current().add(request) { error in
//                if let error = error {
//                    print("Notification scheduling failed: \(error)")
//                }
//            }
//        }
//    }
//    
//}
