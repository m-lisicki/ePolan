//
//  LessonStatus.swift
//  ePolan
//
//  Created by Michał Lisicki on 10/05/2025.
//

import Foundation

// MARK: - Enums

enum LessonStatus: String, Codable, Sendable, CaseIterable {
    case future = "FUTURE"
    case near = "NEAR"
    case past = "PAST"
}

enum DeclarationStatus: String, Codable, Sendable {
    case waiting = "WAITING"
    case cancelled = "CANCELLED"
    case rejected = "REJECTED"
    case approved = "APPROVED"
}

// MARK: - Structures

struct LessonTime: Codable, Hashable, Sendable {
    let dayOfWeek: String
    
    static func getMockData() -> [LessonTime] {
        return [
            .init(dayOfWeek: "Monday"),
            .init(dayOfWeek: "Wednesday")
        ]
    }
}

extension String {
    func convertShortWeekDaysToFull() -> String? {
        switch self {
        case Calendar.autoupdatingCurrent.shortWeekdaySymbols[1]:
            return "MONDAY"
        case Calendar.autoupdatingCurrent.shortWeekdaySymbols[2]:
            return "TUESDAY"
        case Calendar.autoupdatingCurrent.shortWeekdaySymbols[3]:
            return "WEDNESDAY"
        case Calendar.autoupdatingCurrent.shortWeekdaySymbols[4]:
            return "THURSDAY"
        case Calendar.autoupdatingCurrent.shortWeekdaySymbols[5]:
            return "FRIDAY"
        case Calendar.autoupdatingCurrent.shortWeekdaySymbols[6]:
            return "SATURDAY"
        case Calendar.autoupdatingCurrent.shortWeekdaySymbols[0]:
            return "SUNDAY"
        default:
            return nil
        }
    }
}

struct ExerciseDto: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let classDate: Date
    let groupName: String
    let exerciseNumber: Int
    var subpoint: String?
    
    init(classDate: Date, groupName: String, exerciseNumber: Int, subpoint: String? = nil) {
        self.id = UUID()
        self.classDate = classDate
        self.groupName = groupName
        self.exerciseNumber = exerciseNumber
        self.subpoint = subpoint
    }
    
    static func getMockData() -> [ExerciseDto] {
        let now = Date()
        return [
            .init(classDate: now, groupName: "Group A", exerciseNumber: 1, subpoint: "a"),
            .init(classDate: now, groupName: "Group A", exerciseNumber: 1, subpoint: "b"),
            .init(classDate: now, groupName: "Group A", exerciseNumber: 2, subpoint: nil),
        ]
    }
}

struct LessonDto: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let classDate: Date
    let courseName: String
    var exercises: Set<ExerciseDto>
    let status: LessonStatus
    
    init(id: UUID = UUID(), classDate: Date, courseName: String, exercises: Set<ExerciseDto> = [], lessonStatus: LessonStatus) {
        self.id = id
        self.classDate = classDate
        self.courseName = courseName
        self.exercises = exercises
        self.status = lessonStatus
    }
    
    static func getMockData() -> [LessonDto] {
        let now = Date()
        let exercises = ExerciseDto.getMockData()
        return [
            .init(classDate: now.addingTimeInterval(-60 * 24*60*60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .past),
            .init(classDate: now.addingTimeInterval(-20 * 24*60*60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .past),
            .init(classDate: now.addingTimeInterval(-30 * 24*60*60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .past),
            .init(classDate: now, courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .past),
            .init(classDate: now.addingTimeInterval(-90 * 24*60*60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .past),
            .init(classDate: now.addingTimeInterval(-100 * 24*60*60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .past),
            .init(classDate: now.addingTimeInterval(-110 * 24*60*60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .past),
            .init(classDate: now.addingTimeInterval(-120 * 24*60*60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .past),
            .init(classDate: now.addingTimeInterval(-130 * 24*60*60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .past),
            .init(classDate: now.addingTimeInterval(30 * 24 * 60 * 60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .near)
        ]
    }
}

struct CourseDto: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    let name: String
    let instructor: String
    let creator: String
    let lessonTimes: Set<LessonTime>
    var lessons: Set<LessonDto>
    let startDate: Date
    let endDate: Date
    let frequency: Int
    let courseCode: String
    
    static func getMockData() -> [CourseDto] {
        let now = Date()
        let lessonTimes = Set(LessonTime.getMockData())
        let lessons = Set(LessonDto.getMockData())
        let thirtyDaysLater = now.addingTimeInterval(30 * 24 * 60 * 60)
        
        return [
            .init(
                name: "SwiftUI Programming",
                instructor: "Dr. Strangelove",
                creator: "admin@example.com",
                lessonTimes: lessonTimes,
                lessons: lessons,
                startDate: now,
                endDate: thirtyDaysLater,
                frequency: 2,
                courseCode: Array(repeating: "101", count: 7).joined(separator: "-")
            ),
            .init(
                name: "iOS Development",
                instructor: "Prof. Johnson",
                creator: "admin@example.com",
                lessonTimes: lessonTimes,
                lessons: lessons,
                startDate: now,
                endDate: thirtyDaysLater,
                frequency: 1,
                courseCode: "BOWIE102"
            )
        ]
    }
}

struct DeclarationDto: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    let declarationDate: Date
    let declarationStatus: DeclarationStatus
    let exercise: ExerciseDto
    let student: String
    
    static func getMockData() -> [DeclarationDto] {
        let now = Date()
        let exercises = ExerciseDto.getMockData()
        
        return [
            .init(
                declarationDate: now,
                declarationStatus: .approved,
                exercise: exercises[0],
                student: ""
            ),
            .init(
                declarationDate: now,
                declarationStatus: .waiting,
                exercise: exercises[1],
                student: ""
            ),
            .init(
                declarationDate: now,
                declarationStatus: .waiting,
                exercise: exercises[2],
                student: ""
            )
        ]
    }
}

struct PointDto: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    let student: String
    let lesson: LessonDto
    let activityValue: Double
    
    static func getMockData() -> [PointDto] {
        let lessons = LessonDto.getMockData()
        return [
            .init(
                student: "john.doe@example.com",
                lesson: lessons[0],
                activityValue: 5.0
            ),
            .init(
                student: "john.doe@example.com",
                lesson: lessons[1],
                activityValue: 8.0
            ),
            .init(
                student: "john.doe@example.com",
                lesson: lessons[2],
                activityValue: 1.0
            ),
            .init(
                student: "john.doe@example.com",
                lesson: lessons[3],
                activityValue: 1.5
            ),
            .init(
                student: "jane.smith@example.com",
                lesson: lessons[4],
                activityValue: 7.0
            ),
            .init(
                student: "jane.smith@example.com",
                lesson: lessons[5],
                activityValue: 1.0
            ),
            .init(
                student: "jane.smith@example.com",
                lesson: lessons[6],
                activityValue: 0.0
            ),
            .init(
                student: "jane.smith@example.com",
                lesson: lessons[7],
                activityValue: 6.0
            ),
            .init(
                student: "jane.smith@example.com",
                lesson: lessons[8],
                activityValue: 3.0
            ),
        ]
    }
}

struct NewCourseDto: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    let name: String
    let instructor: String
    let lessonTimes: Set<LessonTime>
    let students: Set<String>
    let startDate: Date
    let endDate: Date
    let frequency: Int
    
    static func getMockData() -> [NewCourseDto] {
        let now = Date()
        let lessonTimes = Set(LessonTime.getMockData())
        let students: Set<String> = ["john.doe@example.com", "jane.smith@example.com"]
        let thirtyDaysLater = now.addingTimeInterval(30 * 24 * 60 * 60)
        
        return [
            .init(
                name: "New Course 1",
                instructor: "Instructor A",
                lessonTimes: lessonTimes,
                students: students,
                startDate: now,
                endDate: thirtyDaysLater,
                frequency: 3
            ),
            .init(
                name: "New Course 2",
                instructor: "Instructor B",
                lessonTimes: lessonTimes,
                students: students,
                startDate: now,
                endDate: thirtyDaysLater,
                frequency: 1
            )
        ]
    }
}

struct UserDto: Codable, Hashable, Sendable {
    let email: String
    let name: String
    let surname: String
    
    static func getMockData() -> [UserDto] {
        return [
            .init(email: "john.doe@example.com", name: "John", surname: "Doe"),
            .init(email: "jane.smith@example.com", name: "Jane", surname: "Smith")
        ]
    }
}

struct TaskDto: Codable, Hashable, Sendable {
    var groupId: UUID = UUID()
    let courseName: String
    let dueDate: Date
    let numberOfDeclarations: Int
    let assigned: Set<ExerciseDto?>
    
    static func getMockData() -> [TaskDto] {
        let now = Date()
        let thirtyDaysLater = now.addingTimeInterval(30 * 24 * 60 * 60)
        let assignedExercises = Set(ExerciseDto.getMockData())
        
        return [
            .init(
                courseName: "SwiftUI Programming",
                dueDate: thirtyDaysLater,
                numberOfDeclarations: 5,
                assigned: assignedExercises
            ),
            .init(
                courseName: "iOS Development",
                dueDate: thirtyDaysLater,
                numberOfDeclarations: 10,
                assigned: assignedExercises
            )
        ]
    }
}

struct UserInfoDto: Codable, Hashable, Sendable {
    let email: String
    
    static func getMockData() -> [UserInfoDto] {
        return [
            .init(email: "john.doe@example.com"),
            .init(email: "jane.smith@example.com")
        ]
    }
}
