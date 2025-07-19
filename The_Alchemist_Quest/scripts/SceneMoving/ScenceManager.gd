extends Node

const TRANSITION_DELAY = 3.0 # 3 seconds delay before fade
const FADE_DURATION = 1.0 # Match AnimationPlayer durartion

var current_transition: ScreenTransition = null


func change_scene_with_delay(scene_path: String):
	# Wait for delay (player can still move/act)
	await get_tree().create_timer(TRANSITION_DELAY).timeout
	# Instantiate and add transition
	current_transition = preload("res://The_Alchemist_Quest/scences/SceneMoving/screen_transition.tscn").instantiate()
	get_tree().root.add_child(current_transition)
	
	#Play fade and wait for completion 
	current_transition.fade_out()
	await current_transition.transition_completed
	
	#Load new scene
	get_tree().change_scene_to_file("res://The_Alchemist_Quest/scences/Map/game.tscn") # MOVE TO NEW MAP
	
	# Clean up 
	current_transition.queue_free()
