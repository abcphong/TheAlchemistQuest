class_name OptionsMenu
extends Control

@onready var exit: Button = $MarginContainer/VBoxContainer/Exit

signal exit_options_menu


func _ready() -> void:
	exit.button_down.connect(on_exit_pressed)

func on_exit_pressed() -> void:
	exit_options_menu.emit()
	set_process(false)
