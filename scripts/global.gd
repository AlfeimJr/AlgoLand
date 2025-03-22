extends Node2D

# Variável para rastrear se algo está sendo arrastado
var is_dragging: bool = false

func _ready():
	modulate = Color(Color.MEDIUM_PURPLE, 0.7)
	
func _process(delta):
	if Global.is_dragging:
		visible = true
	else:
		visible = false
