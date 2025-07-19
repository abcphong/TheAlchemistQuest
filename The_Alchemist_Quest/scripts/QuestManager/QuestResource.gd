extends Resource
class_name QuestResource

@export var quest_name: String
@export_multiline var quest_description: String
@export_multiline var reached_goal_text: String

# Cách kích hoạt nhiệm vụ
enum ActivationType { 
	NPC_INTERACTION,  # Tương tác với NPC
	AUTO_START,       # Tự động bắt đầu
	MAP_ENTER,        # Khi vào map
	EVENT_TRIGGERED   # Khi sự kiện xảy ra
}
@export var activation_type: ActivationType = ActivationType.NPC_INTERACTION

# NPC Interaction
@export var npc_id: String = ""  # ID của NPC liên quan
@export_file("*.tscn") var next_scene: String = ""  # Scene chuyển tiếp sau khi hoàn thành

# Map Enter
@export var target_map: String = ""  # Map kích hoạt nhiệm vụ

# Event Triggered
@export var trigger_event: String = ""  # Tên sự kiện kích hoạt

# Hiển thị marker
@export var show_marker: bool = true
@export var marker_texture: Texture2D
