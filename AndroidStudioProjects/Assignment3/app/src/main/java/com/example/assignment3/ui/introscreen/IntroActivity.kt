package com.example.assignment3.ui.introscreen

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.viewpager2.widget.ViewPager2
import com.example.assignment3.MainActivity
import com.example.assignment3.R
import com.example.assignment3.data.models.IntroView
import me.relex.circleindicator.CircleIndicator3

class IntroActivity : AppCompatActivity() {

    private lateinit var btn_start_app: Button
    private lateinit var viewPager2: ViewPager2
    private lateinit var circleIndicator: CircleIndicator3

    lateinit var introView: List<IntroView>
    override fun onCreate(savedInstanceState: Bundle?) {

        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_intro)

        btn_start_app = findViewById(R.id.btn_start_app)
        viewPager2 = findViewById(R.id.viewPager2)
        circleIndicator = findViewById(R.id.circleIndicator)

        addToIntroView()

        viewPager2.adapter = ViewPagerAdapter(introView)
        viewPager2.orientation = ViewPager2.ORIENTATION_HORIZONTAL

        circleIndicator.setViewPager(viewPager2)

        viewPager2.registerOnPageChangeCallback(object : ViewPager2.OnPageChangeCallback() {
            override fun onPageScrolled(
                position: Int,
                positionOffset: Float,
                positionOffsetPixels: Int
            ) {
                if (position == 2) {
                    animationButton()
                }
                super.onPageScrolled(position, positionOffset, positionOffsetPixels)
            }
        })
    }

    private fun animationButton() {
        btn_start_app.visibility = View.VISIBLE

        btn_start_app.animate().apply {
            duration = 1400
            alpha(1f)

            btn_start_app.setOnClickListener {
                val intent = Intent(applicationContext, MainActivity::class.java)
                startActivity(intent)
                finish()
            }
        }.start()
    }

    private fun addToIntroView(){
        introView = listOf(
            IntroView("Welcome to Habit Tracker!", R.drawable.baseline_emoji_food_beverage),
            IntroView("This is the second page",R.drawable.baseline_games_24),
            IntroView("This is the third pasge", R.drawable.baseline_fastfood_24)
        )
    }
}
