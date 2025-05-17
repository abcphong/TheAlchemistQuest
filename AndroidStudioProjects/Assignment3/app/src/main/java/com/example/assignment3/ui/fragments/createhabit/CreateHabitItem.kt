package com.example.assignment3.ui.fragments.createhabit

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.DatePicker
import android.widget.EditText
import android.widget.ImageView
import android.widget.TextView
import android.widget.TimePicker
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
import androidx.navigation.fragment.findNavController
import com.example.assignment3.R
import com.example.assignment3.data.models.Habit
import com.example.assignment3.ui.viewmodels.HabitViewModel
import com.example.assignment3.utils.Calculations
import java.util.Calendar

class CreateHabitItem : Fragment(R.layout.fragment_create_habit_item),
    TimePickerDialog.OnTimeSetListener, DatePickerDialog.OnDateSetListener {

    private var title = ""
    private var description = ""
    private var drawableSelected = 0
    private var timeStamp = ""

    private var day = 0
    private var month = 0
    private var year = 0
    private var minute = 0
    private var hour = 0

    private var cleanDate:String = ""
    private var cleanTime:String = ""

    private lateinit var habitViewModel: HabitViewModel

    private lateinit var btn_confirm: Button
    private lateinit var btn_pickDate: Button
    private lateinit var btn_pickTime: Button
    private lateinit var fastfoodSelected: ImageView
    private lateinit var gameSelected: ImageView
    private lateinit var beverageSelected: ImageView
    private lateinit var tv_dateSelected: TextView
    private lateinit var tv_timeSelected: TextView
    private lateinit var et_habitDescription: EditText
    private lateinit var et_habitTitle: EditText

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        habitViewModel = ViewModelProvider(this).get(HabitViewModel::class.java)

        // Initialize views
        btn_pickDate = view.findViewById(R.id.btn_pickDate)
        btn_pickTime = view.findViewById(R.id.btn_pickTime)
        btn_confirm = view.findViewById(R.id.btn_confirm)
        fastfoodSelected = view.findViewById(R.id.iv_fastFoodSelected)
        gameSelected = view.findViewById(R.id.iv_gameSelected)
        beverageSelected = view.findViewById(R.id.iv_beverageSelected)
        et_habitDescription = view.findViewById(R.id.et_habitDescription)
        et_habitTitle = view.findViewById(R.id.et_habitTitle)
        tv_dateSelected = view.findViewById(R.id.tv_dateSelected)
        tv_timeSelected = view.findViewById(R.id.tv_timeSelected)

        btn_confirm.setOnClickListener {
             addHabitToDB()
        }
        pickDateAndTime()

        drawableSelected()
    }

    private fun drawableSelected() {
        fastfoodSelected.setOnClickListener {
            fastfoodSelected.isSelected = !fastfoodSelected.isSelected
            drawableSelected = R.drawable.baseline_fastfood_24

            gameSelected.isSelected = false
            beverageSelected.isSelected = false
        }

        gameSelected.setOnClickListener {
            gameSelected.isSelected = !gameSelected.isSelected
            drawableSelected = R.drawable.baseline_games_24

            beverageSelected.isSelected = false
            fastfoodSelected.isSelected = false
        }

        beverageSelected.setOnClickListener {
            beverageSelected.isSelected = !beverageSelected.isSelected
            drawableSelected = R.drawable.baseline_emoji_food_beverage

            fastfoodSelected.isSelected = false
            gameSelected.isSelected = false
        }
    }

    private fun addHabitToDB() {
        title = et_habitTitle.text.toString()
        description = et_habitDescription.text.toString()

        timeStamp = "$cleanDate $cleanTime"

        if (!(title.isEmpty() || description.isEmpty() || timeStamp.isEmpty() || drawableSelected ==0))
        {
            val habit = Habit(0,title, description,timeStamp,drawableSelected)

            habitViewModel.addHabit(habit)
            Toast.makeText(context, "Habit created successfully!", Toast.LENGTH_SHORT).show()

            findNavController().navigate(R.id.action_createHabitItem_to_habitList)
        }
        else{
            Toast.makeText(context, "Please fill all the fields", Toast.LENGTH_SHORT).show()
        }
    }

    private fun pickDateAndTime()
    {
        btn_pickDate.setOnClickListener {
            getDateCalendar()
            DatePickerDialog(requireContext(), this, year, month, day).show()
        }

        btn_pickTime.setOnClickListener {
            getTimeCalendar()
            TimePickerDialog(requireContext(), this, hour, minute, true).show()
        }
    }

    override fun onTimeSet(view: TimePicker?, hourOfDay: Int, minute: Int) {
       cleanTime = Calculations.cleanTime(hourOfDay, minute)
        tv_timeSelected.text = "Time: $cleanTime"
    }

    override fun onDateSet(view: DatePicker?, yearX: Int, monthX: Int, dayX: Int) {
        cleanDate = Calculations.cleanDate(dayX, monthX, yearX)
        tv_dateSelected.text = "Date: $cleanDate"
    }

    private fun getTimeCalendar(){
        val cal = Calendar.getInstance()
        hour = cal.get(Calendar.HOUR_OF_DAY)
        minute = cal.get(Calendar.MINUTE)
    }

    private fun getDateCalendar(){
        val cal = Calendar.getInstance()
        day = cal.get(Calendar.DAY_OF_MONTH)
        month = cal.get(Calendar.MONTH)
        year = cal.get(Calendar.YEAR)
    }
}
