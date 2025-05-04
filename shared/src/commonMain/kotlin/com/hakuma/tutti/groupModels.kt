@file:OptIn(ExperimentalUuidApi::class)

package com.hakuma.tutti

import kotlinx.datetime.DayOfWeek
import kotlinx.datetime.Instant
import kotlinx.serialization.Contextual
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

// Pojedyncze punkty z aktywności przydzielone użytkownikowi
@Serializable
data class PointDto(
    var id: Uuid,
    var student: String,
    var lesson: LessonDto,
    var activityValue: Double
)

// Dane całokształtu kursu
@Serializable
data class CourseDto(
    val id: Uuid,
    val name: String,
    val instructor: String,
    val creator: String,
    val lessonTimes: Set<LessonTime>,
    val lessons: Set<LessonDto>?,
    val startDate: Instant,
    val endDate: Instant,
    var frequency: Int,
    var isArchived: Boolean
)

// Dane pojedynczej sesji (lekcji)
@Serializable
data class LessonDto(
    val id: Uuid,
    @Contextual
    val classDate: Instant,
    val courseName: String,
    var exercises: Set<ExerciseDto>?,
    @SerialName("status")
    val lessonStatus: LessonStatus
) {
    fun getClassDateString(): String = classDate.toString()
}

// Czas pojedynczej lekcji
@Serializable
class LessonTime (
    val dayOfWeek: DayOfWeek,
)

// Pojedyncza deklaracja zadań przypisana do pojedynczej sesji (lekcji)
@Serializable
data class DeclarationDto(
    val id: Uuid,
    val declarationDate: Instant,
    val declarationStatus: DeclarationStatus,
    val exercise: ExerciseDto,
    val student: String
)

// Status deklaracji
@Serializable
enum class DeclarationStatus {
    WAITING,
    CANCELLED,
    REJECTED,
    APPROVED
}

@Serializable
enum class LessonStatus {
    PAST,
    NEAR,
    FUTURE
}

// Dane pojedynczego ćwiczenia z danych zajęć
@Serializable
data class ExerciseDto(
    val id: Uuid,
    val classDate: Instant,
    val groupName: String,
    val exerciseNumber: Int,
    var subpoint: String?,
    ) {
    constructor(classDate: Instant,
        groupName: String,
        exerciseNumber: Int,
        subpoint: String?
    ) : this(
        Uuid.random(),
        classDate,
        groupName,
        exerciseNumber,
        subpoint
    )
}

@Serializable
data class NewCourseDto(
    var id: Uuid,
    var name: String,
    var instructor: String,
    var lessonTimes: Set<LessonTime>,
    var students: Set<String>,
    var startDate: Instant,
    var endDate: Instant,
    var frequency: Int
)

// Dane użytkownika
@Serializable
data class UserDto(
    val email: String,
    val name: String,
    val surname: String
)

// Dane zestawu zadań
@Serializable
data class TaskDto (
    val groupId: Uuid,
    val courseName: String,
    val dueDate: Instant,
    val numberOfDeclarations: Int,
    val assigned: Set<ExerciseDto?>
)

@Serializable
data class UserInfoDto(
    val email: String
)