extends CharacterBody2D

@export_category("Variables")
@export var _move_speed: float = 64.0
@export var _friction: float = 0.3
@export var _acceleration: float = 0.3
@export var _attack_damage: int = 1
@export var _knockback_strength: float = 200.0
@export var _knockback_decay: float = 0.1

@export_category("Objects")
@export var _animation_tree: AnimationTree = null
@export var _timer: Timer = null

@onready var bodySprite = $CompositeSprites/BaseSprites/Body
@onready var hairSprite = $CompositeSprites/BaseSprites/Hair
@onready var outfit_sprite = $CompositeSprites/BaseSprites/Outfit

# Estes são os nós específicos para “espada/escudo”
@onready var swordChieldBodySprite = $CompositeSprites/SwordChieldSprites/SwordChieldBody
@onready var swordArmSprite        = $CompositeSprites/SwordChieldSprites/SwordArm
@onready var chieldSprite          = $CompositeSprites/SwordChieldSprites/Chield
@onready var swordChieldHairSprite = $CompositeSprites/SwordChieldSprites/Hair
@onready var swordChieldOutfitSprite          = $CompositeSprites/SwordChieldSprites/Outfit


@onready var composite_sprites: Composite = Composite.new()
@onready var camera: Camera2D = $Camera2D

var nickname: String = ""
signal customization_finished(hair: int, outfit: int, nickname: String)

var curr_hair: int = 0
var curr_outfit: int = 0
var _state_machine: Object
var _is_attacking: bool = false
var _knockback: Vector2 = Vector2.ZERO

# --- Variável para controlar se o player está usando espada/escudo ---
var using_sword: bool = false

func _ready() -> void:
	bodySprite.texture = composite_sprites.body_spriteSheet[0]
	hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
	outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]

	if _animation_tree == null:
		print("Erro: _animation_tree não foi atribuído corretamente!")
	else:
		_state_machine = _animation_tree["parameters/playback"]
		if _state_machine == null:
			print("Erro: _state_machine está null! Verifique o nome da propriedade 'parameters/playback'.")

	# Configura layers/mask da AttackArea
	$AttackArea.collision_layer = 1 << 1  # Layer 2
	$AttackArea.collision_mask  = 1 << 2  # Mask 4
	$AttackArea.monitoring = false
	$AttackArea.monitorable = false

	# Conecta sinais de ataque
	connect_signal_if_not_connected($AttackArea, "body_entered", "_on_attack_body_entered")
	connect_signal_if_not_connected($AttackArea, "area_entered", "_on_attack_area_area_entered")

	# Carrega dados salvos (se houver)
	var loaded_data = load_from_json()
	apply_loaded_data(loaded_data)

	# Inicia todos os sprites de espada/escudo invisíveis
	swordChieldBodySprite.visible = false
	swordArmSprite.visible = false
	chieldSprite.visible = false


func connect_signal_if_not_connected(node: Node, signal_name: String, method: String) -> void:
	if not node.is_connected(signal_name, Callable(self, method)):
		node.connect(signal_name, Callable(self, method))
		print("Sinal ", signal_name, " conectado ao método ", method)


func _physics_process(delta: float) -> void:
	if IsCustomization.is_customization:
		camera.enabled = false
		return

	# Se tiver knockback, aplica
	if _knockback.length() > 1:
		velocity = _knockback
		_knockback = _knockback.lerp(Vector2.ZERO, _knockback_decay)
	else:
		_move(delta)
		_attack()

	move_and_slide()
	_animate()


func apply_knockback(force: Vector2) -> void:
	_knockback = force
	print("Player sofreu knockback!")
	# Efeito de piscar
	for i in range(5):
		modulate.a = 0.2
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout


func _attack() -> void:
	if Input.is_action_just_pressed("attack") and not _is_attacking:
		_is_attacking = true
		_timer.start()
		$AttackArea.monitoring = true
		$AttackArea.monitorable = true


func _move(delta: float) -> void:
	var dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		velocity.x = lerp(velocity.x, dir.x * _move_speed, _acceleration)
		velocity.y = lerp(velocity.y, dir.y * _move_speed, _acceleration)

		# Dependendo se está usando espada ou não, atualizamos
		# o blend_position dos estados corretos.
		if using_sword:
			_animation_tree["parameters/SwordChieldIdle/blend_position"] = dir
			_animation_tree["parameters/SwordChieldMove/blend_position"] = dir
		else:
			_animation_tree["parameters/idle/blend_position"] = dir
			_animation_tree["parameters/run/blend_position"] = dir
	else:
		velocity.x = lerp(velocity.x, 0.0, _friction)
		velocity.y = lerp(velocity.y, 0.0, _friction)


func _animate() -> void:
	# Se estiver atacando, toca animação de ataque normal
	# (se quiser animação diferente para espada, crie "SwordChieldAttack")
	if _is_attacking:
		_state_machine.travel("attack")
		return

	# Se estiver em movimento:
	if velocity.length() > 2:
		# Se usando espada, use "SwordChieldMove"
		if using_sword:
			_state_machine.travel("SwordChieldMove")
		else:
			_state_machine.travel("run")
	else:
		# Parado: "SwordChieldIdle" ou "idle"
		if using_sword:
			_state_machine.travel("SwordChieldIdle")
		else:
			_state_machine.travel("idle")


func _on_attack_timer_timeout() -> void:
	_is_attacking = false
	$AttackArea.monitoring = false
	$AttackArea.monitorable = false


func _on_attack_area_area_entered(area: Area2D) -> void:
	print("Área de ataque entrou em contato com outra área:", area.name)


func _on_attack_body_entered(body: Node2D) -> void:
	print("Colisão detectada com: ", body.name)
	if body is Slime:
		print("O corpo é um Slime!")
		if not body.is_dead:
			print("Causando dano ao Slime...")
			var knockback_dir = (body.position - position).normalized()
			body.take_damage(_attack_damage, knockback_dir * _knockback_strength)


func _on_change_hair_pressed() -> void:
	curr_hair = (curr_hair + 1) % composite_sprites.hair_spriteSheet.size()
	hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
	print("Cabelo alterado para:", curr_hair)


func _on_change_hair_back_pressed() -> void:
	curr_hair = (curr_hair - 1) % composite_sprites.hair_spriteSheet.size()
	if curr_hair == -1:
		curr_hair = 0
	hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
	print("Cabelo alterado para:", curr_hair)


func _on_change_outfit_pressed() -> void:
	curr_outfit = (curr_outfit + 1) % composite_sprites.outfit_spriteSheet.size()
	outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
	print("Roupa alterada para:", curr_outfit)


func _on_change_outfit_back_pressed() -> void:
	curr_outfit = (curr_outfit - 1) % composite_sprites.outfit_spriteSheet.size()
	if curr_outfit == -1:
		curr_outfit = 0
	outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
	print("Roupa alterada para:", curr_outfit)


func save_customization():
	print("Emitindo sinal de personalização...")
	print("Cabelo atual:", curr_hair, "Roupa atual:", curr_outfit, "Nickname:", nickname)
	emit_signal("customization_finished", curr_hair, curr_outfit, nickname)


func load_from_json():
	var documents_dir = OS.get_user_data_dir()
	var file_path = documents_dir.path_join("player_config.json")
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Erro: Arquivo JSON não encontrado em:", file_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Erro ao analisar o JSON.")
		return {}
	
	var data = json.get_data()
	print("Dados carregados:", data)
	return data


func apply_loaded_data(data: Dictionary):
	if data.has("curr_hair"):
		curr_hair = data["curr_hair"]
		hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
		print("Cabelo carregado:", curr_hair)
	if data.has("curr_outfit"):
		curr_outfit = data["curr_outfit"]
		outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
		print("Roupa carregada:", curr_outfit)
	if data.has("nickname"):
		nickname = data["nickname"]
		print("Nickname carregado:", nickname)


# -------------------------------
# Função para equipar espada e escudo
# -------------------------------
func equip_sword_and_shield() -> void:
	using_sword = true

	# Carrega a espada e o escudo das pastas (ajuste o nome dos arquivos conforme seu projeto)
	var sword_tex = load("res://CharacterSprites/Arms/swords/Sword_1.png")
	var shield_tex = load("res://CharacterSprites/Arms/chields/chield_1.png")	

	swordArmSprite.texture = sword_tex
	chieldSprite.texture = shield_tex

	# Esconde o corpo normal
	bodySprite.visible = false
	# Mostra o corpo+braço com espada e o escudo
	swordChieldBodySprite.visible = true
	swordArmSprite.visible = true
	chieldSprite.visible = true

	# Esconde os sprites de cabelo e roupa do BaseSprites
	hairSprite.visible = false
	outfit_sprite.visible = false

	# ---------- AQUI VEM A PARTE IMPORTANTE ----------
	# curr_hair e curr_outfit são índices numéricos, ex.: 0, 1, 2...
	# Vamos montar o arquivo usando esse índice + 1, pois o arquivo se chama "hair (1).png", "hair (2).png", etc.
	var hair_file = "hair (" + str(curr_hair + 1) + ").png"
	var outfit_file = "outfit (" + str(curr_outfit + 1) + ").png"

	# Monta o caminho para a pasta "Hair_Sword_Chield"
	var hair_path = "res://CharacterSprites/Hair_Sword_Chield/" + hair_file
	#var outfit_path = "res://CharacterSprites/Hair_Sword_Chield/" + outfit_file

	# Carrega essas texturas
	var hair_texture = load(hair_path)
	#var outfit_texture = load(outfit_path)

	# Seta nos sprites
	swordChieldHairSprite.texture = hair_texture
	#outfit_sprite.texture = outfit_texture

	# Mostra de volta
	swordChieldHairSprite.visible = true
	swordChieldOutfitSprite.visible = true

	print("Espada e escudo equipados com hair:", hair_file, "e outfit:", outfit_file)

# -------------------------------
# (Opcional) Função para voltar ao Body normal
# -------------------------------
func unequip_sword_and_shield() -> void:
	using_sword = false

	bodySprite.visible = true
	swordChieldBodySprite.visible = false
	swordArmSprite.visible = false
	chieldSprite.visible = false

	# Volta os sprites de cabelo e roupa para os padrões
	hairSprite.visible = true
	outfit_sprite.visible = true

	print("Espada e escudo removidos!")
