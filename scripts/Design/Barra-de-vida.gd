extends Node2D

@export var max_health: int = 25
var current_health: int = max_health

@onready var bar_sprite: Sprite2D = $Sprite2D

# Armazena a largura original da textura
var original_width: float = 0.0

func _ready() -> void:
	# Ativamos a região para poder recortar a textura
	bar_sprite.region_enabled = true

	# Garante que o 'region_rect' comece do tamanho total da textura
	# (supondo que bar_sprite.texture não seja null).
	if bar_sprite.texture:
		bar_sprite.region_rect.size = bar_sprite.texture.get_size()
		original_width = bar_sprite.texture.get_size().x
	
	# Ajuste inicial (caso queira começar em 100% de vida)
	set_current_health(max_health)

func set_current_health(value: int) -> void:
	current_health = clamp(value, 0, max_health)
	# se quiser chamar update_bar aqui, então passamos value também
	update_bar(value)

func update_bar(new_health: int) -> void:
	current_health = clamp(new_health, 0, max_health)
	if not bar_sprite.texture:
		return

	var ratio = float(current_health) / float(max_health)
	var rect = bar_sprite.region_rect
	rect.size.x = original_width * ratio
	bar_sprite.region_rect = rect
