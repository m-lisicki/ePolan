package com.polan.baklava

import io.ktor.client.*
import io.ktor.client.engine.*
// import io.ktor.client.engine.cio.*      // Android
// import io.ktor.client.engine.darwin.*   // iOS
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

expect fun httpClientEngine(): HttpClientEngine

object HttpClientProvider {
    val client = HttpClient(httpClientEngine()) {
        install(ContentNegotiation) {
            json(Json {
                prettyPrint = true
                ignoreUnknownKeys = true
            })
        }
    }
}