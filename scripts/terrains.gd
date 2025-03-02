extends Node2D

@onready var barraca_aberta = $BarracaAberta
@onready var barraca_fechada = $BarraFechada
@onready var wave_manager = $"../enemySpawner/WaveManager"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if wave_manager:
		wave_manager.connect("wave_started", Callable(self, "_on_wave_started"))
		wave_manager.connect("wave_completed", Callable(self, "_on_wave_completed"))
		wave_manager.connect("waves_stopped_signal",  Callable(self, "_on_waves_stopped"))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_wave_started(wave: int) -> void:
	barraca_aberta.visible = false
	barraca_fechada.visible = true
	
func _on_wave_completed(wave: int) -> void:
	print("Wave completada: ", wave)
	# Aqui você pode adicionar a lógica para tratar o término de uma wave,
	# como atualizar a interface ou preparar a próxima wave.

func _on_waves_stopped() -> void:
	barraca_aberta.visible = true
	barraca_fechada.visible = false
