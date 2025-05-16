//
//  definitions.swift
//  ePolan
//
//  Created by Michał Lisicki on 10/05/2025.
//  Copyright © 2025 orgName. All rights reserved.
//


import Foundation

// MARK: - Constants

struct NetworkConstants {
    #if targetEnvironment(simulator)
    static let ip = "localhost"
    #else
    static let ip = "192.168.254.134"
    #endif
    static let baseUrl = "http://\(ip):8080"
    static let keycloakUrl = "http://\(ip):8280"
}

// MARK: - API Client and Services

actor ApiClient {
    static let shared = ApiClient()
    var sharedSession = URLSession(configuration: .default)
    private let cache: URLCache
    
    private init() {
        let memoryCapacity = 20 * 1024 * 1024 // 20 MB
        let diskCapacity   = 100 * 1024 * 1024 // 100 MB
        cache = URLCache(memoryCapacity: memoryCapacity,
                             diskCapacity: diskCapacity,
                             diskPath: "urlCache")
        
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .useProtocolCachePolicy
        
        sharedSession = URLSession(configuration: config)
    }
    
        func removeCachedResponse(for request: URLRequest) {
            cache.removeCachedResponse(for: request)
        }
        
        func removeAllCachedResponses() {
            cache.removeAllCachedResponses()
        }
    
    let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}


struct DBQuery {
    enum HTTPMethod: String {
        case GET, POST, PUT, DELETE
    }
    
    private static func makeRequest(
        url: URL,
        method: HTTPMethod,
        body: Encodable? = nil,
        forceRefresh: Bool = false,
        invalidateCache: Bool = false
    ) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(await OAuthManager.shared.useFreshToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = forceRefresh ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy
        
        if let payload = body {
            request.httpBody = try ApiClient.shared.jsonEncoder.encode(payload)
        }
        
        return request
    }
    
    private struct APIErrorResponse: Decodable {
        let error: String
    }
    
    private static func validate(
        data: Data,
        response: URLResponse
    ) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ApiError.httpError(statusCode: httpResponse.statusCode, body: body)
        }
        
        return data
    }
    
    private static func send<T: Decodable>(
        url: URL,
        method: HTTPMethod,
        body: Encodable? = nil,
        forceRefresh: Bool = false
    ) async throws -> T {
        do {
            let request = try await makeRequest(url: url, method: method, body: body, forceRefresh: forceRefresh)
            
            let (data, response) = try await ApiClient.shared.sharedSession.data(for: request)
            
            let validData = try validate(data: data, response: response)
   
            return try ApiClient.shared.jsonDecoder.decode(T.self, from: validData)
        } catch {
            throw ApiError.requestError(error)
        }
    }
    
    private static func send(
        url: URL,
        method: HTTPMethod,
        body: Encodable? = nil
    ) async throws {
        let request = try await makeRequest(url: url, method: method, body: body)
        let (data, response) = try await ApiClient.shared.sharedSession.data(for: request)
        _ = try validate(data: data, response: response)
    }
    
    // MARK: - API Calls
    
    // MARK: - Students - NR
    private static func getAllStudentURL(_ courseId: UUID) -> URL { URL(string: "\(NetworkConstants.baseUrl)/course/\(courseId.uuidString)/students")! }
    static func getAllStudents(courseId: UUID) async throws -> Set<String> {
        try await send(url: getAllStudentURL(courseId), method: .GET)
    }
    
    static func addStudent(courseId: UUID, email: String) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/course/\(email)/\(courseId.uuidString)")!, method: .POST)
        
        try await ApiClient.shared.removeCachedResponse(for: makeRequest(url: getAllStudentURL(courseId), method: .GET))
    }
    
    static func removeStudent(courseId: UUID, email: String) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/course/\(email)/\(courseId.uuidString)")!, method: .DELETE)
        
        try await ApiClient.shared.removeCachedResponse(for: makeRequest(url: getAllStudentURL(courseId), method: .GET))
    }
    
    // MARK: - Courses - NR
    private static func getAllCoursesURL() -> URL { URL(string: "\(NetworkConstants.baseUrl)/course/courses")! }
    static func getAllCourses(forceRefresh: Bool = false) async throws -> Set<CourseDto> {
        try await send(url: getAllCoursesURL(), method: .GET, forceRefresh: forceRefresh)
    }
    
    private static func getAllArchivedCoursesURL() -> URL { URL(string: "\(NetworkConstants.baseUrl)/course/courses/archived")! }
    static func getArchivedCourses() async throws -> Set<CourseDto> {
        try await send(url: getAllArchivedCoursesURL(), method: .GET)
    }
    
    static func createCourse(
        name: String,
        instructor: String,
        swiftShortSymbols: Set<String>,
        students: Set<String>,
        startDate: Date,
        endDate: Date,
        frequency: Int
    ) async throws -> CourseDto {
        var lessonTimes = Set<LessonTime>()
        swiftShortSymbols.map { $0.convertShortWeekDaysToFull()! }.forEach { lessonTimes.insert(.init(dayOfWeek: $0))}
        
        let payload = NewCourseDto(
            id: UUID(),
            name: name,
            instructor: instructor,
            lessonTimes: lessonTimes,
            students: students,
            startDate: startDate,
            endDate: endDate,
            frequency: frequency
        )
        
        let newCourseDto: CourseDto = try await send(url: URL(string: "\(NetworkConstants.baseUrl)/course/create")!, method: .POST, body: payload)
        try await ApiClient.shared.removeCachedResponse(for: makeRequest(url: getAllCoursesURL(), method: .GET))
        return newCourseDto
    }
    
    static func archiveCourse(courseId: UUID) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/course/\(courseId.uuidString)")!, method: .DELETE)
        
        try await ApiClient.shared.removeCachedResponse(for: makeRequest(url: getAllCoursesURL(), method: .GET))
        try await ApiClient.shared.removeCachedResponse(for: makeRequest(url: getAllArchivedCoursesURL(), method: .GET))
    }
    
    static func unarchiveCourse(courseId: UUID) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/course/\(courseId.uuidString)")!, method: .PUT)
        
        try await ApiClient.shared.removeCachedResponse(for: makeRequest(url: getAllCoursesURL(), method: .GET))
        try await ApiClient.shared.removeCachedResponse(for: makeRequest(url: getAllArchivedCoursesURL(), method: .GET))
    }
    
    static func joinCourse(invitationCode: String) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/course/\(invitationCode)")!, method: .POST)
        
        try await ApiClient.shared.removeCachedResponse(for: makeRequest(url: getAllCoursesURL(), method: .GET))
    }
    
    // MARK: - Declarations - MR
    static func getAllLessonDeclarations(lessonId: UUID, forceRefresh: Bool = false) async throws -> Set<DeclarationDto> {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/declaration/lesson/\(lessonId.uuidString)")!, method: .GET, forceRefresh: forceRefresh)
    }
    
    static func postDeclaration(exerciseId: UUID) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/declaration/\(exerciseId.uuidString)")!, method: .POST)
    }
    
    static func removeDeclaration(declarationId: UUID) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/declaration/\(declarationId.uuidString)")!, method: .DELETE)
    }
    
    // MARK: - Points - NR
    
    private static func getPointsURL(_ courseId: UUID) -> URL { URL(string: "\(NetworkConstants.baseUrl)/points/\(courseId.uuidString)/howMany")! }
    static func getPoints(courseId: UUID) async throws {
        try await send(url: getPointsURL(courseId), method: .GET)
    }
    
    private static func getPointsForCourseURL(_ courseId: UUID) -> URL { URL(string: "\(NetworkConstants.baseUrl)/points/\(courseId.uuidString)")! }
    static func getPointsForCourse(courseId: UUID, forceRefresh: Bool) async throws -> [PointDto] {
        try await send(url: getPointsForCourseURL(courseId), method: .GET, forceRefresh: forceRefresh)
    }
    
    static func addPoints(lessonId: UUID, courseId: UUID, activityValue: Double) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/points/\(lessonId.uuidString)/\(activityValue)")!, method: .POST)
        
        try await ApiClient.shared.removeCachedResponse(for: makeRequest(url: getPointsForCourseURL(courseId), method: .GET))
    }
    
    // MARK: - Lessons - NR
    
    private static func getAllLessonsURL(_ courseId: UUID) -> URL { URL(string: "\(NetworkConstants.baseUrl)/lesson/\(courseId.uuidString)/lessons")! }
    static func getAllLessons(courseId: UUID, forceRefresh: Bool = false) async throws -> Set<LessonDto> {
        try await send(url: getAllLessonsURL(courseId), method: .GET, forceRefresh: forceRefresh)
    }
    
    static func deleteLesson(lessonId: UUID, courseId: UUID) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/lesson/\(lessonId.uuidString)")!, method: .DELETE)
        
        try await ApiClient.shared.removeCachedResponse(for: makeRequest(url: getAllLessonsURL(courseId), method: .GET))
    }
    
    static func manualAddLesson(courseId: UUID, date: Date) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/lesson/\(courseId.uuidString)/\(date.ISO8601Format())/addLesson")!, method: .PUT)
        
        try await ApiClient.shared.removeCachedResponse(for: makeRequest(url: getAllLessonsURL(courseId), method: .GET))
    }
    
    // MARK: - Exercises - NR
    
    private static func getAllExercisesURL(_ lessonId: UUID) -> URL { URL(string: "\(NetworkConstants.baseUrl)/lesson/\(lessonId.uuidString)/exercises")! }
    static func getAllExercises(lessonId: UUID) async throws -> [ExerciseDto] {
        try await send(url: getAllExercisesURL(lessonId), method: .GET)
    }
    
    static func postExercises(lesson: LessonDto) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/lesson/exercises")!, method: .PUT, body: lesson)
        
        try await ApiClient.shared.removeCachedResponse(for: makeRequest(url: getAllExercisesURL(lesson.id), method: .GET))
    }
    
    static func getUserEmail() async throws -> String {
        let userInfo: UserInfoDto = try await send(url: URL(string: "\(NetworkConstants.keycloakUrl)/realms/Users/protocol/openid-connect/userinfo")!, method: .GET)
        return userInfo.email
    }
}
