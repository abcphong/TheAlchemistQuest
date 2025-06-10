extends Node2D

@export var puzzle_ui_scene: PackedScene  # Dùng để chọn PuzzleUI.tscn trong editor

var puzzle_ui_instance: Node = null

func _ready():
	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_area_body_exited)
	
func _on_detection_area_body_entered(body: Node):
	if body.name == "Player":
		body.nearby_workbench = self
		print("🔵 Player entered workbench area")

func _on_detection_area_body_exited(body: Node) -> void:
	if body.name == "Player":
		body.nearby_workbench = null
		print("🔴 Player exited workbench area")
		
func open_puzzle_ui():
	print("🔵 Attempting to open puzzle UI")
	print("🔵 Puzzle UI instance exists:", puzzle_ui_instance != null)
	print("🔵 Puzzle UI scene exists:", puzzle_ui_scene != null)
	print("🔵 Any inventory open:", UserInterface.is_any_inventory_open())
	
	# First close any existing inventories
	if UserInterface.is_any_inventory_open():
		print("🔵 Closing existing inventories")
		UserInterface.close_all_inventories()
		# Wait a frame to ensure everything is closed
		await get_tree().process_frame
	
	if puzzle_ui_instance == null and puzzle_ui_scene:
		print("✅ Creating new puzzle UI instance")
		puzzle_ui_instance = puzzle_ui_scene.instantiate()
		get_tree().current_scene.add_child(puzzle_ui_instance)
		puzzle_ui_instance.connect("tree_exiting", _on_puzzle_ui_exiting)
	else:
		print("❌ Cannot open puzzle UI:")
		if puzzle_ui_instance != null:
			print("- Puzzle UI instance already exists")
		if not puzzle_ui_scene:
			print("- No puzzle UI scene assigned")

func _on_puzzle_ui_exiting():
	print("🔵 Puzzle UI is being closed")
	puzzle_ui_instance = null
