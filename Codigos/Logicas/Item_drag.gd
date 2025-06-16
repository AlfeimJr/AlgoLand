extends Node2D

@export var tipo_item: String = "espada_basica"
@export var nivel_item: int = 1  # Nível do item (opcional)
var no_inventario: bool = false
var arrastavel = false
var esta_dentro_area_soltar = false
var ref_slot = null
var deslocamento: Vector2
var posicao_inicial: Vector2
var esta_arrastando = false
var posicao_atual_mouse = Vector2.ZERO
var ultima_posicao_mouse = Vector2.ZERO
var mouse_moveu: bool = false
var posicao_inicial_camera: Vector2
var pontos_trajetoria: Array = []
var max_pontos_trajetoria: int = 10
var algum_item_sendo_arrastado = false

func _ready() -> void:
	if is_in_group("espada_basica"):
		tipo_item = "espada_basica"
	elif is_in_group("escudo_basico"):
		tipo_item = "escudo_basico"
	elif is_in_group("lanca_basica"):
		tipo_item = "lanca_basica"
	elif is_in_group('cabeca_basica'):
		tipo_item = ("cabeca_basica")
	elif is_in_group('armadura_basica'):
		tipo_item = ("armadura_basica")
	elif is_in_group('luvas_basicas'):
		tipo_item = ("luvas_basicas")
	elif is_in_group('botas_basicas'):
		tipo_item = ("botas_basicas")
	posicao_inicial = global_position
	posicao_inicial_camera = get_viewport().get_camera_2d().global_position
	$Area2D.collision_layer = 11
	$Area2D.collision_mask = 12
	add_to_group("itens_arrastaveis")
	
	$Area2D.connect("area_entered", Callable(self, "_ao_area_2d_entrar_area"))
	$Area2D.connect("area_exited", Callable(self, "_ao_area_2d_sair_area"))
	$Area2D.connect("mouse_entered", Callable(self, "_ao_area_2d_mouse_entrar"))
	$Area2D.connect("mouse_exited", Callable(self, "_ao_area_2d_mouse_sair"))
	
	$Area2D.monitoring = true
	$Area2D.monitorable = true

func _process(delta: float) -> void:
	ultima_posicao_mouse = posicao_atual_mouse
	posicao_atual_mouse = get_global_mouse_position()
	
	if esta_arrastando:
		# Adiciona pontos para interpolar a trajetória e checar colisões
		if (posicao_atual_mouse - ultima_posicao_mouse).length() > 10:
			var direcao = (posicao_atual_mouse - ultima_posicao_mouse).normalized()
			var distancia = (posicao_atual_mouse - ultima_posicao_mouse).length()
			var passos = int(distancia / 5)
			for i in range(1, passos):
				var ponto_intermediario = ultima_posicao_mouse + direcao * (distancia * i / passos)
				pontos_trajetoria.append(ponto_intermediario)
				if pontos_trajetoria.size() > max_pontos_trajetoria:
					pontos_trajetoria.remove_at(0)
		
		if arrastavel:
			global_position = posicao_atual_mouse - deslocamento

	var jogador = get_tree().get_current_scene().get_node("Jogador")
	if arrastavel:
		if Input.is_action_just_pressed("click") and not algum_item_sendo_arrastado:
			deslocamento = get_global_mouse_position() - global_position
			pontos_trajetoria.clear()
			mouse_moveu = false
			algum_item_sendo_arrastado = true
			esta_arrastando = true
			
		elif Input.is_action_pressed("click"):
			if esta_arrastando:
				global_position = get_global_mouse_position() - deslocamento
				var posicao_atual = get_global_mouse_position()
				pontos_trajetoria.append(posicao_atual)
				if pontos_trajetoria.size() > max_pontos_trajetoria:
					pontos_trajetoria.remove_at(0)
				verificar_colisoes_caminho()
			
		elif Input.is_action_just_released("click"):
			if esta_arrastando:
				esta_arrastando = false
				algum_item_sendo_arrastado = false
				if jogador and jogador.has_method("block_attacks"):
					jogador.block_attacks(false)
					
				if esta_dentro_area_soltar and ref_slot != null:
					var tween = create_tween()
					tween.tween_property(self, "global_position", ref_slot.global_position, 0.2)
				else:
					# Se não estiver sobre um slot válido, reseta a posição
					visible = false
					resetar_posicao()
					await get_tree().create_timer(0.05).timeout
					visible = true

func verificar_colisoes_caminho() -> void:
	if pontos_trajetoria.size() < 2:
		return
	var estado_espaco = get_world_2d().direct_space_state
	for i in range(1, pontos_trajetoria.size()):
		var de = pontos_trajetoria[i-1]
		var para = pontos_trajetoria[i]
		var consulta = PhysicsRayQueryParameters2D.create(de, para)
		consulta.collide_with_areas = true
		consulta.collision_mask = 1
		var resultado = estado_espaco.intersect_ray(consulta)
		if resultado and resultado.collider.get_parent().has_method("accepts_item_type"):
			var slot = resultado.collider.get_parent()
			if slot.accepts_item_type(tipo_item):
				esta_dentro_area_soltar = true
				ref_slot = slot
				return

func _ao_area_2d_entrar_area(area: Area2D) -> void:
	var pai = area.get_parent()
	if pai.is_in_group("itens_arrastaveis"):
		return
	if pai.has_method("accepts_item_type"):
		if pai.accepts_item_type(tipo_item):
			esta_dentro_area_soltar = true
			ref_slot = pai
		else:
			esta_dentro_area_soltar = false

func _ao_area_2d_sair_area(area: Area2D) -> void:
	if ref_slot == area.get_parent():
		esta_dentro_area_soltar = false
		ref_slot = null

func _ao_area_2d_mouse_entrar() -> void:
	arrastavel = true
	scale = Vector2(1.1, 1.1)

func _ao_area_2d_mouse_sair() -> void:
	if not esta_arrastando:
		arrastavel = false
		scale = Vector2(1, 1)

func obter_tipo_item() -> String:
	return tipo_item

func obter_nivel_item() -> int:
	return nivel_item

func definir_nivel_item(novo_nivel: int) -> void:
	nivel_item = novo_nivel
	# Aqui você pode atualizar visuais ou stats do item conforme o novo nível

func resetar_posicao() -> void:
	if no_inventario and ref_slot:
		# Se estiver no inventário, reposicione no slot
		global_position = ref_slot.global_position
	else:
		var camera = get_viewport().get_camera_2d()
		var deslocamento_camera = camera.global_position - posicao_inicial_camera
		global_position = posicao_inicial + deslocamento_camera
	esta_arrastando = false
	algum_item_sendo_arrastado = false
	pontos_trajetoria.clear()
