package com.polan.baklava

import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*

class GroupApi(
    private val baseUrl: String = "https://your.server.com/group",
    private val client: io.ktor.client.HttpClient = HttpClientProvider.client
) {
    suspend fun createGroup(email: String, group: NewCourseDto) {
        client.post("$baseUrl/create") {
            contentType(ContentType.Application.Json)
            header("X-User-Email", email)       // or pass email in body if your API expects it
            setBody(group)
        }
    }

    suspend fun getStudentsInGroup(groupId: Long): List<String> =
        client.get("$baseUrl/$groupId/students").body()

    suspend fun addStudentToGroup(email: String, groupId: Long) {
        client.post("$baseUrl/$email/$groupId")
    }

    suspend fun deleteStudentFromGroup(email: String, groupId: Long) {
        client.delete("$baseUrl/$email/$groupId")
    }
}
