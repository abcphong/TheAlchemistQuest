extends CanvasLayer

@export_file("*.json") var puzzle_text_file: String

var puzzle_text = {}
var selected_text = []
var in_progress = false
var is_active = false
var puzzle_ui

signal dialog_finished

@onready var background = $MarginContainer/Background
@onready var text_label = $MarginContainer/Background/Text
@onready var turnoff_label = $MarginContainer/Background/TurnOff

func _ready():
	background.visible = false
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turnoff_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	puzzle_text = load_puzzle_text()
	if not SignalBus.is_connected("display_puzzle_dialog",on_display_dialog):
		SignalBus.connect("display_puzzle_dialog",on_display_dialog)
		
	process_mode = Node.PROCESS_MODE_ALWAYS

func load_puzzle_text():
	var file = FileAccess.open(puzzle_text_file, FileAccess.READ)
	if file:
		puzzle_text = JSON.parse_string(file.get_as_text())
		if puzzle_text:
			return puzzle_text
		else: 
			print("⚠️ Failed to parse JSON from", puzzle_text_file)
	return {}

func show_puzzle_dialog():
	if selected_text.is_empty():
		print("No text display")
		return
	text_label.text = selected_text.pop_front().replace("%n","\n")
	
func display_next_line():
	if selected_text.size() >0:
		show_puzzle_dialog()
	else:
		finish()

func finish():
	print("finishing dialog...")
	text_label.text =""
	background.visible = false
	is_active = false
	set_process_input(false)
	in_progress = false
	emit_signal("dialog_finished")
	
func on_display_dialog(text_key,trial_puzzle):
	print("✅ Signal received! Text Key:", text_key)
	puzzle_ui = trial_puzzle
	in_progress = true
	background.visible = true
	is_active = true
	var matched_key = null
	for key in puzzle_text.keys():
		if key.begins_with(text_key) and not key.begins_with("Mentor"):
			matched_key =key
			break
	if matched_key:
		selected_text = puzzle_text[matched_key].duplicate()
		print("Found dialog:", matched_key)
	else:	
		print("No dialog found for key:",text_key)
		selected_text = ["Missing diaglog puzzle"]
	show_puzzle_dialog()
	
func _input(event):
	if is_active:
		if event.is_action_pressed("ui_accept"):
			display_next_line()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("turn_off_dialog"):
			finish()
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton:
			return
