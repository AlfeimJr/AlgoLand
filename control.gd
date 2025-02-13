extends CanvasLayer  # Agora o script pode ser usado no CanvasLayer

@onready var wave_label = $wave/WaveLabel
@onready var enemies_label = $enemiesCount/EnemiesLabel
@onready var countdown_label = $CountWaveInit/CountdownLabel
@onready var count_wave_init = $CountWaveInit  # 🔥 Referência ao nó inteiro

var wave_manager

func _ready():
	wave_manager = get_tree().get_root().get_node("/root/cenario/enemySpawner/WaveManager")

	# 🔥 Esconder CountWaveInit no início
	count_wave_init.visible = false  

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

	# 🔥 Esconder CountWaveInit quando a wave começar
	count_wave_init.visible = false  

func _on_wave_completed(wave: int):
	print("🟢 Wave completada! Restam", wave_manager.enemies_alive, "inimigos.")
	count_wave_init.visible = true  # 🔥 Exibir CountWaveInit quando a wave for vencida

	countdown_label.text = "Próxima wave em: " + str(int(wave_manager.wave_interval))
	start_countdown(wave_manager.wave_interval)

func start_countdown(time: float):
	for i in range(int(time), 0, -1):
		countdown_label.text = "Wave starts in: " + str(i)
		await get_tree().create_timer(1.0).timeout

	countdown_label.text = "Wave arriving!"
	count_wave_init.visible = false  # 🔥 Esconder novamente quando a wave estiver chegando
