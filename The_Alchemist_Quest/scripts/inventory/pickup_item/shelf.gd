extends InteractableBase

signal task_items_updated

@export var pickup_salt_bridge := "Player_pickup_salt_bridge"
@export var pickup_CuSO4 := "Player_pickup_CuSO4"
@export var pickup_ZnSO4 := "Player_pickup_ZnSO4"
@export var pickup_filter_paper := "Player_pick_up_filter_paper"
@export var pickup_FeSO4 := "Player_pick_up_FeSO4"
@export var pickup_activated_coal := "Player_pickup_C"
@export var pickup_mini_oxygen := "Player_pickup_oxymini"
@export_file("*.json") var dialog_file

var task_items = {
	1: [
		{"name" : "Salt bridge", "quantity" : 1},
		{"name" : "CuSO4" , "quantity" : 1},
		{"name" : "ZnSO4" , "quantity" : 1},
	],
	2: [
		{"name" : "FeSO4" , "quantity" : 1},
		{"name" : "Filter paper" , "quantity" : 1},
	],
	3: [
		{"name" : "Activated coal" , "quantity" : 1},
		{"name" : "Mini Oxygen" , "quantity" : 1},
	]
}

var available_items_for_pickup = []
var current_item_index = 0
var item_dialog_map = {}
var interaction_enabled : bool = false

func _ready():
	interaction_group = "Shelf"
	super._ready()
	_init_dialog_map()
	
	setup_for_task(1)

func _init_dialog_map():
	item_dialog_map = {
		"Salt bridge": pickup_salt_bridge,
		"CuSO4": pickup_CuSO4,
		"ZnSO4": pickup_ZnSO4,
		"FeSO4": pickup_FeSO4,
		"Filter Paper": pickup_filter_paper,
		"Activated coal": pickup_activated_coal,
		"Mini Oxygen": pickup_mini_oxygen
	}

func setup_for_task(task_number: int):
	print("Tủ đồ nhận lệnh thiết lập cho Task %d" % task_number)
	current_item_index = 0
	available_items_for_pickup.clear()

	if task_items.has(task_number):
		available_items_for_pickup = task_items[task_number].duplicate()
	else:
		print("⚠️ Không có vật phẩm cho task này.")
	
	# RESET trạng thái hoàn toàn khi sang task mới
	interaction_enabled = true
	item_name = ""
	item_quantity = 0

	_set_current_item()


func _set_current_item():
	if current_item_index < available_items_for_pickup.size():
		var current_item_data = available_items_for_pickup[current_item_index]
		set_item(current_item_data["name"], current_item_data["quantity"])
		interaction_enabled = true
	else:
		# Hết đồ để nhặt
		item_name = ""
		item_quantity = 0
		interaction_enabled = false
		print("🎉 Shelf: Đã lấy hết vật phẩm.")

func _handle_interaction():
		_pickup_next_item()

func _pickup_next_item():
	print("🟠 [Shelf Debug] current_item_index: %d / available_items_for_pickup.size(): %d" % [current_item_index, available_items_for_pickup.size()])
	if not interaction_enabled:
		print("⚠️ Shelf: Không còn vật phẩm để nhặt.")
		return

	if item_name.is_empty():
		print("⚠️ Shelf: Item name trống.")
		return

	print("🔵 Shelf: Cố gắng nhặt '%s'" % item_name)

	if PlayerInventory.add_item(item_name, item_quantity):
		print("✅ Shelf: Đã thêm '%s' vào túi đồ" % item_name)

		if item_dialog_map.has(item_name):
			var dialog_key = item_dialog_map[item_name]
			if dialog_file:
				DialogPlayer.set_dialog_file(dialog_file)
				SignalBus.emit_signal("display_dialog", dialog_key)

		current_item_index += 1
		_set_current_item()
	else:
		print("❌ Shelf: Túi đồ đầy, không thể nhặt '%s'" % item_name)

# Không cần override _can_give_item hay _give_item, vì Shelf dùng cơ chế riêng hoàn toàn
# Không cần quan tâm can_interact, chỉ dùng interaction_enabled để kiểm soát pickup flow

func _on_player_entered(body: Node2D):
	print("🔵 Shelf: Player vào khu vực tủ đồ")

func _on_player_exited(body: Node2D):
	print("🴴 Shelf: Player rời khỏi khu vực tủ đồ")
