extends Area2D

@export var dialog_key: String = "Mentor"  # Set this in the editor for different NPCs
@onready var exclamination_mark = $exclamination_mark

var dialog_stage = 0  # Track which sentence is being displayed

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		print("📌 Contact to NPC - Dialog Key:", "'" + dialog_key + "'")  
	
		var current_key = dialog_key + "_" + str(dialog_stage + 1)  
		SignalBus.emit_signal("display_dialog", current_key, self)  # ✅ Pass self (NPC reference)



func _ready() -> void:
	print("🛠 Mentor NPC Ready - Dialog Key:", "'" + dialog_key + "'")
	exclamination_mark.visible = false  # Hide in the first sentence
