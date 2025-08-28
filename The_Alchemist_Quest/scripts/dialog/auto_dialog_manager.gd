# auto_dialog_manager.gd
# Đặt script này vào một node trong scene demoroom.tscn (có thể là root node)

extends Node

@export_file("*.json") var auto_dialog_file: String = "res://The_Alchemist_Quest/assets/json/auto_dialog.json"
@export var dialog_key: String = "Welcome"
@export var delay_seconds: float = 0.5  # Delay trước khi hiện dialog

func _ready():
	# Đợi scene hoàn toàn load xong
	await get_tree().process_frame
	await get_tree().create_timer(delay_seconds).timeout
	
	# Kích hoạt auto dialog
	trigger_auto_dialog()

func trigger_auto_dialog():
	print("🎬 Triggering auto dialog...")
	
	# Set dialog file cho DialogPlayer
	if DialogPlayer:
		DialogPlayer.set_dialog_file(auto_dialog_file)
		
		# Emit signal để hiện dialog (không cần node liên kết)
		SignalBus.emit_signal("display_dialog", dialog_key, null)
		print("📢 Auto dialog triggered with key: ", dialog_key)
	else:
		print("❌ DialogPlayer not found in autoload")
