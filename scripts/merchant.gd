extends CharacterBody2D

@onready var icon: Sprite2D = $button  # Ícone que aparece quando o jogador está próximo
var player_in_range: bool = false     # Controla se o jogador está na área de detecção
var menu_instance: CanvasLayer = null # Referência ao menu aberto

# Sinal para iniciar uma nova wave
signal start_wave_requested

func _ready() -> void:
	# Adiciona o merchant ao grupo "merchant" (opcional, para organização)
	add_to_group("merchant")
	icon.visible = false

	# Obtém o nó Area2D
	var area_2d = $Area2D
	if area_2d:
		# Conecta o sinal 'body_entered' apenas se ainda não estiver conectado
		if not area_2d.is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
			area_2d.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))

		# Conecta o sinal 'body_exited' apenas se ainda não estiver conectado
		if not area_2d.is_connected("body_exited", Callable(self, "_on_area_2d_body_exited")):
			area_2d.connect("body_exited", Callable(self, "_on_area_2d_body_exited"))

func _process(delta: float) -> void:
	# Verifica se o jogador está no alcance e pressiona o botão F para abrir o menu
	if player_in_range and Input.is_action_just_pressed("open_menu"):
		_on_open_menu_pressed()

	# Verifica se o menu está aberto e se a tecla Esc foi pressionada
	if menu_instance != null and Input.is_action_just_pressed("close_menu"):
		close_menu()

func _on_area_2d_body_entered(body: Node2D) -> void:
	# Verifica se o corpo que entrou é o jogador
	if body.is_in_group("character"):
		player_in_range = true
		icon.visible = true  # Mostra o ícone


func _on_area_2d_body_exited(body: Node2D) -> void:
	# Verifica se o corpo que saiu é o jogador
	if body.is_in_group("character"):
		player_in_range = false
		icon.visible = false  # Oculta o ícone


func _on_open_menu_pressed() -> void:
	# Carrega a cena do menu
	var menu_scene = preload("res://cenas/menu_merchant.tscn")  # Substitua pelo caminho correto da sua cena de menu
	menu_instance = menu_scene.instantiate()  # Usa 'instantiate()' em vez de 'instance()'
	add_child(menu_instance)  # Adiciona o menu como filho da cena atual

	# Conecta o sinal de fechamento do menu (opcional)
	if menu_instance.has_method("connect_menu_closed"):
		menu_instance.connect_menu_closed(Callable(self, "close_menu"))

	# Conecta o sinal de início de wave
	if menu_instance.has_method("connect_start_wave"):
		menu_instance.connect_start_wave(Callable(self, "_on_start_wave_selected"))


func close_menu() -> void:
	# Remove o menu da cena
	if menu_instance != null:
		menu_instance.queue_free()  # Libera o nó do menu
		menu_instance = null

func _on_start_wave_selected() -> void:
	# Emite o sinal para iniciar uma nova wave
	emit_signal("start_wave_requested")
