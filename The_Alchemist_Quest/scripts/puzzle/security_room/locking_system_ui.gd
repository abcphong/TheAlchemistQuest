extends CanvasLayer
signal puzzle_solved  # 🔔 Tín hiệu thông báo puzzle đã hoàn thành

# Lưu trữ các texture cho các trạng thái khác nhau
@export var before_texture: Texture2D
@export var after_texture: Texture2D

@onready var background = $Background  # TextureRect hiển thị hình ảnh
@onready var card_slot = $CardSlot    # Slot để đặt thẻ bảo mật
var current_state = "before"  # Trạng thái hiện tại: "before", "after", hoặc "card_check"

# 🎁 Phần thưởng cho người chơi (danh sách item và số lượng)
@export var reward_items: Array[String] = []
@export var reward_amounts: Array[int] = []

func _ready():
	# Thiết lập trạng thái ban đầu
	if before_texture:
		background.texture = before_texture
		print("[DEBUG-SECURITY] Đã thiết lập texture ban đầu")
	else:
		print("[DEBUG-SECURITY] Lỗi: Không có before_texture")
	
	print("[DEBUG-SECURITY] After texture có sẵn: ", after_texture != null)
	
	# Ẩn card_slot lúc bắt đầu
	if card_slot:
		card_slot.visible = false
		print("[DEBUG-SECURITY] Đã tìm thấy và ẩn card slot")
	else:
		print("[DEBUG-SECURITY] CẢNH BÁO: Không tìm thấy card slot")
	
	add_to_group("PuzzleSlot")
	print("[DEBUG-SECURITY] Locking system UI khởi tạo")
	
	# Debug thông tin các texture
	if before_texture:
		print("[DEBUG-SECURITY] Path texture before: ", before_texture.resource_path)
	if after_texture:
		print("[DEBUG-SECURITY] Path texture after: ", after_texture.resource_path)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("[DEBUG-SECURITY] Đóng UI: đã nhấn ESC")
		queue_free()

# Được gọi mỗi khung hình
func _process(delta):
	# Kiểm tra phím tương tác (E)
	if Input.is_action_just_pressed("interact") and current_state == "before":
		print("[DEBUG-SECURITY] Phím tương tác (E) được nhấn - chuyển trạng thái")
		_change_to_after_state()

# Chuyển sang trạng thái mở khóa (after)
func _change_to_after_state():
	print("[DEBUG-SECURITY] Bắt đầu chuyển sang trạng thái after")
	current_state = "after"
	if after_texture:
		background.texture = after_texture
		print("[DEBUG-SECURITY] Đã thay đổi texture thành công")
	else:
		print("[DEBUG-SECURITY] Lỗi: Không có after_texture để chuyển")
	
	# Chờ một chút để người dùng thấy trạng thái mới
	print("[DEBUG-SECURITY] Bắt đầu đợi 1.5 giây")
	await get_tree().create_timer(1.5).timeout
	print("[DEBUG-SECURITY] Đã đợi xong, hiển thị card slot")
	
	# Hiển thị slot để người chơi đặt thẻ vào
	_show_card_slot()

# Hiển thị card slot để người chơi đặt thẻ bảo mật vào
func _show_card_slot():
	current_state = "card_check"
	if card_slot:
		card_slot.visible = true
		print("[DEBUG-SECURITY] Đã hiển thị card slot")
	else:
		print("[DEBUG-SECURITY] Lỗi: Không tìm thấy card slot để hiển thị")

func _complete_puzzle():
	# 🔔 Gửi tín hiệu cho security_door
	print("[DEBUG-SECURITY] Phát tín hiệu puzzle_solved")
	
	# Thêm phần thưởng vào inventory trước khi kết thúc
	_add_rewards_to_inventory()
	
	emit_signal("puzzle_solved")
	
	# 🧼 Dọn giao diện sau khi hoàn tất
	print("[DEBUG-SECURITY] Dọn dẹp UI locking system")
	queue_free()

# Hàm này được gọi từ bên ngoài (thường từ door.gd) để kiểm tra trạng thái
func check_all_slots_filled():
	# Chỉ kiểm tra slot khi đã chuyển sang giai đoạn card_check
	if current_state == "card_check" and card_slot:
		# Kiểm tra xem người chơi đã đặt thẻ vào chưa
		if card_slot.is_filled and card_slot.current_item:
			if card_slot.expected_item.has(card_slot.current_item.item_name):
				print("[DEBUG-SECURITY] Card slot đã được điền đúng item:", card_slot.current_item.item_name)
				# Hoàn thành puzzle khi đặt đúng thẻ
				_complete_puzzle()
			else:
				print("[DEBUG-SECURITY] Card slot có item không hợp lệ:", card_slot.current_item.item_name)
		else:
			print("[DEBUG-SECURITY] Card slot chưa được điền")

# Thêm phần thưởng vào inventory (nếu có)
func _add_rewards_to_inventory():
	var ui = get_tree().get_first_node_in_group("UserInterface")
	if not ui:
		print("[DEBUG-SECURITY] Không tìm thấy UserInterface để nhận phần thưởng")
		return
		
	print("[DEBUG-SECURITY] Chuẩn bị thêm phần thưởng vào inventory")
	for i in range(min(reward_items.size(), reward_amounts.size())):
		var item_name = reward_items[i]
		var qty = reward_amounts[i]
		
		# Thêm item vào inventory
		var success = ui.add_new_item_to_inventory(item_name, qty)
		if success:
			print("[DEBUG-SECURITY] Đã thêm ", item_name, " x", qty, " vào inventory")
		else:
			# Thử cách khác nếu cách đầu tiên thất bại
			success = PlayerInventory.add_item(item_name, qty)
			if success:
				print("[DEBUG-SECURITY] Đã thêm ", item_name, " x", qty, " vào inventory (qua PlayerInventory)")
				# Cập nhật giao diện inventory nếu đang mở
				if get_tree().get_first_node_in_group("Inventory"):
					get_tree().get_first_node_in_group("Inventory").initialize_inventory()
			else:
				print("[DEBUG-SECURITY] Không thể thêm ", item_name, " vào inventory")
 
