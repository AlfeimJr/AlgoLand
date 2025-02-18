extends Node2D

var max_enemies: int = 110
var current_wave: int = 1
var wave_interval: float = 10.0  # Intervalo entre as waves

func _ready() -> void:
	pass# Inicia a primeira wave ou envia um sinal para os spawners

func start_wave() -> void:
	pass# Pode emitir um sinal ou chamar métodos em cada spawner
