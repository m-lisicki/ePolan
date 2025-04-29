@file:OptIn(ExperimentalUuidApi::class)

package com.polan.baklava

import io.ktor.client.*
import io.ktor.client.call.body
import io.ktor.client.engine.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.delete
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import io.ktor.serialization.kotlinx.json.*
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

    const val BASE_URL = "http://localhost:8080"
}

class DBCommunicationServices(val token: String) {

    @Throws(Throwable::class)
    // Create a new course on the server
    suspend fun createCourse(
        name: String,
        instructor: String,
        lessonTimeDtos: Set<LessonTimeDto>,
        students: Set<String>
    ): CourseDto {
        val lessonTimes = lessonTimeDtos.map { it.toLessonTime() }.toSet()

        val payload = NewCourseDto(Uuid.random(), name, instructor, lessonTimes, students)
        val response = ApiClient.client.post("${ApiClient.BASE_URL}/course/create") {
            header(HttpHeaders.Authorization, "Bearer $token")
            contentType(ContentType.Application.Json)
            setBody(payload)
        }
        print(response)

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
    // Get all courses from the server
    suspend fun getAllCourses(): Set<CourseDto> {
        val response = ApiClient.client.get("${ApiClient.BASE_URL}/course/courses") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }

        print(response)

        return response.body()
    }

    @Throws(Throwable::class)
    suspend fun getAllExercises(lessonId: Uuid): List<ExerciseDto> {
        val response = ApiClient.client.get("${ApiClient.BASE_URL}/$lessonId/exercises") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }
        print(response)

        return response.body()
    }

    @Throws(Throwable::class)
    suspend fun getAllLessons(courseId: Uuid): List<LessonDto> {
        val response = ApiClient.client.get("${ApiClient.BASE_URL}/$courseId/lessons") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }
        print(response)

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
    suspend fun postUnDeclaration(exerciseId: Uuid) : Int {
        val response = ApiClient.client.post("${ApiClient.BASE_URL}/undeclaration/$exerciseId") {
            header(HttpHeaders.Authorization, "Bearer $token")
        }

        return response.status.value
    }
}
