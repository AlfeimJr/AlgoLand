extends Node2D

@onready var barraca_aberta = $BarracaAberta
@onready var barraca_fechada = $BarraFechada
@onready var wave_manager = $"../enemySpawner/WaveManager"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"BarraFechada/1".collision_enabled = false
	if wave_manager:
		wave_manager.connect("wave_started", Callable(self, "_on_wave_started"))
		wave_manager.connect("wave_completed", Callable(self, "_on_wave_completed"))
		wave_manager.connect("waves_stopped_signal",  Callable(self, "_on_waves_stopped"))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_wave_started(_wave: int) -> void:
	barraca_aberta.visible = false
	barraca_fechada.visible = true
	$"BarraFechada/1".collision_enabled = true
	
func _on_wave_completed(_wave: int) -> void:
	barraca_aberta.visible = true
	barraca_fechada.visible = false
	$"BarraFechada/1".collision_enabled = false
	
func _on_waves_stopped() -> void:
	barraca_aberta.visible = true
	barraca_fechada.visible = false
	$"BarraFechada/1".collision_enabled = false
