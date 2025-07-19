extends InteractableBase

signal item_activated

var initial_dialog_shown = false # Kiểm tra xem Cabinet dialog đã được hiển thị chưa
@export var initial_dialog_key := "Cabinet"
@export var pickup_dialog_key := "Player_pickup_copper_wire"
@export var pickup_electric_wire_dialog_key := "Player_pickup_electric_wire"
@export_file("*.json") var dialog_file 

var items_to_give = [
	{"name": "Copper wire", "quantity": 1},
	{"name": "Electric wire", "quantity": 2}
]
var current_item_index = 0


func _ready():
	# Lấy item đầu tiên 
	set_current_item()
	interaction_group = "cabinet"
	
	super._ready()
	
	# Set collision properties
	collision_layer = 2  # Layer 2 for interactable objects
	collision_mask = 1   # Mask 1 for player

func set_current_item():
	if current_item_index < items_to_give.size():
		item_name = items_to_give[current_item_index]["name"]
		item_quantity = items_to_give[current_item_index]["quantity"]
		
func _on_player_entered(body: Node2D):
	print("🔵 Cabinet: Player người chơi có thể tương tác ")

func _on_player_exited(body: Node2D):
	print("🴴 Player ra khỏi khu vực cabinet")


func _handle_interaction():
	print("🔵 Cabinet interaction triggered")
	
	if not initial_dialog_shown:
		# Hiện thị dialog environemnt của computer
		DialogPlayer.set_dialog_file(dialog_file)
		SignalBus.emit_signal("display_dialog", initial_dialog_key)
		initial_dialog_shown = true
		print("Dialog states:", "Initial shown:", initial_dialog_shown)
	else:
		# Cho lớp cha xử lí pickup
		super._handle_interaction()

func _on_item_given():
	# Hiển thị dialog khi pick up Copper wire thành công 
	print("✅ Thêm Copper wire vào túi đồ thành công")
	DialogPlayer.set_dialog_file(dialog_file)
	SignalBus.emit_signal("display_dialog", pickup_dialog_key)
	print("Dialog states:", "Initial shown:", initial_dialog_shown, "Has item:", has_given_item)
	
	# Lấy item electric wire
	print("✅ Thêm Electric wire vào túi đồ thành công")
	DialogPlayer.set_dialog_file(dialog_file)
	SignalBus.emit_signal("display_dialog", pickup_electric_wire_dialog_key)
	print("Dialog states:", "Initial shown:", initial_dialog_shown, "Has item:", has_given_item, "Pick up electric wire:", has_given_item )
	current_item_index += 1
	if current_item_index < items_to_give.size():
		set_current_item()
		has_given_item = false  # Reset cho item tiếp theo 
	else:
		print("🎉 Đã lấy tất cả vật phẩm từ cabinet")
		
		super._on_item_given()

	
