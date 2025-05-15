extends Control


@onready var option_button: OptionButton = $HBoxContainer/OptionButton


const WINDOWED_MODE_ARRAY : Array[String] = [
	"Full Screen",
	"Windowed Mode",
	"Borderless Windowed",
	"Borderless Fullscreen"
]

func _ready() -> void:
	add_window_mode_items()
	option_button.item_selected.connect(on_windowed_mode_selected)


func add_window_mode_items() -> void:
	for windowed_mode in WINDOWED_MODE_ARRAY:
		option_button.add_item(windowed_mode)


func on_windowed_mode_selected(index : int) -> void:
	match index :
		0: #Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		1: #Windowed Mode
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		2: #Borderless Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		3: #Borderless Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
