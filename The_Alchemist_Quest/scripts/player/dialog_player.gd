extends CanvasLayer

@export_file("*.json") var dialog_text_file: String  # Optional, can be overridden dynamically

var dialog_text = {}
var selected_text = []
var in_progress = false
var is_active = false
var associated_node = null  # For MentorNPC, puzzle, or null for Player_2


signal dialog_finished

@onready var background = $MarginContainer/Background
@onready var text_label = $MarginContainer/Background/Text
@onready var turnoff_label = $MarginContainer/Background/TurnOff

func _ready():
	# Instantiate dialogPlayer.tscn for UI (fix path typo: scenes -> scenes)
	var dialog_scene = preload("res://The_Alchemist_Quest/scenes/dialog_player.tscn")
	var dialog_instance = dialog_scene.instantiate()
	add_child(dialog_instance)
	
	# Update references from the dialog_instance
	background = dialog_instance.get_node("MarginContainer/Background")
	text_label = background.get_node("Text")
	turnoff_label = background.get_node("TurnOff")
	
	# Verify node references
	if not background or not text_label or not turnoff_label:
		push_error("❌ Dialog UI nodes not found. Check dialog_player.tscn structure.")
		return
	
	# Ensure dialog starts hidden with a small delay
	await get_tree().create_timer(0.1).timeout
	if background:
		background.visible = false
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		turnoff_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("📋 Dialog initialized, background hidden")
	
	# Load dialog text and log result
	if dialog_text_file:
		dialog_text = load_dialog_text()
		print("📄 Loaded dialog file: ", dialog_text_file, " - Content: ", dialog_text.keys())
	else:
		print("⚠️ No default dialog_text_file set in DialogPlayer")
	
	# Connect signals (alternative syntax without callable)
	if not SignalBus.is_connected("display_dialog", self.on_display_dialog):
		var err = SignalBus.connect("display_dialog", self.on_display_dialog)
		if err != OK:
			print("❌ Failed to connect display_dialog signal: ", err)
		else:
			print("✅ Connected display_dialog signal")
	if not SignalBus.is_connected("display_puzzle_dialog", self.on_display_dialog):
		var err = SignalBus.connect("display_puzzle_dialog", self.on_display_dialog)
		if err != OK:
			print("❌ Failed to connect display_puzzle_dialog signal: ", err)
		else:
			print("✅ Connected display_puzzle_dialog signal")
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func load_dialog_text():
	var file = FileAccess.open(dialog_text_file, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(content)
		if error == OK:
			var result = json.get_data()
			# Convert string values to arrays for consistency
			for key in result.keys():
				if result[key] is String:
					result[key] = [result[key]]
			print("✅ Parsed JSON successfully: ", dialog_text_file, " Keys: ", result.keys())
			return result
		else:
			print("⚠️ Failed to parse JSON from ", dialog_text_file, " Error: ", error, " - ", json.get_error_message())
			return {}
	else:
		print("❌ Could not open dialog file: ", dialog_text_file, " - Check path and file existence")
		return {}


func show_dialog():
	if selected_text.is_empty():
		print("No text to display")
		finish()
		return
	if text_label:
		text_label.text = selected_text.pop_front().replace("%n", "\n")
		print("📝 Displaying text: ", text_label.text)

func next_line():
	if selected_text.size() > 0:
		show_dialog()
	else:
		finish()

func _input(event):
	if in_progress and is_active:
		if event.is_action_pressed("ui_accept"):
			next_line()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("turn_off_dialog"):
			finish()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton:
			return

func finish():
	print("✅ Finishing dialog...")
	if text_label:
		text_label.text = ""
	if background:
		background.visible = false
	in_progress = false
	is_active = false
	set_process_input(false)
	get_tree().paused = false
	
	if associated_node and "dialog_stage" in associated_node:
		associated_node.dialog_stage += 1
		print("📌 Moved to Stage:", associated_node.dialog_stage)
		if associated_node.dialog_stage == 1:
			if "exclamination_mark" in associated_node:
				associated_node.exclamination_mark.visible = true
				print("✅ Showing Exclamation Mark!")
	
	emit_signal("dialog_finished")

func on_display_dialog(text_key, node = null):
	if in_progress:
		print("⚠️ Dialog already in progress, ignoring new request")
		return
	print("✅ Signal received! Text Key:", text_key, " Node:", node)
	associated_node = node
	in_progress = true
	is_active = true
	set_process_input(true)
	get_tree().paused = true
	if background:
		background.visible = true
	
	var matched_key = null
	for key in dialog_text.keys():
		if key.begins_with(text_key):
			matched_key = key
			break
	print("📄 Dialog keys available:", dialog_text.keys())
	print("Requested key:", text_key)
	if matched_key:
		selected_text = dialog_text[matched_key].duplicate()
		print("Found dialog:", matched_key, " Text:", selected_text)
	else:
		print("No dialog found for key:", text_key)
		selected_text = ["(Missing dialog for: " + text_key + ")"]
	
	show_dialog()

func set_dialog_file(new_file: String):
	if new_file != dialog_text_file or dialog_text.is_empty():
		dialog_text_file = new_file
		dialog_text = load_dialog_text()
		print("📄 Switched dialog file to:", new_file, " - Content: ", dialog_text.keys())
