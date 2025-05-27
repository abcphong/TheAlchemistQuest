extends CanvasLayer

@onready var success_anim = $SuccessAnim  # Optional: add a success animation node if you want

func _ready():
	if has_node("SuccessAnim"):
		success_anim.visible = false
	add_to_group("PuzzleSlot")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		queue_free()

func check_all_slots_filled():
	for child in get_children():
		if child is PuzzleSlot and not child.is_filled:
			return
	if has_node("SuccessAnim"):
		success_anim.visible = true
		success_anim.play("complete")
