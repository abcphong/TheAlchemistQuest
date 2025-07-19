extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var dialog_player = $DialogPlayerTrialPuzzle
	dialog_player.scence_text_file = "res://The_Alchemist_Quest/assets/json/demo_AI_dialoge.json"
	if not dialog_player.scence_text.has("Puzzle_guide"):
		printerr("Missing Puzzle_guide in dialog JSON")
