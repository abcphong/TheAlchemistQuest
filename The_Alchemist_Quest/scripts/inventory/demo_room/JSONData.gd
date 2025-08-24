extends Node

var item_data: Dictionary

func _ready():
	# Initialize item_data with an empty dictionary
	item_data = {}

	# Tải dữ liệu từ demo_room
	var demo_data = load_data("res://The_Alchemist_Quest/assets/json/demo_items.json")

	# Tải dữ liệu từ intro_room
	var intro_data = load_data("res://The_Alchemist_Quest/assets/json/intro_room/task1_items.json")

	# Tải dữ liệu từ security_room nếu tồn tại
	var security_data = load_data("res://The_Alchemist_Quest/assets/json/security_room/task1_items.json")

	# Tải dữ liệu từ storage_room task1 nếu tồn tại
	var storage_data = load_data("res://The_Alchemist_Quest/assets/json/storage_room/task1_items.json")

	# Tải dữ liệu từ storage_room task2 nếu tồn tại
	var storage_task2_data = load_data("res://The_Alchemist_Quest/assets/json/storage_room/task2_items.json")
	
	# Hợp nhất dữ liệu từ các nguồn khác nhau
	# Start with demo_data
	if "item" in demo_data:
		item_data["item"] = demo_data["item"].duplicate(true)
	else:
		item_data["item"] = demo_data.duplicate(true)
	
	# Merge intro data into item_data
	if "item" in intro_data and intro_data["item"]:
		for key in intro_data["item"]:
			item_data["item"][key] = intro_data["item"][key]
	elif intro_data:
		for key in intro_data:
			item_data["item"][key] = intro_data[key]

	# Merge security data into item_data
	if security_data:
		if "item" in security_data:
			for key in security_data["item"]:
				item_data["item"][key] = security_data["item"][key]
		else:
			for key in security_data:
				item_data["item"][key] = security_data[key]

	# Merge storage task1 data into item_data
	if storage_data:
		if "item" in storage_data:
			for key in storage_data["item"]:
				item_data["item"][key] = storage_data["item"][key]
		else:
			for key in storage_data:
				item_data["item"][key] = storage_data[key]
				
	# Merge storage task2 data into item_data
	if storage_task2_data:
		if "item" in storage_task2_data:
			for key in storage_task2_data["item"]:
				item_data["item"][key] = storage_task2_data["item"][key]
		else:
			for key in storage_task2_data:
				item_data["item"][key] = storage_task2_data[key]
	

	

func get_item_description(item_name: String) -> String:
	if "item" in item_data and item_name in item_data["item"]:
		return item_data["item"].get(item_name, {}).get("Description", "No description")
	elif item_name in item_data:
		return item_data.get(item_name, {}).get("Description", "No Description available")
	else:
		return "Item không tồn tại"
	
func load_data(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_error("JSON file missing at: " + file_path)
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)

	if not file:
		push_error("Failed to open JSON file. Error code: ", FileAccess.get_open_error())
		return {}

	var text = file.get_as_text()
	var parsed_data = JSON.parse_string(text)

	if not parsed_data is Dictionary:
		push_error("Invalid JSON format - expected Dictionary")
		return {}

	return parsed_data
		
	
