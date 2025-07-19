extends CanvasLayer

@onready var trial_puzzle = $TrialPuzzle
@onready var explode_animation = $TrialPuzzle/Explode
@onready var dialog_player = DialogPlayer


var puzzle_solved = false
var is_post_puzzle_dialog = false  # Flag to track post-puzzle dialog


func _ready():
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	if trial_puzzle:
		print("TrialPuzzle type:", trial_puzzle.get_class())
		trial_puzzle.visible = false  # Start with the puzzle hidden
		if trial_puzzle is Control:
			trial_puzzle.mouse_filter = Control.MOUSE_FILTER_IGNORE
			print("✅ Set TrialPuzzle mouse_filter to IGNORE")
		else:
			trial_puzzle.set_process_input(false)
			print("⚠️ TrialPuzzle is not a Control, skipping mouse_filter")
		if explode_animation and explode_animation is AnimatedSprite2D:
			explode_animation.visible = false
			explode_animation.connect("animation_finished", _on_explode_animation_finished)
	
	if dialog_player and not dialog_player.is_connected("dialog_finished", _on_post_puzzle_dialog_finished):
		dialog_player.connect("dialog_finished", _on_post_puzzle_dialog_finished, CONNECT_ONE_SHOT)
	
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("🟥 ESC pressed")
		var worklab2D = get_tree().root.get_node_or_null("worklab2D")
		if not worklab2D:
			worklab2D = find_worklab2D(get_tree().root)
		
		# Nếu có dialog đang bật thì tắt luôn dialog
		if dialog_player and dialog_player.in_progress:
			print("🟥 Dialog đang chạy - force finish")
			dialog_player.finish()
		
		# Dù có dialog hay không, vẫn tắt puzzle luôn
		if worklab2D and worklab2D.has_method("close_puzzle_ui"):
			worklab2D.close_puzzle_ui()
			print("🟩 ESC - Đã gọi close_puzzle_ui trên Worklab2D")
		else:
			print("❌ Worklab2D không tìm thấy hoặc thiếu close_puzzle_ui()")
		
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("turn_off_dialog"):
		if puzzle_solved and dialog_player.in_progress and is_post_puzzle_dialog:
			dialog_player.finish()
			get_viewport().set_input_as_handled()
		else:
			print("Turn off dialog ignored: puzzle not solved, not post-puzzle, or dialog not active")

func check_all_slots_filled():
	var slots = $TrialPuzzle.get_children()
	var filled_count = 0
	var total_slots = 0
	
	for child in slots:
		if child is PuzzleSlotTrial:
			total_slots += 1
			if child.is_filled:
				filled_count += 1
			print("Slot:", child.name, "Filled:", child.is_filled, "Expected Item:", child.expected_item)
	
	print("Total Slots:", total_slots, "Filled Slots:", filled_count)
	
	if filled_count == total_slots and total_slots > 0:
		if explode_animation and explode_animation is AnimatedSprite2D:
			explode_animation.visible = true
			explode_animation.play("explode")
			puzzle_solved = true
			
			# Báo cáo hoàn thành mục tiêu nhiệm vụ
			if QuestManager:
				QuestManager.reach_goal()
			else:
				push_error("QuestManager not found!")

func _on_explode_animation_finished():
	print("🔍 _on_explode_animation_finished called")
	print("🔍 Explode animation finished")
	clear_slots()
	print("🔍 Cleared slots")
	var worklab2D = get_tree().root.get_node_or_null("worklab2D")
	if worklab2D and worklab2D.has_method("close_puzzle_ui"):
		worklab2D.close_puzzle_ui()
		print("🧩 Called close_puzzle_ui on Worklab2D")
	else:
		print("❌ Error: Worklab2D not found or close_puzzle_ui method missing")
		worklab2D = find_worklab2D(get_tree().root)
		if worklab2D and worklab2D.has_method("close_puzzle_ui"):
			worklab2D.close_puzzle_ui()
	print("🔍 Worklab2D handling complete")
	
	if dialog_player and dialog_player.in_progress:
		dialog_player.finish()  # Close any active dialog before post-puzzle
	if dialog_player and not dialog_player.in_progress:
		dialog_player.set_dialog_file("res://The_Alchemist_Quest/assets/json/demo_AI_dialoge.json")
		is_post_puzzle_dialog = true
		SignalBus.emit_signal("display_puzzle_dialog", "Post_Puzzle_Sequence", null)
		print("📢 Post puzzle dialog triggered")
	
	end_puzzle_sequence()
	print("🔍 Dialog or scene change handled")

func start_dialog_sequence():
	if is_post_puzzle_dialog:
		if dialog_player and not dialog_player.in_progress:
			dialog_player.set_dialog_file("res://The_Alchemist_Quest/assets/json/demo_AI_dialoge.json")
			SignalBus.emit_signal("display_puzzle_dialog", "Post_Puzzle_Sequence", null)
			print("🔍 Triggered Post_Puzzle_Sequence dialog")
		else:
			print("❌ DialogPlayer in progress or not found, delaying map transition")
			proceed_to_map()

func find_worklab2D(node: Node) -> Node:
	if node.name == "Worklab2D":
		return node
	for child in node.get_children():
		var result = find_worklab2D(child)
		if result:
			return result
	return null

func end_puzzle_sequence():
	# Hoàn thành nhiệm vụ và chuyển cảnh
	if QuestManager:
		QuestManager.complete_current_task()

	print("🔍 Starting post-puzzle dialog sequence")
	is_post_puzzle_dialog = true
	if dialog_player and is_instance_valid(dialog_player):
		dialog_player.visible = true
		if dialog_player.in_progress:
			dialog_player.finish()  # Ensure no lingering dialog
		dialog_player.in_progress = false
		dialog_player.is_active = false
		dialog_player.set_dialog_file("res://The_Alchemist_Quest/assets/json/demo_AI_dialoge.json")
		SignalBus.emit_signal("display_puzzle_dialog", "Post_Puzzle_Sequence", null)
	else:
		print("❌ DialogPlayer not found, proceeding to map transition")
		proceed_to_map()

func _on_post_puzzle_dialog_finished():
	if puzzle_solved:
		print("🔍 Post-puzzle dialog finished, proceeding to map")
		proceed_to_map()
	else:
		print("Puzzle not solved yet, ignoring dialog finish")

func proceed_to_map():
	print("🔍 Proceeding to map")
	hide_puzzle()
	if puzzle_solved:
		# Xóa item player inventory trước kh chuyển cảnh 
		PlayerInventory.clear_inventory()
		if ScenceManager and is_instance_valid(ScenceManager):
			ScenceManager.change_scene_with_delay("res://The_Alchemist_Quest/scenes/Map/game.tscn")
		else:
			print("❌ Error: ScenceManager is invalid")
	else:
		print("Cannot proceed to map, puzzle not solved")

func clear_slots():
	var slots = $TrialPuzzle.get_children()
	for child in slots:
		if child is PuzzleSlotTrial:
			child.clear_slot()
			print("🔍 Cleared slot:", child.name)
	if explode_animation:
		explode_animation.visible = false
	trial_puzzle.visible = false

func show_puzzle():
	trial_puzzle.show()
	if dialog_player and not dialog_player.in_progress:
		dialog_player.set_dialog_file("res://The_Alchemist_Quest/assets/json/demo_AI_dialoge.json")
		SignalBus.emit_signal("display_puzzle_dialog", "Puzzle_guide", null)
		print("📢 Puzzle guide dialog triggered")
	var user_interface = get_tree().root.get_node_or_null("Game/UserInterface")
	if user_interface:
		var inventory_container = user_interface.get_node_or_null("InventoryContainer")
		if inventory_container and inventory_container.has_node("Inventory"):
			var inventory = inventory_container.get_node("Inventory")
			if not inventory.visible:
				if user_interface.has_method("toggle_inventory"):
					user_interface.toggle_inventory()
					print("📦 Opened inventory for puzzle")
			else:
				print("📦 Inventory already visible")
	if dialog_player:
		dialog_player.layer = 20
	else:
		print("❌ DialogPlayer not found for puzzle guide")

func hide_puzzle():
	clear_slots()
	trial_puzzle.hide()
	if dialog_player and dialog_player.in_progress:
		dialog_player.finish()  # Sync dialog close with puzzle
	var user_interface = get_tree().root.get_node_or_null("Game/UserInterface")
	if user_interface:
		var inventory_container = user_interface.get_node_or_null("InventoryContainer")
		if inventory_container and inventory_container.has_node("Inventory"):
			var inventory = inventory_container.get_node("Inventory")
			print("🔍 Hiding inventory, current visibility:", inventory.visible)
			if inventory.visible:
				inventory.visible = false  # Force close
				print("🔍 Inventory forced to hidden")
