extends Node

var item_data: Dictionary

func _ready():
	# Xóa debug log cũ
	
	# Tải dữ liệu từ intro_room
	var intro_data = load_data("res://The_Alchemist_Quest/assets/json/intro_room/task1_items.json")
	print("[DEBUG-ITEMS] Đã tải intro items: ", intro_data.keys())
	
	# Tải dữ liệu từ security_room nếu tồn tại
	var security_data = load_data("res://The_Alchemist_Quest/assets/json/security_room/task1_items.json")
	print("[DEBUG-ITEMS] Đã tải security items: ", security_data.keys())

	# Tải dữ liệu từ storage_room task1 nếu tồn tại
	var storage_data = load_data("res://The_Alchemist_Quest/assets/json/storage_room/task1_items.json")
	print("[DEBUG-ITEMS] Đã tải storage task1 items: ", storage_data.keys())
	
	# Tải dữ liệu từ storage_room task2 nếu tồn tại
	var storage_task2_data = load_data("res://The_Alchemist_Quest/assets/json/storage_room/task2_items.json")
	print("[DEBUG-ITEMS] Đã tải storage task2 items: ", storage_task2_data.keys())
	
	# Hợp nhất dữ liệu từ các nguồn khác nhau
	if "item" in intro_data:
		item_data = intro_data
	else:
		item_data = {"item": intro_data}
	
	# Merge security data vào item_data
	if security_data:
		if "item" in security_data:
			for key in security_data["item"]:
				item_data["item"][key] = security_data["item"][key]
		else:
			for key in security_data:
				item_data["item"][key] = security_data[key]

	# Merge storage task1 data vào item_data
	if storage_data:
		if "item" in storage_data:
			for key in storage_data["item"]:
				item_data["item"][key] = storage_data["item"][key]
		else:
			for key in storage_data:
				item_data["item"][key] = storage_data[key]
				
	# Merge storage task2 data vào item_data
	if storage_task2_data:
		if "item" in storage_task2_data:
			for key in storage_task2_data["item"]:
				item_data["item"][key] = storage_task2_data["item"][key]
		else:
			for key in storage_task2_data:
				item_data["item"][key] = storage_task2_data[key]
	
	print("[DEBUG-ITEMS] Cấu trúc cuối cùng của item_data:", item_data.keys())
	if "item" in item_data:
		print("[DEBUG-ITEMS] Số lượng items trong item_data['item']:", item_data["item"].size())
		print("[DEBUG-ITEMS] Danh sách items có sẵn:", item_data["item"].keys())
	

func get_item_description(item_name: String) -> String:
	if "item" in item_data and item_name in item_data["item"]:
		print("[DEBUG-ITEMS] Lấy description từ 'item' key cho: ", item_name)
		return item_data["item"].get(item_name, {}).get("Description", "No description")
	elif item_name in item_data:
		print("[DEBUG-ITEMS] Lấy description trực tiếp cho: ", item_name)
		return item_data.get(item_name, {}).get("Description", "No Description available")
	else:
		print("[DEBUG-ITEMS] Không tìm thấy item: ", item_name)
		return "Item không tồn tại"
	
func load_data(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_error("JSON file missing at: " + file_path)
		print("[DEBUG-ITEMS] Không tìm thấy file: ", file_path)
		return {}
			
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		push_error("Failed to open JSON file. Error code: ", FileAccess.get_open_error())
		print("[DEBUG-ITEMS] Không thể mở file: ", file_path, " - Error: ", FileAccess.get_open_error())
		return {}
	
	var text = file.get_as_text()
	var parsed_data = JSON.parse_string(text)
	
	if not parsed_data is Dictionary:
		push_error("Invalid JSON format - expected Dictionary")
		print("[DEBUG-ITEMS] JSON không hợp lệ trong file: ", file_path)
		return {}
		
	print("[DEBUG-ITEMS] Dữ liệu đã parse từ file", file_path, ":", parsed_data.keys())
	return parsed_data
		
	
