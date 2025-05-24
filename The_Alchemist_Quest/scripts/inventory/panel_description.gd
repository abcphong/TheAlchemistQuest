extends Panel

var ItemClass = preload("res://The_Alchemist_Quest/scences/player/item.tscn")
var item = null
var item_name =""
var item_data = {}
var item_description = {}

@onready var popup_panel = get_node("../PopupPanel")
@onready var popup_label = popup_panel.get_node("$VBoxContainer/DescriptionLabel")

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	modulate = Color(0,1,0,0.3)
	await get_tree().create_timer(0.3).timeout
	modulate = Color(1,1,1,1)
	
	load_item_data()

func set_item(new_item_name: String):
	item_name = new_item_name
	print_debug("Item set in slot: ", item_name)
	
func load_item_data():
	print_debug("Loading item data...")
	var file_path ="res://The_Alchemist_Quest/assets/json/intro_room/task1_items.json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_result = JSON.parse_string(file.get_as_text())
	
	if "item" in json_result:
		item_data = json_result["item"]
		print("Loaded", item_data.size(), "items")
		print_debug("Successfully loaded ", item_data.size(), " items")
		print_debug("Item keys: ", item_data.keys())
		
	gui_input.connect(_on_gui_input)
	
func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT and item:
			get_parent().get_parent().show_description(
				JsonData.get_item_description(item.item_name),
				get_global_mouse_position()
			)

func _show_item_popup(item_name:String):

	if item == null or not is_instance_valid(popup_panel) or not is_instance_valid(popup_label):
		return
	
	print("Showing popup for item: ", item.item_name)
	var description = _get_popup_text(item.item_name)
	print("Description text: ", description)
	#Set popup text based on item
	popup_label.text = description 
	popup_panel.show()
	
	print("Popup visibility:", popup_panel.visible)
	print("Label text:", popup_label.text)
	
func _get_popup_text(item_name: String) -> String:
	print_debug("Getting description for: ", item_name)
	if item_name in item_data:
		return item_data[item_name].get("Mô tả", "Không có mô tả về vật phẩm này")
	return "Không tìm thấy đồ vật này"
	
