extends CanvasLayer

# Tham chiếu đến các node camera
@onready var camera1 = $MonitorPanel/MainVBox/Cameras/CameraThumbnails/Camera1
@onready var camera2 = $MonitorPanel/MainVBox/Cameras/CameraThumbnails/Camera2
@onready var camera3 = $MonitorPanel/MainVBox/Cameras/CameraThumbnails/Camera3
@onready var main_screen = $MonitorPanel/MainVBox/Cameras/MainScreen
@onready var status_label = $MonitorPanel/MainVBox/StatusPanel/HBox/StatusLabel

# Tham chiếu đến SceneView
@onready var camera1_view = $MonitorPanel/MainVBox/Cameras/CameraThumbnails/Camera1/SceneView
@onready var camera2_view = $MonitorPanel/MainVBox/Cameras/CameraThumbnails/Camera2/SceneView
@onready var camera3_view = $MonitorPanel/MainVBox/Cameras/CameraThumbnails/Camera3/SceneView
@onready var main_view = $MonitorPanel/MainVBox/Cameras/MainScreen/SceneView

# Biến theo dõi camera đang được chọn
var active_camera = 0
var static_timer = 0.0

# Texture cho các camera
var intro_room_texture
var storage_room_texture

# Shader cho hiệu ứng nhiễu TV
var tv_noise_shader

func _ready():
	# Tải shader nhiễu TV
	tv_noise_shader = load("res://The_Alchemist_Quest/assets/shaders/tv_noise.gdshader")
	
	# Tải texture cho các camera
	_load_camera_textures()
	
	# Kết nối tín hiệu click cho mỗi camera
	for i in range(1, 4):  # Chỉ có 3 camera
		var camera = get_node("MonitorPanel/MainVBox/Cameras/CameraThumbnails/Camera" + str(i))
		if camera:
			# Thêm tính năng click cho mỗi camera
			var button = Button.new()
			button.flat = true
			button.modulate = Color(1, 1, 1, 0)  # Trong suốt
			button.size = camera.size
			button.position = Vector2(0, 0)
			camera.add_child(button)
			
			# Kết nối tín hiệu click
			button.pressed.connect(_on_camera_pressed.bind(i))
	
	# Áp dụng shader cho camera 3 và màn hình chính
	_apply_noise_shader()

	print("[SecurityMonitorUI] Đã khởi tạo giao diện màn hình giám sát")
	
	# Hiển thị camera đầu tiên mặc định
	_switch_to_camera(1)

# Tải texture cho các camera
func _load_camera_textures():
	# Tải texture cho Intro Room
	intro_room_texture = load("res://The_Alchemist_Quest/assets/screenshots/intro_room_camera.png")
	if intro_room_texture:
		camera1_view.texture = intro_room_texture
		print("[SecurityMonitorUI] Đã tải texture Intro Room")
	else:
		print("[SecurityMonitorUI] Không thể tải texture Intro Room")
	
	# Tải texture cho Storage Room
	storage_room_texture = load("res://The_Alchemist_Quest/assets/screenshots/storage_room_camera.png")
	if storage_room_texture:
		camera2_view.texture = storage_room_texture
		print("[SecurityMonitorUI] Đã tải texture Storage Room")
	else:
		print("[SecurityMonitorUI] Không thể tải texture Storage Room")
	
	# Camera 3 sẽ sử dụng hiệu ứng nhiễu tạo bằng shader
	camera3_view.texture = null

# Áp dụng shader nhiễu TV cho các đối tượng cần thiết
func _apply_noise_shader():
	if !tv_noise_shader:
		print("[SecurityMonitorUI] Lỗi: Không thể tải shader nhiễu TV")
		return
	
	# Tạo và áp dụng material cho static của camera 3
	var static_effect3 = camera3_view.get_node("Static")
	var noise_material_cam3 = ShaderMaterial.new()
	noise_material_cam3.shader = tv_noise_shader
	static_effect3.material = noise_material_cam3
	
	# Tạo và áp dụng material cho static của màn hình chính
	var main_static = main_view.get_node("Static")
	var noise_material_main = ShaderMaterial.new()
	noise_material_main.shader = tv_noise_shader
	main_static.material = noise_material_main
	
	# Ẩn hiệu ứng nhiễu ban đầu
	static_effect3.visible = true # Luôn hiển thị nhiễu trên thumbnail camera 3
	main_static.visible = false

# Xử lý khi người chơi nhấn vào một camera
func _on_camera_pressed(camera_id):
	print("[SecurityMonitorUI] Đã chọn camera " + str(camera_id))
	_switch_to_camera(camera_id)

# Chuyển đổi giữa các camera
func _switch_to_camera(camera_id):
	active_camera = camera_id
	
	# Lấy các node cần thiết
	var main_static = main_view.get_node("Static")
	
	# Cập nhật màn hình chính dựa trên camera được chọn
	match camera_id:
		1:
			if intro_room_texture:
				main_view.texture = intro_room_texture
			main_static.visible = false
			_update_status_display("Đang xem Intro Room - Tín hiệu ổn định")
		2:
			if storage_room_texture:
				main_view.texture = storage_room_texture
			main_static.visible = false
			_update_status_display("Đang xem Storage Room - Tín hiệu ổn định")
		3:
			main_view.texture = null  # Xóa texture hiện tại
			main_static.visible = true # Hiển thị nhiễu TV
			_update_status_display("Tín hiệu không ổn định - Nhiễu mạnh")
	
	# Hiển thị thông tin camera đang xem
	var selected_camera = get_node("MonitorPanel/MainVBox/Cameras/CameraThumbnails/Camera" + str(camera_id))
	if selected_camera:
		var main_label = main_screen.get_node("Label")
		if main_label:
			main_label.text = "Đang xem: " + selected_camera.get_node("Label").text

# Xử lý khi người chơi nhấn nút đóng
func _on_close_button_pressed():
	print("[SecurityMonitorUI] Đóng giao diện màn hình giám sát")
	queue_free()

# Xử lý input bàn phím
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("[SecurityMonitorUI] Đóng giao diện bằng phím ESC")
		queue_free()
	
	# Chuyển đổi camera bằng phím số
	for i in range(1, 4):  # Chỉ có 3 camera
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_1 + i - 1:  # KEY_1, KEY_2, KEY_3
				_switch_to_camera(i)

# Cập nhật hiệu ứng nhiễu
func _process(delta):
	# Cập nhật hiệu ứng nhiễu nhẹ
	static_timer += delta
	if static_timer >= 0.05:  # Cập nhật mỗi 0.05 giây
		static_timer = 0.0
		_update_static_effect()

# Tạo hiệu ứng nhiễu cho các màn hình camera
func _update_static_effect():
	# Cập nhật hiệu ứng nhiễu nhẹ cho camera 1 và 2
	for i in range(1, 3):
		var camera_view = get_node("MonitorPanel/MainVBox/Cameras/CameraThumbnails/Camera" + str(i) + "/SceneView")
		if camera_view:
			var static_effect = camera_view.get_node("Static")
			static_effect.color = Color(1, 1, 1, randf() * 0.05)  # Nhiễu nhẹ
	
	# Cập nhật nhiễu cho màn hình chính nếu không xem camera 3
	if active_camera != 3:
		var main_static = main_view.get_node("Static")
		if main_static and main_static.material == null: # Chỉ áp dụng nhiễu nhẹ nếu không có shader
			main_static.visible = true
			main_static.color = Color(1, 1, 1, randf() * 0.03)
		elif main_static:
			main_static.visible = false

# Cập nhật hiển thị trạng thái
func _update_status_display(status_text):
	if status_label:
		status_label.text = "Trạng thái: " + status_text 
