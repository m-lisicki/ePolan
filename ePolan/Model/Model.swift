//
//  Model.swift
//  ePolan
//
//  Created by Michał Lisicki on 10/05/2025.
//

import Foundation

// MARK: - Enums

enum LessonStatus: String, Codable, CaseIterable {
    case future = "FUTURE"
    case near = "NEAR"
    case past = "PAST"
}

enum DeclarationStatus: String, Codable {
    case waiting = "WAITING"
    case rejected = "REJECTED"
    case approved = "APPROVED"
}

// MARK: - Structures

nonisolated struct LessonTime: Codable, Hashable {
    let dayOfWeek: String
    static func getMockData() -> [LessonTime] {
        [
            .init(dayOfWeek: "Monday"),
            .init(dayOfWeek: "Wednesday"),
        ]
    }
}

extension String {
    nonisolated func convertShortWeekDaysToFull() -> String? {
        switch self {
        case Calendar.autoupdatingCurrent.shortWeekdaySymbols[1]:
            "MONDAY"
        case Calendar.autoupdatingCurrent.shortWeekdaySymbols[2]:
            "TUESDAY"
        case Calendar.autoupdatingCurrent.shortWeekdaySymbols[3]:
            "WEDNESDAY"
        case Calendar.autoupdatingCurrent.shortWeekdaySymbols[4]:
            "THURSDAY"
        case Calendar.autoupdatingCurrent.shortWeekdaySymbols[5]:
            "FRIDAY"
        case Calendar.autoupdatingCurrent.shortWeekdaySymbols[6]:
            "SATURDAY"
        case Calendar.autoupdatingCurrent.shortWeekdaySymbols[0]:
            "SUNDAY"
        default:
            nil
        }
    }
}

nonisolated struct ExerciseDto: Identifiable, Codable, Hashable {
    let id: UUID
    let classDate: Date
    let groupName: String
    let exerciseNumber: Int
    var subpoint: String?
    let approvedStudent: String?

    init(id: UUID = .init(), classDate: Date, groupName: String, exerciseNumber: Int, subpoint: String? = nil, approvedStudent: String? = nil) {
        self.id = id
        self.classDate = classDate
        self.groupName = groupName
        self.exerciseNumber = exerciseNumber
        self.subpoint = subpoint
        self.approvedStudent = approvedStudent
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

nonisolated struct LessonDto: Identifiable, Codable, Hashable, Sendable {
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
        status = lessonStatus
    }

    static func getMockData() -> [LessonDto] {
        let now = Date()
        let exercises = ExerciseDto.getMockData()
        return [
            .init(classDate: now.addingTimeInterval(-5 * 24 * 60 * 60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .past),
            .init(classDate: now.addingTimeInterval(-15 * 24 * 60 * 60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .past),
            .init(classDate: now.addingTimeInterval(-25 * 24 * 60 * 60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .past),
            .init(classDate: now.addingTimeInterval(-35 * 24 * 60 * 60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .past),
            .init(classDate: now.addingTimeInterval(-45 * 24 * 60 * 60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .past),
            .init(classDate: now.addingTimeInterval(5 * 24 * 60 * 60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .near),
            .init(classDate: now.addingTimeInterval(15 * 24 * 60 * 60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .future),
            .init(classDate: now.addingTimeInterval(25 * 24 * 60 * 60), courseName: "SwiftUI Programming", exercises: Set(exercises), lessonStatus: .future),
        ]
    }
}

nonisolated struct CourseDto: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = .init()
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
                courseCode: Array(repeating: "101", count: 7).joined(separator: "-"),
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
                courseCode: "BOWIE102",
            ),
        ]
    }
}

nonisolated struct DeclarationDto: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = .init()
    let declarationDate: Date
    let declarationStatus: DeclarationStatus
    let exercise: ExerciseDto
    let student: String

    init(id: UUID = .init(), declarationDate: Date, declarationStatus: DeclarationStatus, exercise: ExerciseDto, student: String) {
        self.id = id
        self.declarationDate = declarationDate
        self.declarationStatus = declarationStatus
        self.exercise = exercise
        self.student = student
    }

    static func getMockData() -> [DeclarationDto] {
        let now = Date()
        let exercises = ExerciseDto.getMockData()

        return [
            .init(
                declarationDate: now,
                declarationStatus: .approved,
                exercise: exercises[0],
                student: "",
            ),
            .init(
                declarationDate: now,
                declarationStatus: .approved,
                exercise: exercises[1],
                student: "",
            ),
            .init(
                declarationDate: now,
                declarationStatus: .rejected,
                exercise: exercises[2],
                student: "",
            ),
        ]
    }
}

nonisolated struct PointDto: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = .init()
    let student: String
    let lesson: LessonDto
    let activityValue: Double

    static func getMockData() -> [PointDto] {
        let lessons = LessonDto.getMockData()
        return [
            .init(
                student: "john.doe@example.com",
                lesson: lessons[0],
                activityValue: 5.0,
            ),
            .init(
                student: "john.doe@example.com",
                lesson: lessons[1],
                activityValue: 8.0,
            ),
            .init(
                student: "john.doe@example.com",
                lesson: lessons[2],
                activityValue: 1.0,
            ),
            .init(
                student: "john.doe@example.com",
                lesson: lessons[3],
                activityValue: 1.5,
            ),
            .init(
                student: "jane.smith@example.com",
                lesson: lessons[4],
                activityValue: 7.0,
            ),
            .init(
                student: "jane.smith@example.com",
                lesson: lessons[5],
                activityValue: 1.0,
            ),
            .init(
                student: "jane.smith@example.com",
                lesson: lessons[6],
                activityValue: 0.0,
            ),
            .init(
                student: "jane.smith@example.com",
                lesson: lessons[7],
                activityValue: 6.0,
            ),
        ]
    }
}

nonisolated struct NewCourseDto: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = .init()
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
                frequency: 3,
            ),
            .init(
                name: "New Course 2",
                instructor: "Instructor B",
                lessonTimes: lessonTimes,
                students: students,
                startDate: now,
                endDate: thirtyDaysLater,
                frequency: 1,
            ),
        ]
    }
}

nonisolated struct UserDto: Codable, Hashable, Sendable {
    let email: String
    let name: String
    let surname: String

    static func getMockData() -> [UserDto] {
        [
            .init(email: "john.doe@example.com", name: "John", surname: "Doe"),
            .init(email: "jane.smith@example.com", name: "Jane", surname: "Smith"),
        ]
    }
}

nonisolated struct TaskDto: Codable, Hashable, Sendable {
    var groupId: UUID = .init()
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
                assigned: assignedExercises,
            ),
            .init(
                courseName: "iOS Development",
                dueDate: thirtyDaysLater,
                numberOfDeclarations: 10,
                assigned: assignedExercises,
            ),
        ]
    }
}

nonisolated struct UserInfoDto: Codable, Hashable, Sendable {
    let email: String

    static func getMockData() -> [UserInfoDto] {
        [
            .init(email: "john.doe@example.com"),
            .init(email: "jane.smith@example.com"),
        ]
    }
}
