extends Panel
class_name PuzzleSlot

@export var expected_item: Array[String] = []
var is_filled := false
var current_item: Control = null  # Item hiện đang nằm trong slot

func _ready():
	add_to_group("PuzzleSlot")

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		var held_item = UserInterface.holding_item
		
		# Xử lý cả chuột TRÁI và PHẢI
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			# TH1: đang cầm item và slot trống → đặt vào (bất kể đúng sai)
			if held_item and not is_filled:
				receive_item(held_item)
				UserInterface.holding_item = null
			# TH2: không cầm gì, và slot đã có item
			elif not held_item and current_item:
				# Chuột trái: kéo ra lại
				if event.button_index == MOUSE_BUTTON_LEFT:
					print("🔁 Lấy lại item từ PuzzleSlot:", current_item.item_name)
					# Hiện lại item
					current_item.visible = true
					UserInterface.holding_item = current_item
					# Set original slot info to indicate this came from a puzzle slot
					UserInterface.original_slot_index = -1  # -1 indicates puzzle slot
					UserInterface.original_is_hotbar = false
					UserInterface.original_puzzle_slot = self  # Store reference to this puzzle slot
					current_item = null
					is_filled = false
					$ItemIcon.texture = null
					get_tree().get_root().add_child(UserInterface.holding_item)
					UserInterface.holding_item.global_position = get_global_mouse_position()
					UserInterface.holding_item.set_z_as_relative(false)
					UserInterface.holding_item.z_index = 9999
					UserInterface.is_dragging = true
				# Chuột phải: trả về inventory ngay lập tức
				else:
					print("🖱️ Chuột phải: Trả item về inventory:", current_item.item_name)
					var item_to_return = current_item
					current_item = null
					is_filled = false
					$ItemIcon.texture = null
					return_item_to_inventory(item_to_return)
				
				if get_parent().has_method("check_all_slots_filled"):
					get_parent().check_all_slots_filled()

func receive_item(item: Control):
	# Nếu slot đã có item → trả về inventory
	if is_filled and current_item:
		print("🔁 PuzzleSlot đã có item, trả về inventory:", current_item.item_name)
		return_item_to_inventory(current_item)
	
	# Đặt item mới vào slot
	current_item = item
	if expected_item.has(item.item_name):
		print("✅ Đặt đúng item:", item.item_name)
	else:
		print("❌ Đặt SAI item:", item.item_name, " | Cần:", expected_item)
	
	var tex_node = item.get_node_or_null("TextureRect")
	if tex_node:
		$ItemIcon.texture = tex_node.texture
	
	add_child(item)
	item.visible = false
	item.position = Vector2.ZERO
	is_filled = true
	UserInterface.is_dragging = false
	
	if get_parent().has_method("check_all_slots_filled"):
		get_parent().check_all_slots_filled()

func return_item_to_inventory(item: Control):
	if item.get_parent():
		item.get_parent().remove_child(item)
	
	var success := UserInterface.return_item_to_inventory(item)
	if not success:
		print("⚠ Không có chỗ trống, vứt ra ngoài")
		get_tree().get_root().add_child(item)
		item.visible = true
		item.global_position = get_global_mouse_position()
	
	current_item = null
	is_filled = false
	$ItemIcon.texture = null
