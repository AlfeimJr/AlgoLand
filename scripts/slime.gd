extends "EnemyBase.gd"

class_name SlimeEnemy

# Referência ao jogador
@onready var player = get_node("/root/cenario/Player")

# -----------------------------
# CONFIGURAÇÕES ESPECÍFICAS DO SLIME
# -----------------------------
@export var slime_specific_property: int = 42  # Exemplo de propriedade específica do slime

# -----------------------------
# IMPLEMENTAÇÃO DE MÉTODOS ABSTRATOS
# -----------------------------
func _get_player() -> Node2D:
	return player

# -----------------------------
# COMPORTAMENTOS ESPECÍFICOS DO SLIME
# -----------------------------
func _ready() -> void:
	# Chama o _ready do EnemyBase
	super()
	
	# Configurações específicas do slime
	if animation_tree:
		animation_tree.active = true
		_set_animation("run")  # Define animação inicial específica do slime

func _physics_process(delta: float) -> void:
	# Chama o _physics_process do EnemyBase, passando o argumento delta
	super(delta)
	
	# Adiciona comportamentos específicos do slime aqui, se necessário
	pass

# Exemplo de método específico do slime
func slime_special_behavior():
	print("Executando comportamento especial do slime!")
