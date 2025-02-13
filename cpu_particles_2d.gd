extends Node2D  # Mantém o Node2D como base

func _ready():
	# Criar um nó de partículas
	var snow_particles = CPUParticles2D.new()
	add_child(snow_particles)  # Adicionar ao nó principal

	# Configurar as partículas
	snow_particles.emitting = true
	snow_particles.amount = 500  # Número de partículas (flocos de neve)
	snow_particles.lifetime = 5.0  # Tempo de vida dos flocos
	snow_particles.one_shot = false  # Neve contínua
	snow_particles.speed_scale = 0.5  # Velocidade mais lenta
	snow_particles.position = Vector2(0, -100)  # Posição inicial das partículas

	# **Espalhar os flocos na tela**
	snow_particles.emission_rect_extents = Vector2(300, 50)  # Área de emissão mais larga
	snow_particles.gravity = Vector2(0, 10)  # Faz os flocos caírem mais devagar

	# Configuração do movimento dos flocos
	snow_particles.direction = Vector2(0, 1)  # Direção para baixo
	snow_particles.spread = 180  # Faz os flocos irem para várias direções
	snow_particles.initial_velocity_min = 5
	snow_particles.initial_velocity_max = 15
