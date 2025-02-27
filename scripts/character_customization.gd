extends Node2D

@export var is_save: bool = false
@onready var player = $Player

# Chamado quando o nó entra na árvore de cenas pela primeira vez.
func _ready() -> void:
	print("Conectando sinal 'customization_finished'...")
	player.connect("customization_finished", Callable(self, "_on_player_customization_finished"))
	IsCustomization.is_customization = true

# Chamado a cada quadro. 'delta' é o tempo decorrido desde o quadro anterior.
func _process(delta: float) -> void:
	on_save()
	pass

func _exit_tree():
	pass

func _on_tree_exited() -> void:
	IsCustomization.is_customization = false  # Desativa quando sair

func on_save():
	if is_save:
		print("salvou")
		is_save = false

func _on_player_customization_finished(hair: int, outfit: int, nickname: String):
	print("Personalização concluída! Cabelo:", hair, "Roupa:", outfit)
	save_to_json(hair, outfit, nickname)

func save_to_json(hair: int, outfit: int, nickname: String):
	# Obter o caminho para o diretório "Documentos"
	var documents_dir = OS.get_user_data_dir()
	var file_path = documents_dir.path_join("player_config.json")
	
	# Abrir o arquivo para escrita
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("Erro ao abrir o arquivo para escrita.")
		return
	# Criar os dados a serem salvos
	var data = {
		"curr_hair": hair,
		"curr_outfit": outfit,
		"nickname": nickname
	}
	
	# Converter os dados para JSON e salvar no arquivo
	var json = JSON.new()
	var json_string = json.stringify(data)
	file.store_string(json_string)
	file.close()
	var scene = load("res://cenas/cenario.tscn")
	var instance = scene.instantiate()
	IsCustomization.is_customization = false
		# Limpa a cena atual e adiciona a nova cena à árvore
	get_tree().root.add_child(instance)
	get_tree().current_scene.queue_free()  # Remove a cena atual
	get_tree().current_scene = instance    # Define a nova cena como atual
