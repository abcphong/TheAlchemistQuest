extends CanvasLayer
signal puzzle_solved  # 🔔 Tín hiệu thông báo puzzle đã hoàn thành

@onready var success_anim = $SuccessAnim  # AnimatedSprite2D
@onready var paper_slot = $PaperSlot
@onready var chemical_slot1 = $ChemicalSlot1
@onready var chemical_slot2 = $ChemicalSlot2

enum PuzzlePhase {PHASE1, PHASE2, PHASE3}
var current_phase = PuzzlePhase.PHASE1

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
	
	print("[DEBUG-PUZZLE] Security Room Task1 khởi tạo")
	print("[DEBUG-PUZZLE] Animation frames hiện có:", success_anim.sprite_frames.get_animation_names())
	print("[DEBUG-PUZZLE] Animation hiện tại:", success_anim.animation)
	
	# Theo dõi slot hoàn thành để chuyển phase
	if chemical_slot1 and chemical_slot2:
		print("[DEBUG-PUZZLE] Chemical slot 1 expected:", chemical_slot1.expected_item)
		print("[DEBUG-PUZZLE] Chemical slot 2 expected:", chemical_slot2.expected_item)
		print("[DEBUG-PUZZLE] Paper slot expected:", paper_slot.expected_item)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_immediately_close()

# Hàm đóng puzzle ngay lập tức
func _immediately_close():
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
	print("[DEBUG-PUZZLE] Kiểm tra chemical slots")
	
	# Kiểm tra cả hai ô hóa chất đã được điền đúng chưa
	if not chemical_slot1.is_filled or not chemical_slot2.is_filled:
		return
		
	if not chemical_slot1.expected_item.has(chemical_slot1.current_item.item_name):
		print("[DEBUG-PUZZLE] Chemical slot 1 sai: Có ", chemical_slot1.current_item.item_name)
		return
		
	if not chemical_slot2.expected_item.has(chemical_slot2.current_item.item_name):
		print("[DEBUG-PUZZLE] Chemical slot 2 sai: Có ", chemical_slot2.current_item.item_name)
		return
	
	# ✅ Đã có đủ các hóa chất đúng, chuyển sang phase2
	print("[DEBUG-PUZZLE] Chemical slots đã được điền đúng, chuyển sang phase 2")
	_advance_to_phase2()

func _check_paper_slot():
	print("[DEBUG-PUZZLE] Kiểm tra paper slot")
	
	# Kiểm tra giấy đo pH đã được đặt vào chưa
	if not paper_slot.is_filled:
		return
		
	if not paper_slot.expected_item.has(paper_slot.current_item.item_name):
		print("[DEBUG-PUZZLE] Paper slot sai: Có ", paper_slot.current_item.item_name)
		return
	
	# ✅ Đã có giấy đo pH, chuyển sang phase3
	print("[DEBUG-PUZZLE] Paper slot đã được điền đúng, chuyển sang phase 3")
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
	
	print("[DEBUG-PUZZLE] Đã chuyển sang phase 2, hiển thị ô đặt giấy pH")

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
	print("[DEBUG-PUZZLE] Puzzle hoàn thành!")

	# Thêm phần thưởng vào inventory trước
	_add_rewards_to_inventory()
	
	# Phát tín hiệu puzzle_solved ngay lập tức
	print("[DEBUG-PUZZLE] Phát tín hiệu puzzle_solved")
	emit_signal("puzzle_solved")
	
	# Đóng giao diện ngay lập tức
	_immediately_close()

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
