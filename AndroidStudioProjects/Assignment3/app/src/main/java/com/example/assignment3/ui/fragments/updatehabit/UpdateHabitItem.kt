package com.example.assignment3.ui.fragments.updatehabit

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import android.os.Bundle
import android.view.Menu
import android.view.MenuInflater
import android.view.MenuItem
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
import androidx.navigation.fragment.navArgs
import com.example.assignment3.R
import com.example.assignment3.data.models.Habit
import com.example.assignment3.ui.viewmodels.HabitViewModel
import com.example.assignment3.utils.Calculations
import java.util.Calendar

class UpdateHabitItem : Fragment(R.layout.fragment_update_habit_item),
    TimePickerDialog.OnTimeSetListener,
    DatePickerDialog.OnDateSetListener {

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

    private val args by navArgs<UpdateHabitItemArgs>()

    private lateinit var btn_confirm_update: Button
    private lateinit var btn_pickDate_update: Button
    private lateinit var btn_pickTime_update: Button
    private lateinit var fastfoodSelected_update: ImageView
    private lateinit var gameSelected_update: ImageView
    private lateinit var beverageSelected_update: ImageView
    private lateinit var tv_dateSelected_update: TextView
    private lateinit var tv_timeSelected_update: TextView
    private lateinit var et_habitDescription_update: EditText
    private lateinit var et_habitTitle_update: EditText

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {

        habitViewModel = ViewModelProvider(this).get(HabitViewModel::class.java)

        et_habitTitle_update = view.findViewById(R.id.et_habitTitle_update)
        et_habitDescription_update = view.findViewById(R.id.et_habitDescription_update)
        btn_confirm_update = view.findViewById(R.id.btn_confirm_update)
        btn_pickDate_update = view.findViewById(R.id.btn_pickDate_update)
        btn_pickTime_update = view.findViewById(R.id.btn_pickTime_update)
        fastfoodSelected_update = view.findViewById(R.id.iv_fastFoodSelected_update)
        gameSelected_update =view.findViewById(R.id.iv_gameSelected_update)
        beverageSelected_update = view.findViewById(R.id.iv_beverageSelected_update)
        tv_dateSelected_update = view.findViewById(R.id.tv_dateSelected_update)
        tv_timeSelected_update = view.findViewById(R.id.tv_timeSelected_update)


        et_habitTitle_update.setText(args.selectedHabit.habit_title)
        et_habitDescription_update.setText(args.selectedHabit.habit_description)

        drawableSelected()

        pickDateAndTime()

        btn_confirm_update.setOnClickListener{
            updateHabit()
        }

        setHasOptionsMenu(true)
    }

    private fun updateHabit(){
        title = et_habitTitle_update.text.toString()
        description = et_habitDescription_update.text.toString()

        timeStamp = "$cleanDate $cleanTime"

        if (!(title.isEmpty() || description.isEmpty() || timeStamp.isEmpty() || drawableSelected ==0))
        {
            val habit = Habit(args.selectedHabit.id, title, description, timeStamp, drawableSelected)

            habitViewModel.updateHabit(habit)
            Toast.makeText(context,"Habit updated successfully!", Toast.LENGTH_SHORT).show()

            findNavController().navigate(R.id.action_updateHabitItem_to_habitList)
        }
        else
        {
            Toast.makeText(context, "Please fill all the fields", Toast.LENGTH_SHORT).show()
        }

    }

    private fun drawableSelected() {
        fastfoodSelected_update.setOnClickListener {
            fastfoodSelected_update.isSelected = !fastfoodSelected_update.isSelected
            drawableSelected = R.drawable.baseline_fastfood_24

            gameSelected_update.isSelected = false
            beverageSelected_update.isSelected = false
        }

        gameSelected_update.setOnClickListener {
            gameSelected_update.isSelected = !gameSelected_update.isSelected
            drawableSelected = R.drawable.baseline_games_24

            beverageSelected_update.isSelected = false
            fastfoodSelected_update.isSelected = false
        }

        beverageSelected_update.setOnClickListener {
            beverageSelected_update.isSelected = !beverageSelected_update.isSelected
            drawableSelected = R.drawable.baseline_emoji_food_beverage

            fastfoodSelected_update.isSelected = false
            gameSelected_update.isSelected = false
        }
    }

    private fun pickDateAndTime()
    {
        btn_pickDate_update.setOnClickListener {
            getDateCalendar()
            DatePickerDialog(requireContext(), this, year, month, day).show()
        }

        btn_pickTime_update.setOnClickListener {
            getTimeCalendar()
            TimePickerDialog(requireContext(), this, hour, minute, true).show()
        }
    }


    override fun onTimeSet(view: TimePicker?, hourOfDay: Int, minute: Int) {
        cleanTime = Calculations.cleanTime(hourOfDay, minute)
        tv_timeSelected_update.text = "Time: $cleanTime"
    }

    override fun onDateSet(view: DatePicker?, yearX: Int, monthX: Int, dayX: Int) {
        cleanDate = Calculations.cleanDate(dayX, monthX, yearX)
        tv_dateSelected_update.text = "Date: $cleanDate"
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

    override fun onCreateOptionsMenu(menu: Menu, inflater: MenuInflater){
        inflater.inflate(R.menu.single_item_menu, menu)
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when(item.itemId){
            R.id.nav_delete -> deleteHabit(args.selectedHabit)
        }
        return super.onOptionsItemSelected(item)
    }

    private fun deleteHabit(habit: Habit){
        habitViewModel.deleteHabit(habit)
        Toast.makeText(context, "Habit successfully deleted!", Toast.LENGTH_SHORT).show()

        findNavController().navigate(R.id.action_updateHabitItem_to_habitList)
    }
}