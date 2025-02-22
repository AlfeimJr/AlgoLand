extends CanvasLayer

signal menu_closed      # Sinal emitido quando o menu é fechado

@onready var main_menu: Control = $Container/Buttons
@onready var weapons_list: Control = $Container/Weapons
@onready var buildList: Control  = $Build
func _ready() -> void:
	# Conecta os botões do menu principal
	if $Container/Buttons/StartWave:
		$Container/Buttons/StartWave.connect("pressed", Callable(self, "_on_start_wave_pressed"))
	else:
		print("Erro: Botão StartWave não encontrado!")
		
	if $Container/Buttons/weaponsOption:
		$Container/Buttons/weaponsOption.connect("pressed", Callable(self, "_on_weapons_pressed"))
	else:
		print("Erro: Botão WeaponsButton não encontrado!")
	
	if $Container/Weapons/Sword:
		$Container/Weapons/Sword.connect("pressed", Callable(self, "_on_sword_pressed"))
	else:
		print("Erro: Botão SwordButton não encontrado!")
		
	if $Container/Buttons/Build:
		$Container/Buttons/Build.connect("pressed", Callable(self, "_on_build_pressed()"))
	else:
		print("Erro: Botão SwordButton não encontrado!")

func _on_start_wave_pressed() -> void:
	# Em vez de emitir um sinal, encontra o WaveManager e chama start_wave diretamente.
	var wave_manager = get_parent().get_node("/root/cenario/enemySpawner/WaveManager")
	if wave_manager:
		wave_manager.start_wave()
		print("Início da próxima wave solicitado!")
	else:
		print("WaveManager não encontrado na cena!")
	on_close_button_pressed()  # Fecha o menu

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
	else:
		print("Player não encontrado na cena atual!")


func _on_build_pressed() -> void:
	main_menu.visible = false
	weapons_list.visible = false
	buildList.visible = true
	
func _on_back_button_pressed() -> void:
	main_menu.visible = true
	weapons_list.visible = false
	buildList.visible = false
