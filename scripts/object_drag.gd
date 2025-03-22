extends Node2D

var draggable = false
var is_inside_dropable = false
var body_ref
var offset: Vector2
var initialPos : Vector2
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if draggable:
		if Input.is_action_just_pressed("click"):
			initialPos = global_position
			offset = get_global_mouse_position() - global_position
			Global.is_dragging = true
		if Input.is_action_pressed("click"):
			global_position = get_global_mouse_position() - offset
		elif Input.is_action_just_released("click"):
			Global.is_dragging = false
			var tween = get_tree().create_tween()
			if is_inside_dropable:
				tween.tween_property(self, "global_position", body_ref.global_position, 0.2).set_ease(Tween.EASE_OUT)
			else:
				tween.tween_property(self, "global_position", initialPos, 0.2).set_ease(Tween.EASE_OUT)



func _on_area_2d_mouse_entered() -> void:
	if not Global.is_dragging:
		draggable = true
		scale = Vector2(1.05, 1.05)


func _on_area_2d_mouse_exited() -> void:
	if not Global.is_dragging:
		draggable = false
		scale = Vector2(1, 1)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("dropable"):
		# (Aqui é o "drop area" que entrou?)
		# Normalmente, se for o "slot" entrando no "item", ou vice-versa, 
		# depende de quem tem o sinal. Vamos supor que quem detecta seja o ITEM.
		#
		# Se este script está no ITEM, então `body` é o SLOT.
		# Então para sabermos se o SLOT e o ITEM são compatíveis, faça:
		if self.is_in_group("sword") and body.is_in_group("sword_slot"):
			is_inside_dropable = true
			body.modulate = Color(Color.REBECCA_PURPLE, 1)
			body_ref = body
		elif self.is_in_group("shield") and body.is_in_group("shield_slot"):
			is_inside_dropable = true
			body.modulate = Color(Color.REBECCA_PURPLE, 1)
			body_ref = body
		else:
			# Significa que o SLOT não é compatível
			is_inside_dropable = false

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group('dropable'):
		is_inside_dropable = false
		body.modulate = Color(Color.MEDIUM_PURPLE, .7)
