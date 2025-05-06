@file:OptIn(ExperimentalUuidApi::class)

package com.baklava.polan

import io.ktor.client.*
import io.ktor.client.call.body
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.delete
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.request.post
import io.ktor.client.request.put
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.contentType
import io.ktor.serialization.kotlinx.json.*
import kotlinx.datetime.Instant
import kotlinx.serialization.json.Json
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

object ApiClient {

    val client = HttpClient {
        install(ContentNegotiation) {
            json(Json {
                prettyPrint = true
                isLenient = true
                ignoreUnknownKeys = true // drop any extra fields
            })
        }
    }

    const val IP = "192.168.254.134"
    const val BASE_URL = "http://$IP:8080"
    const val KEYCLOAK_URL = "http://$IP:8280"
}

class DBCommunicationServices(token: String) {
    var token: String = token
        set(value: String) {
            field = value
        }
        get() = field

    @Throws(Throwable::class)
    suspend fun createCourse(
        name: String,
        instructor: String,
        swiftShortSymbols: Set<String>,
        students: Set<String>,
        startDateISO: String,
        endDateISO: String,
        frequency: Int
    ): CourseDto {
        val payload = NewCourseDto(Uuid.random(), name, instructor, convertShortWeekdaySymbolsToLessonTimeSet(swiftShortSymbols), students, Instant.parse(startDateISO), Instant.parse(endDateISO), frequency)
        
        val response = ApiClient.client.post("${ApiClient.BASE_URL}/course/create") {
            header(HttpHeaders.Authorization, "Bearer $token")
            contentType(ContentType.Application.Json)
            setBody(payload)
        }

        return response.body()
    }

    @Throws(Throwable::class)
    suspend fun getAllStudents(courseId: Uuid): Set<String> {
        val response = ApiClient.client.get("${ApiClient.BASE_URL}/course/$courseId/students") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }

        return response.body()
    }

    @Throws(Throwable::class)
    suspend fun addStudent(courseId: Uuid, email: String): Int {
        val response = ApiClient.client.post("${ApiClient.BASE_URL}/course/$email/$courseId") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }

        return response.status.value
    }

    @Throws(Throwable::class)
    suspend fun removeStudent(courseId: Uuid, email: String): Int {
        val response = ApiClient.client.delete("${ApiClient.BASE_URL}/course/$email/$courseId") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }

        return response.status.value
    }

    @Throws(Throwable::class)
    suspend fun getAllCourses(): Set<CourseDto> {
        val response = ApiClient.client.get("${ApiClient.BASE_URL}/course/courses") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }
        
        return response.body()
    }

    @Throws(Throwable::class)
    suspend fun getAllExercises(lessonId: Uuid): List<ExerciseDto> {
        val response = ApiClient.client.get("${ApiClient.BASE_URL}/lesson/$lessonId/exercises") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }
        

        return response.body()
    }

    @Throws(Throwable::class)
    suspend fun getAllLessons(courseId: Uuid): List<LessonDto> {
        val response = ApiClient.client.get("${ApiClient.BASE_URL}/lesson/$courseId/lessons") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }
        

        return response.body()
    }

    @Throws(Throwable::class)
    suspend fun getAllLessonDeclarations(lessonId: Uuid): Set<DeclarationDto> {
        val response = ApiClient.client.get("${ApiClient.BASE_URL}/declaration/lesson/$lessonId") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }
        if (response.status.value == 404) {
            return emptySet()
        }
        return response.body()
    }

    @Throws(Throwable::class)
    suspend fun postDeclaration(exerciseId: Uuid) : Int {
        val response = ApiClient.client.post("${ApiClient.BASE_URL}/declaration/$exerciseId") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }

        return response.status.value
    }

    @Throws(Throwable::class)
    suspend fun postUnDeclaration(declarationId: Uuid) : Int {
        val response = ApiClient.client.delete("${ApiClient.BASE_URL}/declaration/$declarationId") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }

        return response.status.value
    }

    @Throws(Throwable::class)
    suspend fun getPoints(courseId: Uuid) : Int {
        val response = ApiClient.client.get("${ApiClient.BASE_URL}/points/$courseId/howMany") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }

        return response.body()
    }

    @Throws(Throwable::class)
    suspend fun getPointsForCourse(courseId: Uuid) : List<PointDto> {
        val response = ApiClient.client.get("${ApiClient.BASE_URL}/points/$courseId") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }

        return response.body()
    }

    @Throws(Throwable::class)
    suspend fun addPoints(lessonId: Uuid, activityValue: Double) : Int {

        val response = ApiClient.client.post("${ApiClient.BASE_URL}/points/$lessonId/$activityValue") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }

        return response.status.value
    }

    @Throws(Throwable::class)
    suspend fun getUserEmail(): String {
        val userInfo: UserInfoDto = ApiClient.client
          .get("${ApiClient.KEYCLOAK_URL}/realms/Users/protocol/openid-connect/userinfo") {
            header(HttpHeaders.Authorization, "Bearer $token")
          }
          .body()
        return userInfo.email
    }

    @Throws(Throwable::class)
    suspend fun addLesson(courseId: Uuid, exercisesAmount: Int) : Int {
        val response = ApiClient.client.post("${ApiClient.BASE_URL}/create/$courseId/$exercisesAmount") {
            header(HttpHeaders.Authorization, "Bearer $token")
            contentType(ContentType.Application.Json)
            setBody(exercisesAmount)
        }

        return response.status.value
    }

    @Throws(Throwable::class)
    suspend fun deleteLesson(lessonId: Uuid) : Int {
        val response = ApiClient.client.delete("${ApiClient.BASE_URL}/lesson/$lessonId") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }

        return response.status.value
    }

    @Throws(Throwable::class)
    suspend fun postExercises(lesson: LessonDto) : Int {
        val response = ApiClient.client.put("${ApiClient.BASE_URL}/lesson/exercises") {
            header(HttpHeaders.Authorization, "Bearer $token")
            contentType(ContentType.Application.Json)
            setBody(lesson)
        }

        return response.status.value
    }

    @Throws(Throwable::class)
    suspend fun archiveCourse(courseId: Uuid) : Int {
        val response = ApiClient.client.delete("${ApiClient.BASE_URL}/course/$courseId") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }

        return response.status.value
    }

    @Throws(Throwable::class)
    suspend fun manualAddLesson(courseId: Uuid, date: String) : LessonDto {
        val response = ApiClient.client.post("${ApiClient.BASE_URL}/lesson/$courseId/${Instant.parse(date)}/addLesson") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }

        return response.body()
    }

    @Throws(Throwable::class)
    suspend fun joinCourse(invitationCode: String) : Int {
        val response = ApiClient.client.post("${ApiClient.BASE_URL}/course/$invitationCode") {
            header(HttpHeaders.Authorization, "Bearer $token")
    }
        return response.status.value
    }
}
