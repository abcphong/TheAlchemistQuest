extends CanvasLayer
signal puzzle_solved  # 🔔 Tín hiệu thông báo puzzle đã hoàn thành

@onready var success_anim = $SuccessAnim  # AnimatedSprite2D
@onready var puzzle_slot = $PuzzleSlot  # Trỏ trực tiếp tới slot
@export var reward_items: Array[String] = []
@export var reward_amounts: Array[int] = []
@export var allow_flexible_matching: bool = false

var space_press_count = 0  # Đếm số lần nhấn Space

func _ready():
	success_anim.visible = false
	success_anim.connect("animation_finished", Callable(self, "_on_success_anim_done"))
	puzzle_slot.visible = false  # Mặc định ẩn PuzzleSlot

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		queue_free()

	if event.is_action_pressed("ui_accept"):  # Space
		handle_space_press()

func handle_space_press():
	space_press_count += 1
	if space_press_count == 1:
		success_anim.visible = true
		success_anim.play("opened")
		success_anim.pause()
		success_anim.frame = success_anim.sprite_frames.get_frame_count("opened") - 1
	elif space_press_count == 2:
		success_anim.play("peeled")
		success_anim.pause()
		success_anim.frame = success_anim.sprite_frames.get_frame_count("peeled") - 1
		puzzle_slot.visible = true

# ✅ Kiểm tra slot đã được lắp đúng chưa
func check_all_slots_filled():
	if not puzzle_slot.is_filled or puzzle_slot.current_item == null:
		return

	if allow_flexible_matching:
		# Với 1 slot thì flexible không khác biệt
		if not puzzle_slot.expected_items.has(puzzle_slot.current_item.item_name):
			return
	else:
		if not puzzle_slot.expected_item.has(puzzle_slot.current_item.item_name):
			print("❌ Slot sai:", puzzle_slot.name, "| Có:", puzzle_slot.current_item.item_name, "| Cần:", puzzle_slot.expected_item)
			return

	print("➡️ Puzzle complete! Playing success animation.")
	success_anim.visible = true
	puzzle_slot.visible = false  # Mặc định ẩn PuzzleSlot
	success_anim.play("success")

func _on_success_anim_done():
	print("✅ SuccessAnim đã kết thúc")

	var ui = get_tree().get_first_node_in_group("UserInterface")
	if ui:
		for i in range(min(reward_items.size(), reward_amounts.size())):
			var item_name = reward_items[i]
			var qty = reward_amounts[i]
			print("🎁 Thêm vào túi:", item_name, "x", qty)
			ui.add_new_item_to_inventory(item_name, qty)
	else:
		print("❌ Không tìm thấy UserInterface để nhận item")

	emit_signal("puzzle_solved")
	queue_free()
