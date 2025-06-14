//
//  AppIntent.swift
//  ePolan
//
//  Created by Michał Lisicki on 12/06/2025.
//

//import SwiftUI
//import AppIntents
//

//
//nonisolated struct CourseEntityQuery: EntityQuery {
//    func entities(for identifiers: [CourseEntity.ID]) async throws -> [CourseEntity] {
//        let courses = try await DBQuery.getAllCourses().sorted { $0.name < $1.name }
//        return courses.map { CourseEntity(id: $0.id, name: $0.name) }
//    }
//}
//
//struct CourseEntity: @preconcurrency AppEntity {
//    var id: UUID
//    
//    var name: String
//    
//    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Course")
//    static let defaultQuery = CourseEntityQuery()
//    
//    static func == (lhs: CourseEntity, rhs: CourseEntity) -> Bool {
//        lhs.id == rhs.id
//    }
//    
//
//    var displayRepresentation: DisplayRepresentation {
//        DisplayRepresentation(title: "\(name)")
//    }
//}
//
//
//struct ShowNextLesson: @preconcurrency AppIntent {
//    static var title: LocalizedStringResource = "Navigate to the next lesson view"
//    
//    func perform() async throws -> some ReturnsValue<CourseEntity> & ProvidesDialog & ShowsSnippetView {
//        
//        let cou
//        
//    }
//
//}
