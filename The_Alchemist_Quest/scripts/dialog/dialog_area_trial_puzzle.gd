extends Area2D

@export var dialog_key: String = "Puzzle_guide"  # Set this in the inspector
@onready var puzzle_ui = $".."
@export_file("*.json") var dialog_file 
var area_active = false

func _on_body_entered(body):
	if body.name == "Player":
		DialogPlayer.set_dialog_file(dialog_file)
		puzzle_ui.show_puzzle()
		SignalBus.emit_signal("display_dialog", dialog_key, null)
		print("Triggered puzzle guide dialog")

func _on_body_exited(body):
	if body.name == "Player":
		puzzle_ui.hide_puzzle()
