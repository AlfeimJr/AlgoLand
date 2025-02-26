extends CanvasLayer

signal menu_closed

@onready var main_menu: Control = $Container/Buttons
@onready var weapons_list: Control = $Container/Weapons
@onready var build_list: Control = $Container/ItemsContainer
@onready var items_container = $Container/ItemsContainer
@onready var items_spec = $Container/ItemSpec
var item_scene = preload("res://cenas/item.tscn")
@onready var item_spec = $Container/ItemSpec
func _ready() -> void:
	# Conecta os botões do menu principal
	if $Container/Buttons/StartWave:
		$Container/Buttons/StartWave.connect("pressed", Callable(self, "_on_start_wave_pressed"))
	else:
		print("Erro: Botão StartWave não encontrado!")
	
	if $Container/Buttons/weaponsOption:
		$Container/Buttons/weaponsOption.connect("pressed", Callable(self, "_on_weapons_pressed"))
	else:
		print("Erro: Botão weaponsOption não encontrado!")
	
	if $Container/Weapons/Sword:
		$Container/Weapons/Sword.connect("pressed", Callable(self, "_on_sword_pressed"))
	else:
		print("Erro: Botão Sword não encontrado!")
	
	if $Container/Buttons/Build:
		$Container/Buttons/Build.connect("pressed", Callable(self, "_on_build_pressed"))
	else:
		print("Erro: Botão Build não encontrado!")
	
	
	

# ====== Funções de callback ======

func _on_start_wave_pressed() -> void:
	var wave_manager = get_parent().get_node("/root/cenario/enemySpawner/WaveManager")
	if wave_manager:
		wave_manager.start_wave()
		print("Início da próxima wave solicitado!")
	else:
		print("WaveManager não encontrado na cena!")
	on_close_button_pressed()

func on_close_button_pressed() -> void:
	emit_signal("menu_closed")
	queue_free()  

func _on_weapons_pressed() -> void:
	main_menu.visible = false
	weapons_list.visible = true

func _on_sword_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("Player")
	if player:
		player.equip_sword_and_shield()
		print("Espada equipada no Player!")
	else:
		print("Player não encontrado na cena atual!")

func _on_build_pressed() -> void:
	main_menu.visible = false
	weapons_list.visible = false
	build_list.visible = true
	items_container.visible = true
	items_spec.visible = true
	
	for key in ItemDatabase.items.keys():
		var item_data = ItemDatabase.get_item_data(key)
		if item_data.size() > 0:
			print(item_data)
			var item_instance = item_scene.instantiate()
			item_instance.set_item_data(item_data)
			item_instance.connect("item_clicked", Callable(self, "_on_item_clicked"))
			items_container.add_child(item_instance)

func _on_item_clicked(clicked_item_data: Dictionary) -> void:
	# Quando um item é clicado, chamamos um método do ItemSpec para atualizar os dados
	item_spec.set_item_data(clicked_item_data)

func _on_back_button_pressed() -> void:
	main_menu.visible = true
	weapons_list.visible = false
	build_list.visible = false
	items_container.visible = false
	items_spec.visible = false
