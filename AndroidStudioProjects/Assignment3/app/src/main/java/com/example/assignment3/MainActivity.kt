package com.example.assignment3

import android.content.Intent
import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar
import androidx.navigation.Navigation.findNavController
import androidx.navigation.findNavController
import androidx.navigation.fragment.NavHostFragment
import androidx.navigation.fragment.findNavController
import androidx.navigation.ui.setupActionBarWithNavController
import com.example.assignment3.ui.introscreen.IntroActivity

class MainActivity : AppCompatActivity() {

    private var userFirstTime = true

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        //Checks whether it's the users first time
        loadData()

        //If it's the users first time, it will store that the user saw the intro screen, and ignore this the next time
        if (!userFirstTime) {
            userFirstTime = false
            saveData()

            val i = Intent(this, IntroActivity::class.java)
            startActivity(i)
            finish()
        }

        val toolbar = findViewById<Toolbar>(R.id.toolbar)
        setSupportActionBar(toolbar)

        val navHostFragment = supportFragmentManager.findFragmentById(R.id.navHostFragment) as NavHostFragment
        val navController = navHostFragment.navController
        setupActionBarWithNavController(navController)
    }

    override fun onSupportNavigateUp(): Boolean {
        val navHostFragment = supportFragmentManager.findFragmentById(R.id.navHostFragment) as NavHostFragment
        val navController = navHostFragment.navController
        return navController.navigateUp() || super.onSupportNavigateUp()
    }


    private fun saveData() {
        val sp = getSharedPreferences("SHARED_PREFS", MODE_PRIVATE)
        sp.edit().apply {
            putBoolean("BOOLEAN_FIRST_TIME", userFirstTime)
            apply()
        }
    }

    private fun loadData() {
        val sp = getSharedPreferences("SHARED_PREFS", MODE_PRIVATE)
        userFirstTime = sp.getBoolean("BOOLEAN_FIRST_TIME", true)

    }
}
