extends Node2D

@export var puzzle_ui_scene: PackedScene  # Dùng để chọn PuzzleUI.tscn trong editor

var puzzle_ui_instance: Node = null

func _ready():
	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_area_body_exited)
	
func _on_detection_area_body_entered(body: Node):
	if body.name == "Player":
		body.nearby_workbench = self

func _on_detection_area_body_exited(body: Node) -> void:
	if body.name == "Player":
		body.can_interact = false
		
func open_puzzle_ui():
	if puzzle_ui_instance == null and puzzle_ui_scene:
		puzzle_ui_instance = puzzle_ui_scene.instantiate()
		get_tree().current_scene.add_child(puzzle_ui_instance)
