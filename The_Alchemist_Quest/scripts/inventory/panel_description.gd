extends Panel

var ItemClass = preload("res://The_Alchemist_Quest/scences/player/item.tscn")
var item = null
var item_name = ""
var item_data = {}
var item_description = {}

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	modulate = Color(0, 1, 0, 0.3)
	await get_tree().create_timer(0.3).timeout
	modulate = Color(1, 1, 1, 1)
	
	load_item_data()

func set_item(new_item_name: String):
	item_name = new_item_name

func load_item_data():
	var file_path = "res://The_Alchemist_Quest/assets/json/intro_room/task1_items.json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_result = JSON.parse_string(file.get_as_text())
		file.close()
		
		if json_result and "item" in json_result:
			item_data = json_result["item"]
	else:
		print_debug("❌ Cannot load item data from: ", file_path)

func _get_popup_text(item_name: String) -> String:
	if item_name in item_data:
		return item_data[item_name].get("Mô tả", "Không có mô tả về vật phẩm này")
	return "Không tìm thấy đồ vật này"
