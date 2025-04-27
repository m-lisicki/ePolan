//
//  tempModel.swift
//  iosApp
//
//  Created by Michał Lisicki on 27/04/2025.
//  Copyright © 2025 orgName. All rights reserved.
//

import Foundation

struct Lesson: Identifiable {
    let id: Int
    let lessonName: String
    let tasks: [Task]?
    let deadline: Date
    var selection = Set<UUID>()
}

struct Task: Identifiable, Hashable {
    var id = UUID()
    
    var assigned: Bool
    var number: Int
    var numberAddon: String?
    var taken: Int
}
