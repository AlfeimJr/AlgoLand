extends Node2D

@export var float_speed: float = 30.0
@export var lifetime: float = 1.0

var initial_lifetime: float

func _ready() -> void:
	# Armazena o valor inicial de lifetime
	initial_lifetime = lifetime

func set_damage(damage_value: int):
	$Label.text = str(damage_value)

func _process(delta: float) -> void:
	# Faz o Node2D (e consequentemente o Label) subir
	position.y -= float_speed * delta

	# Diminui o tempo de vida
	lifetime -= delta
	
	# Calcula o "progresso" (0.0 a 1.0) do tempo que já passou
	var progress = 1.0 - (lifetime / initial_lifetime)

	# Faz o scale do Node2D ir de (1,1) até (0,0)
	scale = Vector2(1,1).lerp(Vector2(0,0), progress)

	# Quando acabar o lifetime, remove da cena
	if lifetime <= 0:
		queue_free()
