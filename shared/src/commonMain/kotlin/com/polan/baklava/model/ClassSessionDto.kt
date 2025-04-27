package com.polan.baklava.model
import kotlinx.datetime.LocalDateTime

data class ClassSessionDto(
    var id: Long,
    var classDate: LocalDateTime,
    var classGroupName: String
)
