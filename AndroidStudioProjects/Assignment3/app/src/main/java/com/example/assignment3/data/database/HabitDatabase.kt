package com.example.assignment3.data.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.example.assignment3.data.models.Habit
import com.example.assignment3.logic.dao.HabitDao

// Database
@Database(entities = [Habit::class], version = 1, exportSchema = false)
abstract class HabitDatabase : RoomDatabase(){

    abstract fun habitDao() :HabitDao

    companion object{
        @Volatile
        private var  INSTANCE: HabitDatabase? = null

        //Get database
        fun getDatabase(context:Context): HabitDatabase{
            val tempInstance:HabitDatabase? = INSTANCE
            if (tempInstance != null){
                return tempInstance
            }
            synchronized(this){
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    HabitDatabase::class.java,
                    "habit_database"
                ).build()
                INSTANCE = instance
                return instance
            }
        }
    }
}