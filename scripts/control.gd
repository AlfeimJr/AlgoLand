extends CanvasLayer  # Agora o script pode ser usado no CanvasLayer

@onready var wave_label = $wave/WaveLabel
@onready var enemies_label = $enemiesCount/EnemiesLabel


var wave_manager

func _ready():
	wave_manager = get_tree().get_root().get_node("/root/cenario/enemySpawner/WaveManager")


	if wave_manager:
		# Conectar eventos para atualizar UI
		wave_manager.connect("wave_started", Callable(self, "_on_wave_started"))
		wave_manager.connect("wave_completed", Callable(self, "_on_wave_completed"))
	else:
		print("❌ ERRO: WaveManager não encontrado!")

func _on_wave_started(wave: int):
	print("🔵 Wave start:", wave)
	wave_label.text = str(wave)
	enemies_label.text = "Enemys: " + str(wave_manager.enemies_alive)
