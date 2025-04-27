package com.polan.baklava.model

data class ActivityDto(
        var id: Long,
        var student: String,
        var source: ExerciseDto,
        var activityValue: Double
)