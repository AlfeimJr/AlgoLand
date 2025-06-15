extends Node2D

@export var tipo_item: String = "item_generico"
@export var nivel_item: int = 1

# Variáveis de arrastar-e-soltar
var arrastavel = false
var esta_dentro_soltavel = false
var referencia_slot = null
var deslocamento: Vector2
var posicao_inicial: Vector2
var esta_arrastando = false
var posicao_mouse_atual = Vector2.ZERO
var posicao_mouse_anterior = Vector2.ZERO
var pontos_rastro: Array = []
var max_pontos_rastro: int = 10

func _ready() -> void:
	# Aqui você define o tipo_item no Inspector, sem sobrescrevê-lo por grupos
	posicao_inicial = global_position
	# Configure collision para um grupo específico do inventário, por exemplo:
	$Area2D.collision_layer = 15
	$Area2D.collision_mask = 15
	add_to_group("itens_inventario")
	
	# Conecta os sinais mantendo os nomes originais das funções callback
	$Area2D.connect("area_entered", Callable(self, "_on_area_2d_area_entered"))
	$Area2D.connect("area_exited", Callable(self, "_on_area_2d_area_exited"))
	$Area2D.connect("mouse_entered", Callable(self, "_on_area_2d_mouse_entered"))
	$Area2D.connect("mouse_exited", Callable(self, "_on_area_2d_mouse_exited"))
	
	$Area2D.monitoring = true
	$Area2D.monitorable = true

func _process(delta: float) -> void:
	posicao_mouse_anterior = posicao_mouse_atual
	posicao_mouse_atual = get_global_mouse_position()
	
	if esta_arrastando:
		# Atualiza pontos para checar colisões, etc.
		if (posicao_mouse_atual - posicao_mouse_anterior).length() > 10:
			var direcao = (posicao_mouse_atual - posicao_mouse_anterior).normalized()
			var distancia = (posicao_mouse_atual - posicao_mouse_anterior).length()
			var passos = int(distancia / 5)
			for i in range(1, passos):
				var ponto_intermediario = posicao_mouse_anterior + direcao * (distancia * i / passos)
				pontos_rastro.append(ponto_intermediario)
				if pontos_rastro.size() > max_pontos_rastro:
					pontos_rastro.remove_at(0)
		if arrastavel:
			global_position = posicao_mouse_atual - deslocamento

# FUNÇÕES DE CALLBACK DOS SINAIS - MANTÊM NOMES ORIGINAIS
func _on_area_2d_area_entered(area):
	# Lógica quando outra área entra
	pass

func _on_area_2d_area_exited(area):
	# Lógica quando outra área sai
	pass

func _on_area_2d_mouse_entered() -> void:
	arrastavel = true
	scale = Vector2(1.1, 1.1)

func _on_area_2d_mouse_exited() -> void:
	if not esta_arrastando:
		arrastavel = false
		scale = Vector2(1, 1)

# FUNÇÕES CUSTOMIZADAS - PODEM SER TRADUZIDAS
func obter_tipo_item() -> String:
	return tipo_item

func obter_nivel_item() -> int:
	return nivel_item

func resetar_posicao() -> void:
	global_position = posicao_inicial
	esta_arrastando = false
	pontos_rastro.clear()
