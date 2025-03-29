extends Node2D

@export var item_type: String = "generic_item"
@export var item_level: int = 1

# Variáveis de drag-and-drop
var draggable = false
var is_inside_dropable = false
var slot_ref = null
var offset: Vector2
var initialPos: Vector2
var is_dragging = false
var current_mouse_pos = Vector2.ZERO
var last_mouse_pos = Vector2.ZERO
var track_points: Array = []
var max_track_points: int = 10

func _ready() -> void:
	# Aqui você define o item_type no Inspector, sem sobrescrevê-lo por grupos
	initialPos = global_position
	# Configure collision para um grupo específico do inventário, por exemplo:
	$Area2D.collision_layer = 15
	$Area2D.collision_mask = 15
	add_to_group("inventory_items")
	
	# Conecta os sinais, igual ao script original
	$Area2D.connect("area_entered", Callable(self, "_on_area_2d_area_entered"))
	$Area2D.connect("area_exited", Callable(self, "_on_area_2d_area_exited"))
	$Area2D.connect("mouse_entered", Callable(self, "_on_area_2d_mouse_entered"))
	$Area2D.connect("mouse_exited", Callable(self, "_on_area_2d_mouse_exited"))
	
	$Area2D.monitoring = true
	$Area2D.monitorable = true

func _process(delta: float) -> void:
	last_mouse_pos = current_mouse_pos
	current_mouse_pos = get_global_mouse_position()
	
	if is_dragging:
		# Atualiza pontos para checar colisões, etc.
		if (current_mouse_pos - last_mouse_pos).length() > 10:
			var direction = (current_mouse_pos - last_mouse_pos).normalized()
			var distance = (current_mouse_pos - last_mouse_pos).length()
			var steps = int(distance / 5)
			for i in range(1, steps):
				var intermediate_point = last_mouse_pos + direction * (distance * i / steps)
				track_points.append(intermediate_point)
				if track_points.size() > max_track_points:
					track_points.remove_at(0)
		if draggable:
			global_position = current_mouse_pos - offset
	
	# Lógica de drag-and-drop similar ao original...
	# Quando o mouse for pressionado, arrasta o item, etc.
	# (Você pode reutilizar o restante da lógica sem muitas alterações.)

func _on_area_2d_mouse_entered() -> void:
	draggable = true
	scale = Vector2(1.1, 1.1)

func _on_area_2d_mouse_exited() -> void:
	if not is_dragging:
		draggable = false
		scale = Vector2(1, 1)

func get_item_type() -> String:
	return item_type

func get_item_level() -> int:
	return item_level

func reset_position() -> void:
	# Aqui, em vez de resetar para uma posição fixa,
	# você pode querer que o item volte para o slot de origem
	# ou para uma posição definida no layout do inventário.
	global_position = initialPos
	is_dragging = false
	track_points.clear()
