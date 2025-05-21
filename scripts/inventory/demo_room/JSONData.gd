extends Node

var item_data: Dictionary

func _ready():
	item_data = load_data("res://The_Alchemist_Quest/assets/json/demo_items.json")
	print("Loaded items: ", item_data.keys())
	

func get_item_description(item_name: String) -> String:
	var data = get_tree().root.get_node("/root/JsonData").item_data
	if "item" in data:
		return data["item"].get(item_name, {}).get("Description", "No description")
	return data.get(item_name, {}).get("Description", "No Description available")
	
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
		
		# Handle both wrapped and direct JSON structures
	if "item" in parsed_data:
		return parsed_data["item"]
	return parsed_data
		
	
