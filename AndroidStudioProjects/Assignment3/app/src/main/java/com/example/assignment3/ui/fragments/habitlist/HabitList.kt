package com.example.assignment3.ui.fragments.habitlist

import android.os.Bundle
import android.view.LayoutInflater
import android.view.Menu
import android.view.MenuInflater
import android.view.MenuItem
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.navigation.fragment.findNavController
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import com.example.assignment3.R
import com.example.assignment3.data.models.Habit
import com.example.assignment3.ui.fragments.habitlist.adapter.HabitListAdapter
import com.example.assignment3.ui.viewmodels.HabitViewModel
import com.google.android.material.floatingactionbutton.FloatingActionButton

class HabitList : Fragment(R.layout.fragment_habit_list) {

    private lateinit var tv_emptyView: TextView
    private lateinit var rv_habits: RecyclerView
    private lateinit var habitList:List<Habit>
    private lateinit var habitViewModel: HabitViewModel
    private lateinit var adapter: HabitListAdapter
    private lateinit var swipeToRefresh: SwipeRefreshLayout

    val fabAdd = view?.findViewById<FloatingActionButton>(R.id.fab_add)

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {

        rv_habits = view.findViewById(R.id.rv_habits)
        swipeToRefresh = view.findViewById(R.id.swipeToRefresh)
        tv_emptyView = view.findViewById(R.id.tv_emptyView)

        //Adapter
        adapter = HabitListAdapter()
        rv_habits.adapter = adapter
        rv_habits.layoutManager = LinearLayoutManager(context)

        //ViewModel
        habitViewModel = ViewModelProvider(this).get(HabitViewModel::class.java)

        habitViewModel.getAllHabits.observe(viewLifecycleOwner, {
            adapter.setData(it)
            habitList = it

            if(it.isEmpty()){
                rv_habits.visibility= View.GONE
                tv_emptyView.visibility = View.VISIBLE
            }
            else{
                rv_habits.visibility= View.VISIBLE
                tv_emptyView.visibility = View.GONE
            }
        })

        setHasOptionsMenu(true)

        swipeToRefresh.setOnRefreshListener {
            adapter.setData(habitList)
            swipeToRefresh.isRefreshing = false
        }

        view.findViewById<FloatingActionButton>(R.id.fab_add)?.setOnClickListener {
            findNavController().navigate(R.id.action_habitList_to_createHabitItem)
        }
    }
    override fun onCreateOptionsMenu(menu: Menu, inflater: MenuInflater) {
        inflater.inflate(R.menu.nav_main, menu)
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {
            R.id.nav_delete -> habitViewModel.deleteAllHabits()
        }
        return super.onOptionsItemSelected(item)
    }
}