extends Panel
class_name PuzzleSlotTrial

@export var expected_item: String = ""  # Tên item đúng để kiểm tra
var is_filled := false

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("PuzzleSlotTrial")
	if not $ItemIcon is TextureRect:
		print("❌ Error: $ItemIcon is not a TextureRect in", name)
	
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 0
	$ItemIcon.z_index = 10
	$ItemIcon.visible = true
	$ItemIcon.modulate = Color(1, 1, 1, 1)
	$ItemIcon.expand = true
	$ItemIcon.stretch_mode = TextureRect.STRETCH_SCALE
	$ItemIcon.position = Vector2(0, 0)
	$ItemIcon.size = Vector2(52, 52)
	size = Vector2(52, 52)
	clip_contents = false
	
	# Debug properties
	var parent_layer = get_parent().get_parent().layer if get_parent() and get_parent().get_parent() else "unknown"
	print("PuzzleSlotTrial - Name:", name, "Size:", size, "Position:", global_position, "Z-Index:", z_index, "Layer:", parent_layer)
	print("ItemIcon - Size:", $ItemIcon.size, "Position:", $ItemIcon.position, "Z-Index:", $ItemIcon.z_index)

func _gui_input(event: InputEvent):
	print("🔍 _gui_input called on", name, "with event:", event)
	# Fallback logging; main logic is in process_drop

func process_drop(held_item: Node, drop_position: Vector2):
	print("🔍 process_drop called on", name, "with held_item:", held_item, "item_name:", held_item.item_name if held_item else "null", "at position:", drop_position)
	if held_item and not is_filled:
		print("🔍 Checking item:", held_item.item_name, "against expected:", expected_item)
		if held_item.item_name == expected_item:
			var texture_rect = held_item.get_node_or_null("TextureRect")
			if texture_rect and texture_rect.texture:
				var item_texture = texture_rect.texture.duplicate()
				print("✅ Đặt đúng item:", held_item.item_name, "vào", name, "Texture:", item_texture)
				$ItemIcon.texture = item_texture
				$ItemIcon.visible = true
				$ItemIcon.size = size
				$ItemIcon.position = Vector2(0, 0)
				# Debug rendering properties
				print("ItemIcon after drop - Visible:", $ItemIcon.visible, "Size:", $ItemIcon.size, "Texture:", $ItemIcon.texture)
				is_filled = true
				print("🔍 Set is_filled to true for", name)
				var puzzle_ui = get_puzzle_ui()
				if puzzle_ui:
					print("🔍 Calling check_all_slots_filled from", name)
					puzzle_ui.check_all_slots_filled()
				else:
					print("❌ Error: PuzzleUI not found for", name)
			else:
				print("❌ Error: No valid TextureRect or texture in held_item for", name)
		else:
			print("❌ Sai item:", held_item.item_name, "| Cần:", expected_item, "ở", name)

func receive_item(item):
	if is_filled:
		return

	var user_interface = get_user_interface()
	if item.item_name == expected_item:
		var texture_rect = item.get_node_or_null("TextureRect")
		if texture_rect and texture_rect.texture:
			var item_texture = texture_rect.texture.duplicate()
			print("✅ Received item:", item.item_name, "vào", name, "Texture:", item_texture)
			$ItemIcon.texture = item_texture
			$ItemIcon.visible = true
			$ItemIcon.size = size
			$ItemIcon.position = Vector2(0, 0)
			# Debug rendering properties
			print("ItemIcon after receive - Visible:", $ItemIcon.visible, "Size:", $ItemIcon.size, "Texture:", $ItemIcon.texture)
			is_filled = true
			print("🔍 Set is_filled to true for", name)
			item.queue_free()
			if user_interface:
				user_interface.holding_item = null
				var puzzle_ui = get_puzzle_ui()
				if puzzle_ui:
					print("🔍 Calling check_all_slots_filled from", name)
					puzzle_ui.check_all_slots_filled()
				else:
					print("❌ Error: PuzzleUI not found for", name)
		else:
			print("❌ Error: No valid TextureRect or texture in received item for", name)
	else:
		print("❌ Sai item:", item.item_name, "ở", name)

func get_puzzle_ui():
	var parent = get_parent()  # TrialPuzzle
	if parent:
		var puzzle_ui = parent.get_parent()  # PuzzleUI
		if puzzle_ui and puzzle_ui.name == "PuzzleUI":
			return puzzle_ui
		else:
			print("❌ Error: Parent of", parent.name, "is not PuzzleUI, found:", puzzle_ui.name if puzzle_ui else "null")
	else:
		print("❌ Error: No parent (TrialPuzzle) found for", name)
	return null

func get_user_interface():
	var puzzle_ui = get_puzzle_ui()
	if puzzle_ui:
		var user_interface = puzzle_ui.get_parent()  # UserInterface
		if user_interface and user_interface.name == "UserInterface":
			return user_interface
		else:
			print("❌ Error: Parent of PuzzleUI is not UserInterface, found:", user_interface.name if user_interface else "null")
	else:
		print("❌ Error: PuzzleUI not found when getting user_interface")
	return null

func clear_slot():
	$ItemIcon.texture = null
	$ItemIcon.visible = false
	is_filled = false
	print("🔍 Cleared slot:", name)
