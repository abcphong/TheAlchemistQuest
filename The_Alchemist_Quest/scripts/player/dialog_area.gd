extends Area2D

@export var dialog_key: String =""
@export_file("*.json") var dialog_file 
var area_active = false

func _ready():
	# Ensure collision shape is set up
	var collision_shape = $CollisionShape2D
	if not collision_shape:
		push_error("❌ CollisionShape2D not found under DialogArea")
		return

func _on_body_entered(body):
	if body.name == "Player" and not DialogPlayer.in_progress:
		# Set the dialog file for this NPC
		DialogPlayer.set_dialog_file(dialog_file)
		# Emit signal to display dialog
		SignalBus.emit_signal("display_dialog", dialog_key, get_parent())
		print("📢 Triggered dialog for ", dialog_key)

func _on_body_exited(body):
	if body.name == "Player":
		print("👤 Player exited dialog area")
