extends CanvasLayer

@onready var success_anim = $SuccessAnim  # Kéo từ scene hoặc sửa lại đúng tên nếu khác
@onready var gas_mask: Sprite2D = $GasMask
@onready var improved_mask: Sprite2D = $ImprovedMask

func _ready():
	# Ẩn SuccessAnim ngay khi UI được mở
	success_anim.visible = false
	gas_mask.visible = false
	improved_mask.visible = false
	add_to_group("PuzzleSlot")


func _input(event):
	if event.is_action_pressed("ui_cancel"):  # Nhấn ESC để đóng UI
		queue_free()

func check_mask():
	print("Gas mask placed, checking animation.")
	gas_mask.visible = true



# Hàm này được gọi mỗi khi một PuzzleSlot đúng
func check_all_slots_filled():
	for child in get_children():
		if child is PuzzleSlot and not child.is_filled:
			return  # Có ít nhất 1 slot chưa đúng

	# ✅ Tất cả các slot đều đúng
	gas_mask.visible = false
	improved_mask.visible = true
	for child in get_children():
		if child is PuzzleSlot and child.expected_item != "Gas_mask":
			child.clear_slot()
