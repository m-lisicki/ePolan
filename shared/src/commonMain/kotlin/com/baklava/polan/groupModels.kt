@file:OptIn(ExperimentalUuidApi::class)

package com.baklava.polan

import kotlinx.datetime.Clock.System
import kotlinx.datetime.DayOfWeek
import kotlinx.datetime.Instant
import kotlinx.serialization.Contextual
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.Duration.Companion.days
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

@Serializable
data class PointDto(
    val id: Uuid,
    val student: String,
    val lesson: LessonDto,
    val activityValue: Double
) {
    companion object {
        fun getMockData(): List<PointDto> {
            return listOf(
                PointDto(
                    Uuid.random(),
                    "john.doe@example.com",
                    LessonDto.getMockData().first(),
                    5.0
                ),
                PointDto(
                    Uuid.random(),
                    "jane.smith@example.com",
                    LessonDto.getMockData().last(),
                    10.0
                )
            )
        }
    }
}

@Serializable
data class CourseDto(
    val id: Uuid,
    val name: String,
    val instructor: String,
    val creator: String,
    val lessonTimes: Set<LessonTime>,
    var lessons: Set<LessonDto>,
    val startDate: Instant,
    val endDate: Instant,
    val frequency: Int,
    val isArchived: Boolean,
    val courseCode: String
) {
    companion object {
        fun getMockData(): List<CourseDto> {
            val now = System.now()
            val lessonTimes = setOf(LessonTime(DayOfWeek.MONDAY), LessonTime(DayOfWeek.WEDNESDAY))
            val lessons = LessonDto.getMockData().toSet()
            return listOf(
                CourseDto(
                    Uuid.random(),
                    "Kotlin Programming",
                    "Dr. Smith",
                    "admin@example.com",
                    lessonTimes,
                    lessons,
                    now,
                    now.plus(30.days),
                    2,
                    false,
                    "KOTLIN101"
                ),
                CourseDto(
                    Uuid.random(),
                    "Android Development",
                    "Prof. Johnson",
                    "admin@example.com",
                    lessonTimes,
                    lessons,
                    now,
                    now.plus(30.days),
                    1,
                    false,
                    "ANDROID201"
                )
            )
        }
    }
}

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

    companion object {
        fun getMockData(): List<LessonDto> {
            val now = System.now()
            val exercises = ExerciseDto.getMockData().toSet()
            return listOf(
                LessonDto(Uuid.random(), now, "Kotlin Programming", exercises, LessonStatus.PAST),
                LessonDto(
                    Uuid.random(),
                    now.plus(30.days),
                    "Android Development",
                    exercises,
                    LessonStatus.FUTURE
                )
            )
        }
    }
}

@Serializable
class LessonTime(
    val dayOfWeek: DayOfWeek,
) {
    companion object {
        fun getMockData(): List<LessonTime> {
            return listOf(
                LessonTime(DayOfWeek.MONDAY),
                LessonTime(DayOfWeek.WEDNESDAY)
            )
        }
    }
}

@Serializable
data class DeclarationDto(
    val id: Uuid,
    val declarationDate: Instant,
    val declarationStatus: DeclarationStatus,
    val exercise: ExerciseDto,
    val student: String
) {
    companion object {
        fun getMockData(): List<DeclarationDto> {
            val now = System.now()
            val exercise = ExerciseDto.getMockData().first()
            return listOf(
                DeclarationDto(
                    Uuid.random(),
                    now,
                    DeclarationStatus.APPROVED,
                    exercise,
                    "john.doe@example.com"
                ),
                DeclarationDto(
                    Uuid.random(),
                    now,
                    DeclarationStatus.WAITING,
                    exercise,
                    "jane.smith@example.com"
                )
            )
        }
    }
}

@Serializable
enum class DeclarationStatus {
    WAITING,
    CANCELLED,
    REJECTED,
    APPROVED;
}

@Serializable
enum class LessonStatus {
    PAST,
    NEAR,
    FUTURE;
}

@Serializable
data class ExerciseDto(
    val id: Uuid,
    val classDate: Instant,
    val groupName: String,
    val exerciseNumber: Int,
    var subpoint: String?,
) {
    constructor(
        classDate: Instant,
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

    companion object {
        fun getMockData(): List<ExerciseDto> {
            val now = System.now()
            return listOf(
                ExerciseDto(now, "Group A", 1, "1.1"),
                ExerciseDto(now, "Group B", 2, null)
            )
        }
    }
}

@Serializable
data class NewCourseDto(
    val id: Uuid,
    val name: String,
    val instructor: String,
    val lessonTimes: Set<LessonTime>,
    val students: Set<String>,
    val startDate: Instant,
    val endDate: Instant,
    val frequency: Int
) {
    companion object {
        fun getMockData(): List<NewCourseDto> {
            val now = System.now()
            val lessonTimes = LessonTime.getMockData().toSet()
            val students = setOf("john.doe@example.com", "jane.smith@example.com")
            return listOf(
                NewCourseDto(
                    Uuid.random(),
                    "New Course 1",
                    "Instructor A",
                    lessonTimes,
                    students,
                    now,
                    now.plus(30.days),
                    3
                ),
                NewCourseDto(
                    Uuid.random(),
                    "New Course 2",
                    "Instructor B",
                    lessonTimes,
                    students,
                    now,
                    now.plus(30.days),
                    1
                )
            )
        }
    }
}

@Serializable
data class UserDto(
    val email: String,
    val name: String,
    val surname: String
) {
    companion object {
        fun getMockData(): List<UserDto> {
            return listOf(
                UserDto("john.doe@example.com", "John", "Doe"),
                UserDto("jane.smith@example.com", "Jane", "Smith")
            )
        }
    }
}

@Serializable
data class TaskDto(
    val groupId: Uuid,
    val courseName: String,
    val dueDate: Instant,
    val numberOfDeclarations: Int,
    val assigned: Set<ExerciseDto?>
) {
    companion object {
        fun getMockData(): List<TaskDto> {
            val now = System.now()
            val assignedExercises = ExerciseDto.getMockData().toSet()
            return listOf(
                TaskDto(
                    Uuid.random(),
                    "Kotlin Programming",
                    now.plus(30.days),
                    5,
                    assignedExercises
                ),
                TaskDto(
                    Uuid.random(),
                    "Android Development",
                    now.plus(30.days),
                    10,
                    assignedExercises
                )
            )
        }
    }
}

@Serializable
data class UserInfoDto(
    val email: String
) {
    companion object {
        fun getMockData(): List<UserInfoDto> {
            return listOf(
                UserInfoDto("john.doe@example.com"),
                UserInfoDto("jane.smith@example.com")
            )
        }
    }
}