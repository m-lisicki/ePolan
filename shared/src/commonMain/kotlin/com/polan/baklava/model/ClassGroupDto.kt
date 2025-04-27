package com.polan.baklava.model

data class ClassGroupDto(
    var id: Long,
    var name: String,
    var instructor: String,
    var creator: String,
    var classTimes: Set<ClassTime>,
    var sessions: Set<ClassSessionDto>
)