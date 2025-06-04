extends Panel
class_name PuzzleSlot
@export var expected_item: String = ""  # Tên item đúng để kiểm tra
var item: Control = null
var item_data = {}
var slot_index = -1 
var is_hotbar_slot := false
var is_filled := false

@onready var popup_panel = get_node("../../PopupPanel")
@onready var popup_label = get_node("../../PopupPanel/VBoxContainer/DescriptionLabel")

func _ready():
	add_to_group("PuzzleSlot")



func receive_item(item):
	if is_filled:
		return

	if item.item_name == expected_item:
		$ItemIcon.texture = item.get_node("TextureRect").texture
		is_filled = true
		item.queue_free()
		UserInterface.holding_item = null
		get_parent().check_all_slots_filled()
		if item.item_name == "Gas_mask":
			get_parent().check_mask()
	else:
		print("❌ Sai item:", item.item_name)

func clear_slot():
	$ItemIcon.texture = null
	is_filled = false
