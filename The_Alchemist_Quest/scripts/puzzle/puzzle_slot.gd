extends Panel
class_name PuzzleSlot

@export var expected_item: Array[String] = []
var is_filled := false
var current_item: Control = null  # Item hiện đang nằm trong slot

func _ready():
	add_to_group("PuzzleSlot")

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var held_item = UserInterface.holding_item

		# TH1: đang cầm item và slot trống → đặt vào (bất kể đúng sai)
		if held_item and not is_filled:
			# Đảm bảo item sẽ không bị mất nếu nhận thất bại
			if not receive_item(held_item):
				return
			UserInterface.holding_item = null

		# TH2: không cầm gì, và slot đã có item → kéo ra lại
		elif not held_item and current_item and is_filled:
			# ✅ Hiện lại item
			current_item.visible = true

			UserInterface.holding_item = current_item
			current_item = null
			is_filled = false
			$ItemIcon.texture = null

			var parent = get_parent() if is_instance_valid(get_parent()) else get_tree().get_root()
			parent.add_child(UserInterface.holding_item)
			
			UserInterface.holding_item.global_position = get_viewport().get_mouse_position()
			UserInterface.holding_item.set_z_as_relative(false)
			UserInterface.holding_item.z_index = 9999
			UserInterface.is_dragging = true

			if get_parent() and get_parent().has_method("check_all_slots_filled"):
				get_parent().check_all_slots_filled()

func receive_item(item: Control) -> bool:
	if not is_instance_valid(item):
		return false
		
	# Lưu thông tin của item trước khi thay đổi
	var item_name = item.item_name
	var item_quantity = item.item_quantity
	
	# Nếu slot đã có item → trả về inventory
	if is_filled and current_item:
		if not return_item_to_inventory(current_item):
			return false

	# Đặt item mới vào slot
	current_item = item

	var tex_node = item.get_node_or_null("TextureRect")
	if tex_node:
		$ItemIcon.texture = tex_node.texture

	# Lưu ref cũ của parent để kiểm tra
	var old_parent = item.get_parent()
	if old_parent:
		old_parent.remove_child(item)
	
	add_child(item)
	item.visible = false
	item.position = Vector2.ZERO

	is_filled = true
	UserInterface.is_dragging = false
		
	if get_parent().has_method("check_all_slots_filled"):
		get_parent().check_all_slots_filled()
		
	return true

func return_item_to_inventory(item: Control) -> bool:
	if item.get_parent():
		item.get_parent().remove_child(item)

	var success := UserInterface.return_item_to_inventory(item)

	if not success:
		# Nếu không thể trả về inventory, hiển thị item dưới con trỏ chuột để người chơi có cơ hội lấy lại
		get_tree().get_root().add_child(item)
		item.visible = true
		item.global_position = get_viewport().get_mouse_position()
		UserInterface.holding_item = item
		UserInterface.is_dragging = true
		return false  # Báo là không thành công trả về inventory

	current_item = null
	is_filled = false
	$ItemIcon.texture = null
	return true
