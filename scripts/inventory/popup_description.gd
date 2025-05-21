extends Label

@onready var panel = get_parent().get_parent()
@onready var item_name_label = get_parent().get_node("ItemNameLabel")
@onready var item_image = get_parent().get_node("ItemImageRect")

const PANEL_SIZE = Vector2(300,350)
# Add these constants at the top
const POPUP_WIDTH := 300
const IMAGE_SIZE := 64
const LEFT_OFFSET := Vector2(-320, -150)

func show_description(item_data: Dictionary, mouse_pos: Vector2):
	item_name_label.text = item_data["name"]
	item_image.texture = load(item_data["image_path"])
	text = item_data["description"]
	
	#Set text styles
	item_name_label.add_theme_font_size_override("font_size",20)
	item_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_name_label.add_theme_color_override("font_color",Color.GOLD)
	autowrap_mode = TextServer.AUTOWRAP_WORD
	
	#Configure image
	item_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_image.custom_minimum_size = Vector2(100,100)
	item_image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	size = Vector2(POPUP_WIDTH,0)
	position = mouse_pos + LEFT_OFFSET
	
	var viewport = get_viewport()
	position.x = max(position.x,10)
	position.y = clamp(position.y,10,viewport.size.y - size.y - 10)
	
	# Ensure visibility
	panel.show()
	show()
