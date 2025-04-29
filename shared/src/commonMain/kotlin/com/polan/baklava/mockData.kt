@file:OptIn(ExperimentalUuidApi::class)

package com.polan.baklava

import kotlinx.datetime.DayOfWeek
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.LocalTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toInstant
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

//val mockCourseDto = CourseDto(
//    id = Uuid.random(),
//    name = "Introduction to Kotlin",
//    instructor = "John Doe",
//    creator = "Jane Smith",
//    lessonTimes = setOf(LessonTime(
//        dayOfWeek = DayOfWeek.WEDNESDAY,
//        time = LocalTime(10, 30) // 10:30 AM
//    )),
//    lessons = setOf(
//        LessonDto(
//            id = Uuid.random(),
//            classDate = LocalDateTime(2025, 5, 10, 10, 30), // May 10, 2025, 10:30 AM
//            courseName = "Introduction to Kotlin 2"
//        ),
//        LessonDto(
//            id = Uuid.random(),
//            classDate = LocalDateTime(2025, 5, 17, 10, 30), // May 17, 2025, 10:30 AM
//            courseName = "Introduction to Kotlin 3"
//        )
//    )
//)
//
//val mockExerciseDtos: List<ExerciseDto> = listOf(
//    ExerciseDto(
//        id = 0,
//        classDate = LocalDateTime(2025, 5, 17, 11, 0),
//        groupName = "GroupB",
//        exerciseNumber = 2,
//        subpoint = null
//    ),
//    ExerciseDto(
//        id = 1,
//        classDate = LocalDateTime(2025, 5, 24, 12, 0),
//        groupName = "GroupC",
//        exerciseNumber = 3,
//        subpoint = "a"
//    )
//)

