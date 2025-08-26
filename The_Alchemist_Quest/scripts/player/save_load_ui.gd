extends Control

@onready var save_slots_container = $PanelContainer/MarginContainer/VBoxContainer/SaveSlotsContainer
@onready var save_name_edit = $PanelContainer/MarginContainer/VBoxContainer/SaveNameContainer/SaveNameEdit
@onready var close_button = $PanelContainer/MarginContainer/VBoxContainer/CloseButton
@onready var message_label = $PanelContainer/MarginContainer/VBoxContainer/MessageLabel

# Các nút slot lưu game
var save_slot_buttons = []
var load_slot_buttons = []
var delete_slot_buttons = []
var slot_labels = []

# Slot đang được chọn
var selected_slot = 0

# Thời gian hiển thị thông báo
var message_timer = 0.0
const MESSAGE_DISPLAY_TIME = 3.0

func _ready():
	print("[DEBUG-SaveLoadUI] _ready() được gọi")
	
	# Đảm bảo SaveLoadUI có thể nhận input
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	print("[DEBUG-SaveLoadUI] Process mode:", process_mode)
	print("[DEBUG-SaveLoadUI] Mouse filter:", mouse_filter)
	
	# Khởi tạo các nút và label cho từng slot
	for i in range(SaveLoadManager.MAX_SAVE_SLOTS):
		# Tạo container cho mỗi slot
		var slot_container = HBoxContainer.new()
		slot_container.size_flags_horizontal = Control.SIZE_FILL
		save_slots_container.add_child(slot_container)
		
		# Tạo label hiển thị thông tin slot
		var slot_label = Label.new()
		slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_container.add_child(slot_label)
		slot_labels.append(slot_label)
		
		# Tạo nút Save
		var save_button = Button.new()
		save_button.text = "Lưu"
		save_button.custom_minimum_size = Vector2(60, 0)
		save_button.mouse_filter = Control.MOUSE_FILTER_STOP
		save_button.pressed.connect(_on_save_slot_button_pressed.bind(i))
		slot_container.add_child(save_button)
		save_slot_buttons.append(save_button)
		
		# Tạo nút Load
		var load_button = Button.new()
		load_button.text = "Tải"
		load_button.custom_minimum_size = Vector2(60, 0)
		load_button.mouse_filter = Control.MOUSE_FILTER_STOP
		load_button.pressed.connect(_on_load_slot_button_pressed.bind(i))
		slot_container.add_child(load_button)
		load_slot_buttons.append(load_button)
		
		# Tạo nút Delete
		var delete_button = Button.new()
		delete_button.text = "Xóa"
		delete_button.custom_minimum_size = Vector2(60, 0)
		delete_button.mouse_filter = Control.MOUSE_FILTER_STOP
		delete_button.pressed.connect(_on_delete_slot_button_pressed.bind(i))
		slot_container.add_child(delete_button)
		delete_slot_buttons.append(delete_button)
	
	# Kết nối nút đóng
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
		print("[DEBUG-SaveLoadUI] Đã kết nối nút Đóng")
		# Đảm bảo nút Đóng có thể nhận input
		close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		print("[ERROR-SaveLoadUI] Không tìm thấy close_button!")
	
	# Ẩn menu khi khởi động
	visible = false
	
	# Cập nhật thông tin các slot
	update_save_slots_info()

func _process(delta):
	# Xử lý thông báo tạm thời
	if message_timer > 0:
		message_timer -= delta
		if message_timer <= 0:
			message_label.text = ""

func toggle_visibility():
	visible = !visible
	
	if visible:
		# Cập nhật thông tin các slot khi mở menu
		update_save_slots_info()
		# Reset tên bản lưu
		save_name_edit.text = "Bản lưu #" + str(selected_slot + 1)

func update_save_slots_info():
	var save_info_array = SaveLoadManager.get_all_save_info()
	
	for i in range(SaveLoadManager.MAX_SAVE_SLOTS):
		var info = save_info_array[i]
		var slot_text = "Slot " + str(i + 1) + ": "
		
		if info.exists:
			slot_text += info.name + " (" + info.time + ")"
			load_slot_buttons[i].disabled = false
			delete_slot_buttons[i].disabled = false
		else:
			slot_text += "[Trống]"
			load_slot_buttons[i].disabled = true
			delete_slot_buttons[i].disabled = true
			
		slot_labels[i].text = slot_text

func _on_save_slot_button_pressed(slot: int):
	selected_slot = slot
	var save_name = save_name_edit.text
	if save_name.is_empty():
		save_name = "Bản lưu #" + str(slot + 1)
	
	var success = SaveLoadManager.save_game(slot, save_name)
	if success:
		show_message("Đã lưu game thành công vào slot " + str(slot + 1) + "!")
		update_save_slots_info()
	else:
		show_message("Không thể lưu game vào slot " + str(slot + 1) + "!", true)

func _on_load_slot_button_pressed(slot: int):
	if SaveLoadManager.has_save_game(slot):
		var success = SaveLoadManager.load_game(slot)
		if success:
			show_message("Đã tải game thành công từ slot " + str(slot + 1) + "!")
			visible = false  # Ẩn menu sau khi tải game
		else:
			show_message("Không thể tải game từ slot " + str(slot + 1) + "!", true)
	else:
		show_message("Không tìm thấy file lưu game ở slot " + str(slot + 1) + "!", true)

func _on_delete_slot_button_pressed(slot: int):
	if SaveLoadManager.has_save_game(slot):
		var success = SaveLoadManager.delete_save_game(slot)
		if success:
			show_message("Đã xóa bản lưu ở slot " + str(slot + 1) + "!")
			update_save_slots_info()
		else:
			show_message("Không thể xóa bản lưu ở slot " + str(slot + 1) + "!", true)
	else:
		show_message("Không có bản lưu nào ở slot " + str(slot + 1) + "!", true)

func _on_close_button_pressed():
	print("[DEBUG-SaveLoadUI] Nút Đóng được ấn!")
	visible = false

func _unhandled_input(event):
	if event.is_action_pressed("toggle_save_menu"):
		toggle_visibility()
		get_viewport().set_input_as_handled()
	
	if event.is_action_pressed("ui_cancel") and visible:
		visible = false
		get_viewport().set_input_as_handled()

func show_message(text: String, is_error: bool = false):
	message_label.text = text
	message_timer = MESSAGE_DISPLAY_TIME
	
	if is_error:
		message_label.add_theme_color_override("font_color", Color.RED)
	else:
		message_label.add_theme_color_override("font_color", Color.GREEN) 
