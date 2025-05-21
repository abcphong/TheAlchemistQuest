extends Timer


func _ready() -> void:
	$"..".visible = true # show the label initialy
	$".".start() # Count 5s

func _on_timeout() -> void:
	$"..".visible = false
