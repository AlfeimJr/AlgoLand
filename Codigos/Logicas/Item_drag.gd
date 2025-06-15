extends Node2D

@export var item_type: String = "sword_basic"
@export var item_level: int = 1  # Nível do item (opcional)
var in_inventory: bool = false
var draggable = false
var is_inside_dropable = false
var slot_ref = null
var offset: Vector2
var initialPos: Vector2
var is_dragging = false
var current_mouse_pos = Vector2.ZERO
var last_mouse_pos = Vector2.ZERO
var mouse_moved: bool = false
var initialCameraPos: Vector2
var track_points: Array = []
var max_track_points: int = 10
var is_any_item_dragging = false

func _ready() -> void:
	if is_in_group("sword_basic"):
		item_type = "sword_basic"
	elif is_in_group("shield_basic"):
		item_type = "shield_basic"
	elif is_in_group("spear_basic"):
		item_type = "spear_basic"
	elif is_in_group('head_basic'):
		item_type = ("head_basic")
	elif is_in_group('armor_basic'):
		item_type = ("armor_basic")
	elif is_in_group('gloves_basic'):
		item_type = ("gloves_basic")
	elif is_in_group('boots_basic'):
		item_type = ("boots_basic")
	initialPos = global_position
	initialCameraPos = get_viewport().get_camera_2d().global_position
	$Area2D.collision_layer = 11
	$Area2D.collision_mask = 12
	add_to_group("draggable_items")
	
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
		# Adiciona pontos para interpolar a trajetória e checar colisões
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

	var player = get_tree().get_current_scene().get_node("Player")
	if draggable:
		if Input.is_action_just_pressed("click") and not is_any_item_dragging:
			offset = get_global_mouse_position() - global_position
			track_points.clear()
			mouse_moved = false
			is_any_item_dragging = true
			is_dragging = true
			
		elif Input.is_action_pressed("click"):
			if is_dragging:
				global_position = get_global_mouse_position() - offset
				var current_pos = get_global_mouse_position()
				track_points.append(current_pos)
				if track_points.size() > max_track_points:
					track_points.remove_at(0)
				check_path_collisions()
			
		elif Input.is_action_just_released("click"):
			if is_dragging:
				is_dragging = false
				is_any_item_dragging = false
				if player and player.has_method("block_attacks"):
					player.block_attacks(false)
					
				if is_inside_dropable and slot_ref != null:
					var tween = create_tween()
					tween.tween_property(self, "global_position", slot_ref.global_position, 0.2)
				else:
					# Se não estiver sobre um slot válido, reseta a posição
					visible = false
					reset_position()
					await get_tree().create_timer(0.05).timeout
					visible = true

func check_path_collisions() -> void:
	if track_points.size() < 2:
		return
	var space_state = get_world_2d().direct_space_state
	for i in range(1, track_points.size()):
		var from = track_points[i-1]
		var to = track_points[i]
		var query = PhysicsRayQueryParameters2D.create(from, to)
		query.collide_with_areas = true
		query.collision_mask = 1
		var result = space_state.intersect_ray(query)
		if result and result.collider.get_parent().has_method("accepts_item_type"):
			var slot = result.collider.get_parent()
			if slot.accepts_item_type(item_type):
				is_inside_dropable = true
				slot_ref = slot
				return

func _on_area_2d_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.is_in_group("draggable_items"):
		return
	if parent.has_method("accepts_item_type"):
		if parent.accepts_item_type(item_type):
			is_inside_dropable = true
			slot_ref = parent
		else:
			is_inside_dropable = false

func _on_area_2d_area_exited(area: Area2D) -> void:
	if slot_ref == area.get_parent():
		is_inside_dropable = false
		slot_ref = null

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

func set_item_level(new_level: int) -> void:
	item_level = new_level
	# Aqui você pode atualizar visuais ou stats do item conforme o novo nível

func reset_position() -> void:
	if in_inventory and slot_ref:
		# Se estiver no inventário, reposicione no slot
		global_position = slot_ref.global_position
	else:
		var camera = get_viewport().get_camera_2d()
		var camera_offset = camera.global_position - initialCameraPos
		global_position = initialPos + camera_offset
	is_dragging = false
	is_any_item_dragging = false
	track_points.clear()
