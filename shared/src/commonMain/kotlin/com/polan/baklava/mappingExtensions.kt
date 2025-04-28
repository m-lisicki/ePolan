package com.polan.baklava

import kotlinx.datetime.DayOfWeek
import kotlinx.datetime.LocalTime

fun LessonTimeDto.toLessonTime(): LessonTime =
    LessonTime(
        dayOfWeek = DayOfWeek.entries[dayOfWeek],
        time      = LocalTime(hour, minute)
    )