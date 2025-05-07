//
//  Cache.swift
//  ePolan
//
//  Created by Michał Lisicki on 09/05/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import Foundation
@preconcurrency import Shared

final class Cache<Key: Hashable, Value> {
    private let wrapped = NSCache<NSString, Entry>()
    private let date = Date.init()
    private let entryLifetime: TimeInterval = 12 * 60 * 60
    
    func insert(_ value: Value, forKey key: NSString) {
        let entry = Entry(value: value, expirationDate: date.addingTimeInterval(entryLifetime))
            wrapped.setObject(entry, forKey: key)
        }

    func value(forKey key: NSString) -> Value? {
        guard let entry = wrapped.object(forKey: key) else {
                return nil
            }

        guard date < entry.expirationDate else {
            removeValue(forKey: key)
            return nil
        }

        return entry.value
    }

    func removeValue(forKey key: NSString) {
        wrapped.removeObject(forKey: key)
    }
}

private extension Cache {
    final class Entry {
        let value: Value
        let expirationDate: Date
        
        init(value: Value, expirationDate: Date) {
            self.value = value
            self.expirationDate = expirationDate
        }
    }
}

@Observable
final class CoursesCache {
    private let allCoursesCache = Cache<String, Array<CourseDto>>()
    let allCoursesKey: NSString = "allCourses"

    func loadCachedCourses() -> Array<CourseDto>? {
        if let cachedCourses = allCoursesCache.value(forKey: allCoursesKey) {
            return cachedCourses
        }
        return nil
    }
    
    func addToCache(_ courses: Array<CourseDto>) {
        allCoursesCache.insert(courses, forKey: allCoursesKey)
    }
    
    func invalidateCache() {
        allCoursesCache.removeValue(forKey: allCoursesKey)
    }
}

@Observable
final class LessonsCache {
    private let cachedLessons = Cache<String, Set<LessonDto>>()
    private let cachedActivity = Cache<String, Array<PointDto>>()
    
    func loadCachedActivity(id: KotlinUuid) -> Array<PointDto>? {
        if let cachedActivity = cachedActivity.value(forKey: NSString(string: id.toHexString())) {
            return cachedActivity
        }
        return nil
    }
    
    func addActivityToCache(id: KotlinUuid, _ activity: Array<PointDto>) {
        cachedActivity.insert(activity, forKey: NSString(string: id.toHexString()))
    }
    
    func invalidateActivityCache(id: KotlinUuid) {
        cachedActivity.removeValue(forKey: NSString(string: id.toHexString()))
    }

    func loadCachedLessons(id: KotlinUuid) -> Set<LessonDto>? {
        if let cachedLessons = cachedLessons.value(forKey: NSString(string: id.toHexString())) {
            return cachedLessons
        }
        return nil
    }
    
    func addLessonsToCache(id: KotlinUuid, _ courses: Set<LessonDto>) {
        cachedLessons.insert(courses, forKey: NSString(string: id.toHexString()))
    }
    
    func invalidateLessonsCache(id: KotlinUuid) {
        cachedLessons.removeValue(forKey: NSString(string: id.toHexString()))
    }
}

@Observable
final class DeclarationsCache {
    private let cachedDeclarations = Cache<String, Set<DeclarationDto>>()
    
    func loadCachedDeclarations(id: KotlinUuid) -> Set<DeclarationDto>? {
        if let cachedDeclarations = cachedDeclarations.value(forKey: NSString(string: id.toHexString())) {
            return cachedDeclarations
        }
        return nil
    }
    
    func addDeclarationsToCache(id: KotlinUuid, _ declarations: Set<DeclarationDto>) {
        cachedDeclarations.insert(declarations, forKey: NSString(string: id.toHexString()))
    }
}
