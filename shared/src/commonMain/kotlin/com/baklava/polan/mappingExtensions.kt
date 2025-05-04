package com.baklava.polan

import kotlinx.datetime.DayOfWeek

fun convertShortWeekdaySymbolsToLessonTimeSet(
    swiftShortSymbols: Set<String>): Set<LessonTime> {
    val isoOrdered = listOf(
        DayOfWeek.SUNDAY,
        DayOfWeek.MONDAY,
        DayOfWeek.TUESDAY,
        DayOfWeek.WEDNESDAY,
        DayOfWeek.THURSDAY,
        DayOfWeek.FRIDAY,
        DayOfWeek.SATURDAY
    )

    val lookup = swiftShortSymbols.map { it.lowercase() }.toSet()

    return isoOrdered
        .filter { day -> lookup.contains(day.name.take(3).lowercase()) }
        .map { LessonTime(it) }
        .toSet()
}