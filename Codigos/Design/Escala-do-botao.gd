extends Button

# Escala original
var escala_original = Vector2(1, 1)
# Escala ao passar o mouse
var escala_hover = Vector2(1.2, 1.2)

func _ready():
	pass

func _on_mouse_entered():
	# Aumentar a escala ao passar o mouse
	$"../AnimationPlayer".play("hover_scale")

func _on_mouse_exited():
	# Voltar à escala original ao sair o mouse
	$"../AnimationPlayer".play_backwards("hover_scale")


func _on_pressed() -> void:
	pass
