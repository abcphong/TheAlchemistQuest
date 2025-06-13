extends CanvasLayer

@onready var success_anim = $SuccessAnim  # AnimatedSprite2D

func _ready():
	success_anim.visible = false
	success_anim.connect("animation_finished", Callable(self, "_on_success_anim_done"))
	add_to_group("PuzzleSlot")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		queue_free()

func check_all_slots_filled():
	for child in get_children():
		if child is PuzzleSlot and not child.is_filled:
			return  # Có ít nhất 1 slot chưa đúng

	# ✅ Tất cả các slot đều đúng
	print("➡️ Puzzle complete! Playing success animation.")
	success_anim.visible = true
	success_anim.play("complete")

func _on_success_anim_done():
	print("✅ SuccessAnim đã kết thúc")

	var ui = get_tree().get_first_node_in_group("UserInterface")
	if ui:
		print("🎁 Gọi add_new_item_to_inventory(FESO4)")
		ui.add_new_item_to_inventory("FeSO4", 1)
	else:
		print("❌ Không tìm thấy UserInterface để nhận item")
