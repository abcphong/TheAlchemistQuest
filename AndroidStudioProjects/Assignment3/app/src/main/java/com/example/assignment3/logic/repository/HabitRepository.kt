package com.example.assignment3.logic.repository

import androidx.lifecycle.LiveData
import com.example.assignment3.data.models.Habit
import com.example.assignment3.logic.dao.HabitDao

class HabitRepository(private val habitDao: HabitDao) {
    val getAllHabits: LiveData<List<Habit>> = habitDao.getAllHabits()

    // Inserts a new habit
    suspend fun addHabit(habit: Habit) {
        habitDao.addHabit(habit)
    }

    //Updates an existing habit.
    suspend fun updateHabit(habit: Habit) {
        habitDao.updateHabit(habit)
    }

    //Deletes a specific habit from the database.
    suspend fun deleteHabit(habit: Habit) {
        habitDao.deleteHabit(habit)
    }

    //Deletes all habits from the database.
    suspend fun deleteAllHabits()  {
        habitDao.deleteAll()
    }

}