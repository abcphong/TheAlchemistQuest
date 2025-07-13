extends Control

var current_page := 0
var pages = [
	{
		# Trang 1: Giới thiệu
		"story": """Alex Carter – một sinh viên tài năng, vừa được nhận vào chương trình thực tập tại Nexus: trung tâm nghiên cứu sinh – hóa học tiên phong toàn cầu.

Ẩn sau những bức tường thép kiên cố là hàng loạt dự án tối mật, những hợp chất mới có thể thay đổi tương lai của công nghệ sinh học và năng lượng.

Đây là cơ hội vàng trong sự nghiệp của bạn. Nhưng tại Nexus, mọi thứ đều được giám sát nghiêm ngặt, và không phải lúc nào mọi câu hỏi cũng có lời giải đáp...

Bạn đã sẵn sàng bắt đầu ngày thực tập đầu tiên?""",

		"controls": ""  # Trang này không hiển thị điều khiển
	},
	{
		# Trang 2: Hướng dẫn điều khiển
		"story": "",  # Không cần story nữa
		"controls": """🎮 Điều khiển cơ bản:
- W A S D: Di chuyển
- Tab: Mở túi đồ
- E: Tương tác / Nhặt vật phẩm
- ESC: Mở menu thiết lập
- Chuột trái: Kéo thả vật phẩm trong túi
- Chuột phải: Tách riêng 1 đơn vị vật phẩm"""
	}
]
func _ready():
	update_page()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Chuyển trang: nếu đang ở 0 → 1, nếu đang ở 1 → 0
		current_page = 1 - current_page
		update_page()

	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# Nhấn ESC → trở về trang homepage
		get_tree().change_scene_to_file("res://The_Alchemist_Quest/scenes/homepage/homepage.tscn")
		
func update_page():
	$MarginContainer/VBoxContainer/StoryLabel.text = pages[current_page]["story"]
	$MarginContainer/VBoxContainer/ControlGuideLabel.text = pages[current_page]["controls"]
	$PageIndicatorLabel.text = "Trang %d / %d" % [current_page + 1, pages.size()]
