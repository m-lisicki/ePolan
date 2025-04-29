@file:OptIn(ExperimentalUuidApi::class)

package com.polan.baklava

import kotlinx.datetime.DayOfWeek
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.LocalTime
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

// Pojedyncze punkty z aktywności przydzielone użytkownikowi
@Serializable
data class PointDto(
    var id: Uuid,
    var student: String,
    var source: ExerciseDto,
    var activityValue: Double
)

// Dane całokształtu kursu
@Serializable
data class CourseDto(
    var id: Uuid,
    var name: String,
    var instructor: String,
    var creator: String,
    var lessonTimes: Set<LessonTime>,
    var lessons: Set<LessonDto>?
)

// Dane pojedynczej sesji (lekcji)
@Serializable
data class LessonDto(
    val id: Uuid,
    val classDate: LocalDateTime,
    val courseName: String,
    val exercises: List<ExerciseDto>,
    @SerialName("status")
    val lessonStatus: LessonStatus
)

// Czas pojedynczej lekcji
@Serializable
class LessonTime (
    val dayOfWeek: DayOfWeek,
    val time: LocalTime
)

// Pojedyncza deklaracja zadań przypisana do pojedynczej sesji (lekcji)
@Serializable
data class DeclarationDto(
    val id: Uuid,
    val declarationDate: LocalDateTime,
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
    val classDate: LocalDateTime,
    val groupName: String,
    val exerciseNumber: Int,
    val subpoint: String?,
)

@Serializable
data class NewCourseDto(
    var id: Uuid,
    var name: String,
    var instructor: String,
    var lessonTimes: Set<LessonTime>,
    var students: Set<String>
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
    val dueDate: LocalDateTime,
    val numberOfDeclarations: Int,
    val assigned: Set<ExerciseDto?>
    )

@Serializable
data class LessonTimeDto (
    val dayOfWeek: Int,
    val hour: Int,
    val minute: Int
)