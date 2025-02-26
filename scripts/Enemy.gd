extends CharacterBody2D
class_name Enemy

signal enemy_died

@export var health: int = 3
@export var damage: float = 1.0

var is_dead: bool = false
@onready var player = get_node("/root/cenario/Player")

# Função global de perseguição, reutilizável para qualquer inimigo
func chase_player(min_distance: float, speed: float) -> void:
	if player == null:
		return
	var d = position.distance_to(player.position)
	if d > min_distance:
		var dir = (player.position - position).normalized()
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO

# Atualiza o movimento do inimigo usando a lógica de perseguição
func update_enemy(delta: float, min_distance: float, speed: float) -> void:
	chase_player(min_distance, speed)
	move_and_slide()

func take_damage(dmg: int, knockback_force: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	health -= dmg
	if health <= 0:
		die()
		return

func die() -> void:
	if is_dead:
		return
	is_dead = true
	emit_signal("enemy_died")
	queue_free()

func get_damage() -> int:
	return int(damage)
