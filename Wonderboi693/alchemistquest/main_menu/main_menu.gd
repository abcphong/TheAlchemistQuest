class_name MainMenu
extends Control


@onready var start_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/Start
@onready var option_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/Option
@onready var options_menu: OptionsMenu = $Options_Menu
@onready var margin_container: MarginContainer = $MarginContainer
@onready var leave_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/Leave
# @export var star_level = preload()

func _ready() -> void:
	handle_connection_signals()

func on_start_pressed() -> void:
	print("start pressed")

func on_option_pressed() -> void:
	margin_container.visible = false
	options_menu.set_process(true)
	options_menu.visible = true

func on_exit_options_menu() -> void:
	margin_container.visible = true
	options_menu.visible = false

func on_exit_pressed() -> void:
	get_tree().quit()

func handle_connection_signals() -> void:
	start_button.button_down.connect(on_start_pressed)
	option_button.button_down.connect(on_option_pressed)
	leave_button.button_down.connect(on_exit_pressed)
	options_menu.exit_options_menu.connect(on_exit_options_menu)
