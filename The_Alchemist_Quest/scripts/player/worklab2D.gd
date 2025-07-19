extends Node2D

var player = null
@export var explode_scene_path: PackedScene  
var puzzle_ui: CanvasLayer = null
var is_puzzle_open: bool = false

signal player_entered(player)
signal player_exited(player)

func _ready():
	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_area_body_exited)
	print("Worklab2D - Path:", get_path(), "Position:", global_position, "Is Puzzle Open:", is_puzzle_open)
	add_to_group("workbench")

func _on_detection_area_body_entered(body: Node):
	if body.name == "Player":
		emit_signal("player_entered", body)
		body.nearby_workbench = self
		player = body
		print("Player entered workbench area")

func _on_detection_area_body_exited(body: Node):
	if body.name == "Player":
		emit_signal("player_exited", body)
		player = null
		print("Player exited workbench area")
		
func open_puzzle_ui():
	if puzzle_ui == null and explode_scene_path:
		puzzle_ui = explode_scene_path.instantiate() as CanvasLayer
		if puzzle_ui:
			get_tree().current_scene.add_child(puzzle_ui)
			is_puzzle_open = true
			
			# Assign dialog player singleton or node to puzzle_ui
			var dialog_player = get_node_or_null("/root/Game/DialogPlayerTrialPuzzle")
			if dialog_player:
				puzzle_ui.dialog_player = dialog_player
			else:
				print("⚠️ Warning: DialogPlayerTrialPuzzle not found")
			
			# Disable main inventory toggle but keep it visible
			# Gán player vào đây để điều khiển inventory sau khi puzzle đóng
			if player:
				player.can_open_main_inventory = false
				player.is_in_puzzle_mode = true
				if player.user_interface and not player.user_interface.inventory_node.visible:
					player.user_interface.toggle_inventory()
					print("Inventory opened - Visible:", player.user_interface.inventory_node.visible)
			
			# Show puzzle and immediately open dialog guide
			if puzzle_ui.has_method("show_puzzle"):
				puzzle_ui.show_puzzle()
			else:
				print("Error: Puzzle UI does not have show_puzzle method")
			
			print("✅ Puzzle UI opened - PuzzleUI Path:", puzzle_ui.get_path())
		else:
			print("❌ Error: Failed to instantiate PuzzleUI as CanvasLayer")

func close_puzzle_ui():
	if puzzle_ui:
		print("🔵 Đóng puzzle UI ")
		puzzle_ui.queue_free()
		puzzle_ui = null
		is_puzzle_open = false
		
		if player:
			player.is_in_puzzle_mode = false
			player.can_open_main_inventory = true
			print("Puzzle đã bị đóng - người chơi có thể mở lại inventory ")
		
func _process(delta):
	if is_puzzle_open and Input.is_action_just_pressed("ui_cancel"):
		close_puzzle_ui()
