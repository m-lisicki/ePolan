package com.polan.baklava.model

import kotlinx.datetime.LocalDateTime

data class ExerciseDto(
        val id: Long,
        val classDate: LocalDateTime,
        val groupName: String,
        val exerciseNumber: Int,
        val subpoint: String,
        val name: String,
        val instructor: String,
        val creator: String,
        val classTimes: Set<ClassTime>
)
