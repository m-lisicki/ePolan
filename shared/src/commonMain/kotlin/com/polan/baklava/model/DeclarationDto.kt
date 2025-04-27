package com.polan.baklava.model
import kotlinx.datetime.LocalDateTime

data class DeclarationDto(
        val id: Long,
        val declarationDate: LocalDateTime,
        val declarationStatus: DeclarationStatus,
        val exercise: ExerciseDto,
        val student: String
)