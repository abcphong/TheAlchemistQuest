package com.example.assignment3.logic.dao


import androidx.activity.result.contract.ActivityResultContracts.PickVisualMedia.DefaultTab.AlbumsTab.value
import androidx.lifecycle.LiveData
import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.example.assignment3.data.models.Habit

// Data access only
@Dao
interface HabitDao {
    //Inserts a new habit; ignores duplicates using
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun addHabit(habit: Habit)

    //Updates an existing habit.
    @Update
    suspend fun updateHabit(habit: Habit)

    //Deletes a specific habit from the database.
    @Delete
    suspend fun deleteHabit(habit: Habit)

    //Retrieves all habits in ascending order of ID
    @Query("SELECT * FROM habit_table ORDER BY id ASC")
    fun getAllHabits(): LiveData<List<Habit>>

    //Deletes all habits from the database.
    @Query("DELETE FROM habit_table")
    suspend fun deleteAll()
}