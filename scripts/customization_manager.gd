extends Node

signal color_update(color:Color)
var character_data: CharacterData
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	character_data = CharacterData.new()
	print("Manager initialized")

func update_skin_color(new_color: Color)-> void:
	if not character_data:
		push_error("no character data available!")
		
	if new_color.a < 1.0:
		push_warning("color alpha ignore for skin tone.")
		new_color.a = 1.0
	character_data.skin_color = new_color
	color_update.emit(new_color)
	
