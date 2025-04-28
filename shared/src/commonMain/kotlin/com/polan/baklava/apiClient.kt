@file:OptIn(ExperimentalUuidApi::class)

package com.polan.baklava

import io.ktor.client.*
import io.ktor.client.call.body
import io.ktor.client.engine.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.get
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

expect fun httpClientEngine(): HttpClientEngine

object ApiClient {

    //Ewentualnie darwin?
    val client = HttpClient(httpClientEngine()) {
        install(ContentNegotiation) {
            json(Json {
                prettyPrint = true
                ignoreUnknownKeys = true
            })
        }
    }

    const val BASE_URL = "http://localhost:8080/api"
}

class Posts {
    /** Create a new course on the server */
    suspend fun createCourse(
        name: String,
        instructor: String,
        lessonTimeDtos: Set<LessonTimeDto>
    ): CourseDto {
        val lessonTimes = lessonTimeDtos.map { it.toLessonTime() }.toSet()

        val payload = NewCourseDto(Uuid.random(), name, instructor, lessonTimes)
        return ApiClient.client.post("${ApiClient.BASE_URL}/courses") {
            contentType(ContentType.Application.Json)
            setBody(payload)
        }.body()
    }

    /** Register a new declaration */
    suspend fun postDeclaration(declaration: DeclarationDto): DeclarationDto {
        return ApiClient.client.post("${ApiClient.BASE_URL}/declarations") {
            contentType(ContentType.Application.Json)
            setBody(declaration)
        }.body()
    }
}

class Gets {
    /** Fetch all courses */
    suspend fun getCourses(): List<CourseDto> =
        ApiClient.client.get("${ApiClient.BASE_URL}/courses").body()

    /** Fetch exercises for a given course/lesson */
    suspend fun getExercises(
        courseId: Uuid,
        lessonId: Long
    ): List<ExerciseDto> =
        ApiClient.client
            .get("${ApiClient.BASE_URL}/courses/$courseId/lessons/$lessonId/exercises")
            .body()
}