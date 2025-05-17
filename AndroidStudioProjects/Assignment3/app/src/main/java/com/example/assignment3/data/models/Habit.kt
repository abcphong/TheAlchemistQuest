package com.example.assignment3.data.models

import android.os.Parcelable
import androidx.room.Entity
import androidx.room.PrimaryKey
import kotlinx.parcelize.Parcelize

//Parcelable database
@Parcelize
@Entity(tableName = "habit_table")

data class Habit(
    @PrimaryKey(autoGenerate = true)
    val id:Int,
    val habit_title:String,
    val habit_description:String,
    val habit_startTime:String,
    val imageId:Int
)
    : Parcelable