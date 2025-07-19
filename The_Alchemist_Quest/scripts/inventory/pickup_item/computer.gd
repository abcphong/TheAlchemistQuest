extends InteractableBase

var initial_dialog_shown = false
@export var initial_dialog_key := "Computer"
@export var pickup_dialog_key := "Player_pickup_zn"
@export_file("*.json") var dialog_file 

func _ready():
	# Initialize computer-specific settings
	add_to_group("computer")
	item_name = "Zinc bar"
	item_quantity = 1
	interaction_group = "computer"
	
	# Call parent _ready
	super._ready()
	
	collision_layer = 2  # Layer 2 for interactable objects
	collision_mask = 1   # Mask 1 for player
	
func _on_player_entered(body: Node2D):
	print("🔵 Computer: Player entered area")

func _on_player_exited(body: Node2D):
	print("🴴 Player exited computer area")

func _handle_interaction():
	print("🔵 Computer interaction triggered")
	
	if not initial_dialog_shown:
		# Hiện thị dialog environemnt của computer
		DialogPlayer.set_dialog_file(dialog_file)
		SignalBus.emit_signal("display_dialog", initial_dialog_key)
		initial_dialog_shown = true
		print("Dialog states:", "Initial shown:", initial_dialog_shown)
	else:
		# Cho lớp cha xử lí pickup
		super._handle_interaction()

func _on_item_given():
	# Hiển thị dialog khi pick up thành công 
	print("✅ Successfully added Zinc bar to inventory")
	DialogPlayer.set_dialog_file(dialog_file)
	SignalBus.emit_signal("display_dialog", pickup_dialog_key)
	print("Dialog states:", "Initial shown:", initial_dialog_shown, "Has item:", has_given_item)
	
	# Tuyền signal (Nếu cần cho thiết bị khác)
	super._on_item_given()
