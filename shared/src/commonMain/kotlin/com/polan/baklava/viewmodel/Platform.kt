package com.polan.baklava

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform