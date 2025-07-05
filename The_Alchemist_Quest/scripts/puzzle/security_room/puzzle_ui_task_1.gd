extends CanvasLayer
signal puzzle_solved  # 🔔 Tín hiệu thông báo puzzle đã hoàn thành

@onready var success_anim = $SuccessAnim  # AnimatedSprite2D
@onready var paper_slot = $PaperSlot
@onready var chemical_slot1 = $ChemicalSlot1
@onready var chemical_slot2 = $ChemicalSlot2

enum PuzzlePhase {PHASE1, PHASE2, PHASE3}
var current_phase = PuzzlePhase.PHASE1
var is_completed = false  # Biến cờ để theo dõi trạng thái hoàn thành

# 🎁 Phần thưởng cho người chơi (danh sách item và số lượng)
@export var reward_items: Array[String] = []
@export var reward_amounts: Array[int] = []

func _ready():
	# Hiển thị animation làm background và các slot thích hợp
	success_anim.visible = true
	success_anim.play("phase2") # Hiển thị phase đầu tiên
	
	# Hiển thị các chemical slots, ẩn paper slot
	chemical_slot1.visible = true
	chemical_slot2.visible = true
	paper_slot.visible = false
	
	add_to_group("PuzzleSlot")
	
	# Theo dõi slot hoàn thành để chuyển phase
	if chemical_slot1 and chemical_slot2:
		pass

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_immediately_close()

# Hàm đóng puzzle ngay lập tức
func _immediately_close():
	# Chỉ trả lại các vật phẩm nếu puzzle chưa hoàn thành
	if not is_completed:
		# Trả tất cả item về inventory trước khi đóng
		PuzzleSlot.return_all_items_to_inventory(get_tree())
	
	process_mode = Node.PROCESS_MODE_DISABLED  # Tắt xử lý
	visible = false  # Ẩn toàn bộ CanvasLayer
	queue_free()  # Xóa node

# ✅ Kiểm tra tất cả slot đã được lắp đúng chưa
func check_all_slots_filled():
	match current_phase:
		PuzzlePhase.PHASE1:
			_check_chemical_slots()
		PuzzlePhase.PHASE2:
			_check_paper_slot()

func _check_chemical_slots():
	# Kiểm tra cả hai ô hóa chất đã được điền đúng chưa
	if not chemical_slot1.is_filled or not chemical_slot2.is_filled:
		return
		
	if not chemical_slot1.expected_item.has(chemical_slot1.current_item.item_name):
		return
		
	if not chemical_slot2.expected_item.has(chemical_slot2.current_item.item_name):
		return
	
	# ✅ Đã có đủ các hóa chất đúng, chuyển sang phase2
	_advance_to_phase2()

func _check_paper_slot():
	# Kiểm tra giấy đo pH đã được đặt vào chưa
	if not paper_slot.is_filled:
		return
		
	if not paper_slot.expected_item.has(paper_slot.current_item.item_name):
		return
	
	# ✅ Đã có giấy đo pH, chuyển sang phase3
	_advance_to_phase3()

func _advance_to_phase2():
	current_phase = PuzzlePhase.PHASE2
	
	# Ẩn các chemical slot vì đã hoàn thành
	chemical_slot1.visible = false
	chemical_slot2.visible = false
	
	# Vô hiệu hóa input cho các chemical slots
	chemical_slot1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chemical_slot2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Đợi hiệu ứng hiển thị dung dịch xong
	await get_tree().create_timer(0.5).timeout
	
	# Hiển thị ô để đặt giấy đo pH
	paper_slot.visible = true
	
func _advance_to_phase3():
	current_phase = PuzzlePhase.PHASE3
	
	# Ẩn ô giấy pH
	paper_slot.visible = false
	
	# Vô hiệu hóa input cho ô giấy pH
	paper_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Hiển thị trạng thái hoàn thành
	success_anim.play("success")
	
	# Giảm thời gian chờ
	await get_tree().create_timer(0.3).timeout
	
	# Hoàn thành puzzle
	_complete_puzzle()

func _complete_puzzle():
	# Đánh dấu puzzle đã hoàn thành
	is_completed = true
	
	# Thêm phần thưởng vào inventory
	_add_rewards_to_inventory()
	
	# Phát tín hiệu puzzle_solved
	emit_signal("puzzle_solved")
	
	# Dọn dẹp giao diện - không trả lại vật phẩm vì đã hoàn thành
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	queue_free()

# Tách việc thêm phần thưởng thành một hàm riêng để code gọn hơn
func _add_rewards_to_inventory():
	var ui = get_tree().get_first_node_in_group("UserInterface")
	if not ui:
		return
		
	for i in range(min(reward_items.size(), reward_amounts.size())):
		var item_name = reward_items[i]
		var qty = reward_amounts[i]
		
		# Kiểm tra item có tồn tại trong JSONData không
		var item_exists = false
		if JsonData.item_data.has("item") and JsonData.item_data["item"].has(item_name):
			item_exists = true
		elif JsonData.item_data.has(item_name):
			item_exists = true
			
		if not item_exists:
			continue
			
		# Thêm item vào inventory
		var success = ui.add_new_item_to_inventory(item_name, qty)
		if not success:
			success = PlayerInventory.add_item(item_name, qty)
			if success and get_tree().get_first_node_in_group("Inventory"):
				get_tree().get_first_node_in_group("Inventory").initialize_inventory() 
