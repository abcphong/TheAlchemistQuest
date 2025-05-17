package com.example.assignment3.ui.introscreen

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.example.assignment3.R
import com.example.assignment3.data.models.IntroView

class ViewPagerAdapter(introViews:List<IntroView>) : RecyclerView.Adapter<ViewPagerAdapter.IntroViewHolder>(){

    class IntroViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView)
    {
        val iv_image_intro: ImageView = itemView.findViewById(R.id.iv_image_intro)
        val tv_description_intro: TextView = itemView.findViewById(R.id.tv_description_intro)
    }

    private val list = introViews


    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): IntroViewHolder{
        return IntroViewHolder(LayoutInflater.from(parent.context).inflate(R.layout.intro_item_page,parent,false))
    }

    override fun onBindViewHolder(holder: IntroViewHolder, position: Int) {

        val currentView = list[position]
        holder.iv_image_intro.setImageResource(currentView.imageId)
        holder.tv_description_intro.text = currentView.description
    }

    override fun getItemCount(): Int {
        return list.size
    }

}