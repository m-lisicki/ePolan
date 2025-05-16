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
    
    private init() {
        let memoryCapacity = 10 * 1024 * 1024 // 20 MB
        let diskCapacity   = 20 * 1024 * 1024 // 100 MB
        let cache = URLCache(memoryCapacity: memoryCapacity,
                             diskCapacity: diskCapacity,
                             diskPath: "urlCache")
        
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .useProtocolCachePolicy
        
        sharedSession = URLSession(configuration: config)
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
        forceRefresh: Bool = false
    ) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("Bearer \(await OAuthManager.shared.currentValidToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = forceRefresh ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy
        
        if let payload = body {
            request.httpBody = try ApiClient.shared.jsonEncoder.encode(payload)
        }
        
        return request
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
        let request = try await makeRequest(url: url, method: method, body: body, forceRefresh: forceRefresh)
        
        let (data, response) = try await ApiClient.shared.sharedSession.data(for: request)
        let validData = try validate(data: data, response: response)
        
        do {
            return try ApiClient.shared.jsonDecoder.decode(T.self, from: validData)
        } catch {
            log.error("Decoding Error for \(T.self): \(error)")
            log.info("Received data: \(String(data: validData, encoding: .utf8) ?? "N/A")")
            throw ApiError.decodingError(error)
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
    
    static func createCourse(
        name: String,
        instructor: String,
        swiftShortSymbols: Set<String>,
        students: Set<String>,
        startDateISO: String,
        endDateISO: String,
        frequency: Int
    ) async throws -> CourseDto {
        guard let startDate = ISO8601DateFormatter().date(from: startDateISO),
              let endDate = ISO8601DateFormatter().date(from: endDateISO) else {
            throw ApiError.invalidDateFormat
        }
        
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
        
        return try await send(url: URL(string: "\(NetworkConstants.baseUrl)/course/create")!, method: .POST, body: payload)
    }
    
    static func getAllStudents(courseId: UUID) async throws -> Set<String> {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/course/\(courseId.uuidString)/students")!, method: .GET)
    }
    
    static func addStudent(courseId: UUID, email: String) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/course/\(email)/\(courseId.uuidString)")!, method: .POST)
    }
    
    static func removeStudent(courseId: UUID, email: String) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/course/\(email)/\(courseId.uuidString)")!, method: .DELETE)
    }
    
    static func getAllCourses(forceRefresh: Bool = false) async throws -> Set<CourseDto> {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/course/courses")!, method: .GET, forceRefresh: forceRefresh)
    }
    
    static func getAllExercises(lessonId: UUID) async throws -> [ExerciseDto] {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/lesson/\(lessonId.uuidString)/exercises")!, method: .GET)
    }
    
    static func getAllLessons(courseId: UUID, forceRefresh: Bool = false) async throws -> [LessonDto] {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/lesson/\(courseId.uuidString)/lessons")!, method: .GET, forceRefresh: forceRefresh)
    }
    
    static func getAllLessonDeclarations(lessonId: UUID, forceRefresh: Bool = false) async throws -> Set<DeclarationDto> {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/declaration/lesson/\(lessonId.uuidString)")!, method: .GET, forceRefresh: forceRefresh)
    }
    
    static func postDeclaration(exerciseId: UUID) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/declaration/\(exerciseId.uuidString)")!, method: .POST)
    }
    
    static func postUnDeclaration(declarationId: UUID) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/declaration/\(declarationId.uuidString)")!, method: .DELETE)
    }
    
    static func getPoints(courseId: UUID) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/points/\(courseId.uuidString)/howMany")!, method: .GET)
    }
    
    static func getPointsForCourse(courseId: UUID, forceRefresh: Bool) async throws -> [PointDto] {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/points/\(courseId.uuidString)")!, method: .GET, forceRefresh: forceRefresh)
    }
    
    static func addPoints(lessonId: UUID, activityValue: Double) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/points/\(lessonId.uuidString)/\(activityValue)")!, method: .POST)
    }
    
    static func getUserEmail() async throws -> String {
        let userInfo: UserInfoDto = try await send(url: URL(string: "\(NetworkConstants.keycloakUrl)/realms/Users/protocol/openid-connect/userinfo")!, method: .GET)
        return userInfo.email
    }
    
    static func addLesson(courseId: UUID, exercisesAmount: Int) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/create/\(courseId.uuidString)/\(exercisesAmount)")!, method: .POST)
    }
    
    static func deleteLesson(lessonId: UUID) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/lesson/\(lessonId.uuidString)")!, method: .DELETE)
    }
    
    static func postExercises(lesson: LessonDto) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/lesson/exercises")!, method: .PUT, body: lesson)
    }
    
    static func archiveCourse(courseId: UUID) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/course/\(courseId.uuidString)")!, method: .DELETE)
    }
    
    static func manualAddLesson(courseId: UUID, date: Date) async throws -> LessonDto {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/lesson/\(courseId.uuidString)/\(date.ISO8601Format())/addLesson")!, method: .POST)
    }
    
    static func joinCourse(invitationCode: String) async throws {
        try await send(url: URL(string: "\(NetworkConstants.baseUrl)/course/\(invitationCode)")!, method: .POST)
    }
}

// MARK: - Error Handling

enum ApiError: Error {
    case invalidResponse
    case httpError(statusCode: Int, body: String)
    case decodingError(Error)
    case encodingError(Error)
    case invalidDateFormat
    case customError(String)
}
