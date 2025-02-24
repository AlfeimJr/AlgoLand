extends Node
class_name ChaseLogic

# Parâmetros configuráveis
@export var min_distance: float = 10.0
@export var charge_distance: float = 40.0
@export var speed: int = 30

# Referência ao player
var player: Node2D = null

# Sinais para acionar eventos no inimigo
signal do_charge_attack
signal update_direction(new_direction: Vector2)

# Inicializa com o nó do player
func initialize(_player: Node2D) -> void:
	player = _player

# Função que calcula a direção/velocidade de perseguição com base na posição atual do inimigo
func chase(current_position: Vector2, can_attack: bool, is_damaged: bool) -> Vector2:
	if player == null:
		return Vector2.ZERO

	var distance_to_player = current_position.distance_to(player.position)
	var dir = Vector2.ZERO
	
	# Calcula a direção se estiver longe o suficiente
	if distance_to_player > min_distance:
		dir = (player.position - current_position).normalized()
		emit_signal("update_direction", dir)
	else:
		dir = Vector2.ZERO

	# Se estiver próximo e puder atacar, dispara o sinal para charge attack
	if distance_to_player < charge_distance and can_attack and not is_damaged:
		emit_signal("do_charge_attack")
		return Vector2.ZERO

	return dir * speed
