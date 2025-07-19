extends Control

class_name Item

var item_name: String = ""
var item_quantity : int = 0
var max_quantity: int = 1

func set_item(nm: String, qt: int) -> void:
	item_name = nm
	item_quantity = qt
	
	# Cập nhật ảnh item - kiểm tra nhiều thư mục
	var texture_paths = [
		"res://The_Alchemist_Quest/assets/puzzle/intro_room/" + item_name + ".png",
		"res://The_Alchemist_Quest/assets/puzzle/security_room/task1/" + item_name + ".png",
		"res://The_Alchemist_Quest/assets/puzzle/storage_room/task1/" + item_name + ".png",
		"res://The_Alchemist_Quest/assets/puzzle/storage_room/task2/" + item_name + ".png",
		"res://The_Alchemist_Quest/assets/item/" + item_name + ".png",
		"res://The_Alchemist_Quest/assets/gameDemo/" + item_name + ".png"
	]
	
	
	# Kiểm tra chi tiết về file tồn tại
	for path in texture_paths:
		var exists = ResourceLoader.exists(path)
	
	# Thử tải từng đường dẫn cho đến khi tìm thấy texture
	var texture = null
	for path in texture_paths:
		if ResourceLoader.exists(path):
			texture = load(path)
			break
	
	if texture:
		$TextureRect.texture = texture
	else:
		# Tải texture mặc định nếu không tìm thấy
		$TextureRect.texture = load("res://The_Alchemist_Quest/assets/item/unknow_item.png")

	# Cập nhật stack và hiển thị số lượng
	if JsonData.item_data.has(item_name):
		max_quantity = int(JsonData.item_data[item_name].get("StackSize", 1))
	elif JsonData.item_data.has("item") and JsonData.item_data["item"].has(item_name):
		max_quantity = int(JsonData.item_data["item"][item_name].get("StackSize", 1))
	else:
		max_quantity = 1
		
	# Chỉ hiển thị số lượng khi item_quantity > 1
	$Label.visible = item_quantity > 1
	$Label.text = str(item_quantity)
	
func set_item_quantity(new_quantity: int):
	item_quantity = new_quantity
	# Cập nhật hiển thị số lượng
	$Label.visible = item_quantity > 1
	$Label.text = str(item_quantity)
	if item_quantity <= 0:
		queue_free()

func add_item_quantity(amount_to_add: int) -> int:
	var new_quantity = item_quantity + amount_to_add
	var remainder = 0
	if new_quantity > max_quantity:
		item_quantity = max_quantity
		remainder = new_quantity - max_quantity
	else:
		item_quantity = new_quantity
	
	# Cập nhật hiển thị số lượng
	$Label.visible = item_quantity > 1
	$Label.text = str(item_quantity)
	return remainder
	
func decrease_item_quantity(amount_to_remove):
	item_quantity -= amount_to_remove
	# Cập nhật hiển thị số lượng
	$Label.visible = item_quantity > 1
	$Label.text = str(item_quantity)
