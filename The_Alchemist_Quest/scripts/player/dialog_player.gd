extends CanvasLayer

@export_file("*.json") var scence_text_file: String

var scence_text = {}
var selected_text = []
var in_progress = false
var mentor_npc

@onready var background = $MarginContainer/Background
@onready var text_label = $MarginContainer/Background/Text
@onready var turnoff_label = $MarginContainer/Background/TurnOff

func _ready():
	background.visible = false
	scence_text = load_scence_text()
	if not SignalBus.is_connected("display_dialog", on_display_dialog):
		SignalBus.connect("display_dialog", on_display_dialog)

func load_scence_text():
	var file = FileAccess.open(scence_text_file, FileAccess.READ)
	if file:
		var content =file.get_as_text()
		var parsed_data = JSON.parse_string(content)
		if parsed_data:
			return parsed_data
		else:
			print("⚠️ Failed to parse JSON from", scence_text_file)
	return {}

func show_text():
	if selected_text.is_empty():
		print("No text display")
		return
	text_label.text = selected_text.pop_front().replace("%n","\n")

func next_line():
	if selected_text.size() > 0:
		show_text()
	else:
		finish()

func _input(event):
	if event.is_action_pressed("turn_off_dialog") and in_progress:
		print("🚀 Space Pressed! Calling finish()... (Current dialog_stage:", mentor_npc.dialog_stage, ")")
		finish()


func finish():
	print("✅ finish() called! Hiding dialog and resuming game...")
	
	text_label.text = ""
	background.visible = false
	in_progress = false

	get_tree().paused = false  # Resume the game
	set_process_input(false) #Disable input while no dialog is active
	
	if mentor_npc:
		print("mentor_npc.dialog_stage =", mentor_npc.dialog_stage)
		
		#Move to the next stage
		mentor_npc.dialog_stage +=1
		print("📌 Moved to Stage:", mentor_npc.dialog_stage)
		
		if mentor_npc.dialog_stage ==1:
			print("✅ Showing Exclamation Mark!")
			mentor_npc.exclamination_mark.visible= true
			print("📌 mentor_npc.dialog_stage after increment:", mentor_npc.dialog_stage)
	else:
		print("⚠️ mentor_npc not assigned!")

func on_display_dialog(text_key,npc):
	print("✅ Signal received! Text Key:", text_key)
	mentor_npc = npc  # Assign NPC reference correctly
	in_progress = true  # Make sure input works!
	
	set_process_input(true)  # Ensure Space key is detected
	get_tree().paused = true  # Pause game for dialog
	background.visible = true  # Show dialog UI

	#Find the correct dialog key
	var matched_key = null
	for key in scence_text.keys():
		if key.begins_with(text_key):
			matched_key =key
			break
			
	if matched_key:
		selected_text = scence_text[matched_key].duplicate()
		print("Found dialog:", matched_key)
	else:
		print("No dialog found for key: ", text_key)
		selected_text = ["(Missing dialog for: " + text_key + ")"]
	
	show_text()
