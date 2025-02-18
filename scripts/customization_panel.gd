extends Panel



@onready var color_picker = $MarginContainer/VBoxContainer/ColorPickerButton

func _ready():
	color_picker.color = CustomizationManager.character_data.skin_color
	color_picker.color_changed.connect(_on_color_changed)
	_setup_presets()
	
func _on_color_changed(color:Color):
	CustomizationManager.update_skin_color(color)


func _setup_presets():
	var presets = [
		Color(0.98, 0.84, 0.65),
		Color(0.85, 0.65, 0.45),
		Color(0.65, 0.45, 0.25),
	]
	
	for color in presets:
		color_picker.get_picker().add_preset(color)
