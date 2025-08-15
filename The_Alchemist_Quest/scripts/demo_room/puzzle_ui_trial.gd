# Puzzle Script - Modified để chuyển Post_Puzzle_Sequence qua Alert
extends CanvasLayer

signal puzzle_solved
signal start_alert_transition  # 🆕 Signal mới để trigger alert

@onready var slot_container = $InventoryContainer/Inventory/GridContainer
@onready var success_anim = $SuccessAnim
@onready var inventory = $InventoryContainer/Inventory
@onready var dialog_player = DialogPlayer

@export var reward_items: Array[String] = []
@export var reward_amounts: Array[int] = []
@export var allow_flexible_matching: bool = false

var puzzle_solved_flag = false
var is_post_puzzle_dialog = false
var inventory_ref = null

func _ready():
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("PuzzleSlot")
	
	visible = true
	layer = 5
	
	if has_node("SuccessAnim"):
		success_anim.visible = false
		success_anim.stop()
		if success_anim is AnimatedSprite2D:
			success_anim.connect("animation_finished", Callable(self, "_on_success_anim_done"))
			print("✅ Success animation connected và ẩn")
	else:
		print("⚠️ Success animation not found")
	
	if dialog_player and not dialog_player.is_connected("dialog_finished", _on_post_puzzle_dialog_finished):
		dialog_player.connect("dialog_finished", _on_post_puzzle_dialog_finished, CONNECT_ONE_SHOT)
	
	set_process_input(true)
	call_deferred("_force_setup_puzzle")

func _input(event):
	if not visible:
		return
		
	if event.is_action_pressed("ui_cancel"):
		print("🟥 ESC pressed - Closing puzzle")
		hide_puzzle()
		queue_free()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("turn_off_dialog"):
		if puzzle_solved_flag and dialog_player and dialog_player.in_progress and is_post_puzzle_dialog:
			dialog_player.finish()
			get_viewport().set_input_as_handled()
		else:
			print("Turn off dialog ignored: puzzle not solved, not post-puzzle, or dialog not active")

func check_all_slots_filled():
	var slots = []
	if slot_container:
		for child in slot_container.get_children():
			if child.has_method("receive_item") or child.get_script() and "PuzzleSlot" in str(child.get_script()):
				slots.append(child)
	
	if slots.is_empty():
		_find_puzzle_slots_recursive(self, slots)
	
	if slots.is_empty():
		print("❌ Không tìm thấy PuzzleSlot nào!")
		return
	
	if allow_flexible_matching:
		var required_items := []
		var filled_items := []
		for slot in slots:
			if slot.has_method("get_expected_items"):
				required_items += slot.get_expected_items()
			elif slot.has_property("expected_item"):
				required_items.append(slot.expected_item)
			
			if slot.is_filled and slot.current_item:
				filled_items.append(slot.current_item.item_name)
		
		required_items.sort()
		filled_items.sort()
		if required_items != filled_items:
			return
	else:
		for slot in slots:
			if not slot.is_filled:
				return
			print("Slot:", slot.name, "Filled:", slot.is_filled, "Expected Item:", slot.expected_item)
	
	print("➡️ Puzzle complete! Playing success animation.")
	puzzle_solved_flag = true
	
	if QuestManager:
		QuestManager.reach_goal()
	else:
		push_error("QuestManager not found!")
	
	if has_node("SuccessAnim"):
		success_anim.visible = true
		success_anim.play("explode")

func _find_puzzle_slots_recursive(node: Node, slots: Array):
	for child in node.get_children():
		if child.name.begins_with("PuzzleSlot") or child.get_script() != null and "PuzzleSlot" in str(child.get_script()):
			slots.append(child)
		_find_puzzle_slots_recursive(child, slots)

func _on_success_anim_done():
	print("✅ SuccessAnim đã kết thúc")
	
	# 🎁 Thêm phần thưởng...
	var ui = get_tree().get_first_node_in_group("UserInterface")
	if ui and ui.has_method("add_new_item_to_inventory"):
		for i in range(min(reward_items.size(), reward_amounts.size())):
			var item_name = reward_items[i]
			var qty = reward_amounts[i]
			print("🎁 Thêm vào túi:", item_name, "x", qty)
			ui.add_new_item_to_inventory(item_name, qty)
	
	clear_slots()
	print("🔍 Cleared slots")
	
	# 🆕 SET FLAG TRƯỚC - để LevelManager biết không tự động chuyển task
	var level_manager = LevelManager.instance
	if level_manager:
		level_manager.set_post_puzzle_dialog_flag(true)
		print("✅ Set Post_Puzzle_Sequence flag BEFORE signal")
	
	# 🚨 QUAN TRỌNG: Emit signal SAU khi đã set flag
	emit_signal("puzzle_solved")
	proceed_to_alert_with_dialog()

# 🆕 HÀM MỚI: Chuyển sang alert và trigger Post_Puzzle_Sequence ở đó
func proceed_to_alert_with_dialog():
	print("🔍 Proceeding to alert scene with Post_Puzzle_Sequence")
	
	if puzzle_solved_flag:
		# Set flag và chuyển scene ngay
		var level_manager = LevelManager.instance
		if level_manager:
			level_manager.set_post_puzzle_dialog_flag(true)
			print("✅ Set Post_Puzzle_Sequence flag in LevelManager")
		
		# Xóa inventory
		if PlayerInventory and PlayerInventory.has_method("clear_inventory"):
			PlayerInventory.clear_inventory()
		
		# 🚀 CHUYỂN SCENE NGAY LẬP TỨC
		print("🎯 Changing scene immediately to alert.tscn")
		_change_to_alert_scene()

# 🔧 Hàm helper để chuyển scene an toàn
func _change_to_alert_scene():
	var scene_tree = get_tree()
	if scene_tree and is_inside_tree():
		scene_tree.change_scene_to_file("res://The_Alchemist_Quest/scenes/Map/alert.tscn")
		print("✅ Successfully changed to alert scene")
	else:
		print("❌ Cannot change scene - tree not available")

# 🗑️ CÁC HÀM CŨ - giữ lại để tương thích ngược
func end_puzzle_sequence():
	if QuestManager:
		QuestManager.complete_current_task()
	print("🔍 Puzzle sequence ended - proceeding to alert")
	proceed_to_alert_with_dialog()

func _on_post_puzzle_dialog_finished():
	if puzzle_solved_flag:
		print("🔍 Post-puzzle dialog finished in alert scene")
		# Không cần làm gì thêm - alert scene sẽ xử lý
	else:
		print("Puzzle not solved yet, ignoring dialog finish")

func proceed_to_alert_scene():
	# 🗑️ Deprecated - sử dụng proceed_to_alert_with_dialog() thay thế
	proceed_to_alert_with_dialog()

func clear_slots():
	var slots := []
	if slot_container:
		slots = slot_container.get_children()
	else:
		_find_puzzle_slots_recursive(self, slots)
	
	for slot in slots:
		if slot.has_method("clear_slot"):
			slot.clear_slot()
			print("🔍 Cleared slot:", slot.name)
	
	if has_node("SuccessAnim"):
		success_anim.visible = false

func _force_setup_puzzle():
	if has_node("SuccessAnim"):
		success_anim.visible = false
		success_anim.stop()
		if success_anim.is_playing():
			success_anim.stop()
		print("🔍 SUCCESS ANIMATION FORCED HIDDEN: ", success_anim.visible)
	
	show_puzzle()

func show_puzzle():
	visible = true
	layer = 5
	
	if has_node("SuccessAnim"):
		success_anim.visible = false
		success_anim.stop()
		print("🔍 Force hide success animation on show_puzzle")
	
	if inventory:
		inventory.visible = true
	if has_node("InventoryContainer"):
		$InventoryContainer.visible = true
	if has_node("DialogAreaPuzzle"):
		$DialogAreaPuzzle.visible = true
		
	for child in get_children():
		if child.name.begins_with("PuzzleSlot") or "PuzzleSlot" in child.name:
			child.visible = true
		
	if dialog_player and not dialog_player.in_progress:
		dialog_player.set_dialog_file("res://The_Alchemist_Quest/assets/json/demo_AI_dialoge.json")
		SignalBus.emit_signal("display_puzzle_dialog", "Puzzle_guide", null)
		print("📢 Puzzle guide dialog triggered")
	
	if inventory:
		inventory.visible = true
		print("📦 Opened inventory for puzzle")
	
	if dialog_player:
		dialog_player.layer = 20
	else:
		print("❌ DialogPlayer not found for puzzle guide")
	
	print("🔍 PUZZLE DEBUG INFO:")
	print("   - Node path:", get_path())
	print("   - Parent:", get_parent())
	print("   - Tree valid:", is_inside_tree())
	print("   - Success anim visible:", success_anim.visible if has_node("SuccessAnim") else "N/A")
	print("   - Puzzle layer:", layer)

func hide_puzzle():
	clear_slots()
	visible = false
	print("🔍 Puzzle UI hidden")
	
	if dialog_player and dialog_player.in_progress:
		dialog_player.finish()
	
	if inventory and inventory.visible:
		inventory.visible = false
		print("🔍 Inventory hidden")

func set_inventory(inventory_data):
	inventory_ref = inventory_data
	update_ui()

func update_ui():
	if inventory_ref == null:
		print("⚠️ Chưa có inventory để hiển thị.")
		return
		
	if not slot_container:
		print("⚠️ Slot container not found.")
		return
		
	var slots = slot_container.get_children()
	for i in range(slots.size()):
		var slot = slots[i]
		if slot.has_method("set_inventory_reference"):
			slot.slot_index = i
			slot.set_inventory_reference(inventory_ref)
		
		if i < inventory_ref.size() and inventory_ref[i] != null:
			var item_data = inventory_ref[i]
			if item_data[0] != null and item_data[1] > 0:
				slot.initialize_item(item_data[0], item_data[1])
			else:
				slot.initialize_item("", 0)
		else:
			slot.initialize_item("", 0)
