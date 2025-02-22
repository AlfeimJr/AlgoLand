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

# Componentes visuais do Player
@onready var bodySprite = $CompositeSprites/BaseSprites/Body
@onready var hairSprite = $CompositeSprites/BaseSprites/Hair
@onready var outfit_sprite = $CompositeSprites/BaseSprites/Outfit
@onready var sword_sprite = $CompositeSprites/BaseSprites/Arm
@onready var shield_sprite = $CompositeSprites/BaseSprites/Child

@onready var attackSwordChieldBody = $CompositeSprites/AttackSwordAnimation/SwordChieldBody
@onready var attackSwordArm        = $CompositeSprites/AttackSwordAnimation/SwordArm
@onready var attackChield          = $CompositeSprites/AttackSwordAnimation/Chield
@onready var attackHair            = $CompositeSprites/AttackSwordAnimation/Hair
@onready var attackOutfit          = $CompositeSprites/AttackSwordAnimation/Outfit

@onready var composite_sprites: Composite = Composite.new()
@onready var camera: Camera2D = $Camera2D

var nickname: String = ""
signal customization_finished(hair: int, outfit: int, nickname: String)

var curr_hair: int = 0
var curr_outfit: int = 0
var _state_machine: Object
var _is_attacking: bool = false
var _knockback: Vector2 = Vector2.ZERO
var using_sword: bool = false

var hair_attack_array: Array[Texture2D] = []
var outfit_attack_array: Array[Texture2D] = []

var _attack_direction: Vector2 = Vector2(0, 1)

# Variáveis de HP
@export var max_hp: int = 3
var current_hp: int = max_hp

# Variáveis para invulnerabilidade (cooldown de dano)
var invulnerable: bool = false
var invul_time: float = 1.0   # tempo de invulnerabilidade em segundos
var invul_timer: float = 0.0

# Referências para a UI da barra de vida
# Certifique-se de que estes nós estão dentro de um CanvasLayer/Control com âncoras configuradas para o canto.
@onready var hp_bar_full = $"/root/cenario/UI/HealthbarFull"
@onready var hp_bar_empty = $"/root/cenario/UI/HealthbarEmpty"

func _ready() -> void:
	if _timer:
		_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))
		
	bodySprite.texture    = composite_sprites.body_spriteSheet[0]
	hairSprite.texture    = composite_sprites.hair_spriteSheet[curr_hair]
	outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]

	attackSwordChieldBody.texture = load("res://CharacterSprites/Body_sword_chield/body_attack_sword.png")
	for i in range(1, 28):
		var path = "res://CharacterSprites/Hair/Attack/slash_1_sword/hair (" + str(i) + ").png"
		var resource = load(path)
		if resource:
			hair_attack_array.append(resource)
		else:
			print("Não foi possível carregar:", path)
	for i in range(1, 8):
		var path = "res://CharacterSprites/Outfit/Attack/slash_1_sword/outfit(" + str(i) + ").png"
		var resource = load(path)
		if resource:
			outfit_attack_array.append(resource)
		else:
			print("Não foi possível carregar:", path)
	if hair_attack_array.size() > 0:
		attackHair.texture = hair_attack_array[curr_hair]
	if outfit_attack_array.size() > 0:
		attackOutfit.texture = outfit_attack_array[curr_outfit]

	if _animation_tree == null:
		print("Erro: _animation_tree não foi atribuído corretamente!")
	else:
		_state_machine = _animation_tree["parameters/playback"]
		if _state_machine == null:
			print("Erro: _state_machine está null!")

	$AttackArea.collision_layer = 1 << 1
	$AttackArea.collision_mask  = 1 << 2
	$AttackArea.monitoring = false
	$AttackArea.monitorable = false
	connect_signal_if_not_connected($AttackArea, "body_entered", "_on_attack_body_entered")
	connect_signal_if_not_connected($AttackArea, "area_entered", "_on_attack_area_area_entered")

	var loaded_data = load_from_json()
	apply_loaded_data(loaded_data)

	_set_sprites_visible(false)

func connect_signal_if_not_connected(node: Node, signal_name: String, method: String) -> void:
	if not node.is_connected(signal_name, Callable(self, method)):
		node.connect(signal_name, Callable(self, method))
		print("Sinal ", signal_name, " conectado ao método ", method)

func _set_sprites_visible(is_attacking: bool) -> void:
	bodySprite.visible    = not is_attacking
	hairSprite.visible    = not is_attacking
	outfit_sprite.visible = not is_attacking
	sword_sprite.visible  = not is_attacking
	shield_sprite.visible = not is_attacking

	attackSwordChieldBody.visible = is_attacking
	attackSwordArm.visible        = is_attacking
	attackChield.visible          = is_attacking
	attackHair.visible            = is_attacking
	attackOutfit.visible          = is_attacking

func _physics_process(delta: float) -> void:
	# Exemplo de debug: pressione "debug_damage" para sofrer 1 de dano
	if Input.is_action_just_pressed("debug_damage"):
		take_damage(1)
	
	# Atualiza a invulnerabilidade, se estiver ativa
	if invulnerable:
		invul_timer -= delta
		if invul_timer <= 0:
			invulnerable = false

	if _knockback.length() > 1:
		velocity = _knockback
		_knockback = _knockback.lerp(Vector2.ZERO, _knockback_decay)
	else:
		_move(delta)
		_attack()

	# Executa o movimento e animação
	move_and_slide()
	_animate()

	# Verifica colisões geradas no frame e aplica dano (com knockback) se colidiu com um inimigo (do grupo "enemy")
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("enemy") and not invulnerable:
			print("Player colidiu com o inimigo: ", collider.name)
			# Calcula a direção do knockback: do inimigo para o player
			var knockback_dir = (position - collider.position).normalized()
			# Aplica dano e knockback (multiplicador de 300.0, ajuste conforme necessário)
			take_damage(1, knockback_dir * 300.0)
			invulnerable = true
			invul_timer = invul_time

func apply_knockback(force: Vector2) -> void:
	_knockback = force
	print("Player sofreu knockback!")
	for i in range(5):
		modulate.a = 0.2
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout

func _move(delta: float) -> void:
	var dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		velocity.x = lerp(velocity.x, dir.x * _move_speed, _acceleration)
		velocity.y = lerp(velocity.y, dir.y * _move_speed, _acceleration)

		_attack_direction = dir
		if using_sword:
			_animation_tree["parameters/idle/blend_position"]    = dir
			_animation_tree["parameters/running/blend_position"] = dir
		else:
			_animation_tree["parameters/idle/blend_position"] = dir
			_animation_tree["parameters/run/blend_position"]  = dir
	else:
		velocity.x = lerp(velocity.x, 0.0, _friction)
		velocity.y = lerp(velocity.y, 0.0, _friction)

func _attack() -> void:
	if not using_sword:
		return
	if Input.is_action_just_pressed("attack") and not _is_attacking:
		_is_attacking = true
		_timer.start()
		$AttackArea.monitoring = true
		$AttackArea.monitorable = true
		_set_sprites_visible(true)
		_animation_tree["parameters/AttackSwordSlash_1/blend_position"] = _attack_direction

func _animate() -> void:
	if _is_attacking:
		_animation_tree["parameters/AttackSwordSlash_1/blend_position"] = _attack_direction
		_state_machine.travel("AttackSwordSlash_1")
		return

	if velocity.length() > 2:
		if using_sword:
			_state_machine.travel("running")
		else:
			_state_machine.travel("run")
	else:
		_state_machine.travel("idle")

func _on_attack_timer_timeout() -> void:
	print("Timer acabou, voltando para animações base!")
	_is_attacking = false
	$AttackArea.monitoring = false
	$AttackArea.monitorable = false
	_set_sprites_visible(false)

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
	if curr_hair < hair_attack_array.size():
		attackHair.texture = hair_attack_array[curr_hair]
	print("Cabelo alterado para:", curr_hair)

func _on_change_hair_back_pressed() -> void:
	curr_hair = (curr_hair - 1) % composite_sprites.hair_spriteSheet.size()
	if curr_hair < 0:
		curr_hair = composite_sprites.hair_spriteSheet.size() - 1
	hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
	if curr_hair < hair_attack_array.size():
		attackHair.texture = hair_attack_array[curr_hair]
	print("Cabelo alterado para:", curr_hair)

func _on_change_outfit_pressed() -> void:
	curr_outfit = (curr_outfit + 1) % composite_sprites.outfit_spriteSheet.size()
	outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
	if curr_outfit < outfit_attack_array.size():
		attackOutfit.texture = outfit_attack_array[curr_outfit]
	print("Roupa alterada para:", curr_outfit)

func _on_change_outfit_back_pressed() -> void:
	curr_outfit = (curr_outfit - 1) % composite_sprites.outfit_spriteSheet.size()
	if curr_outfit < 0:
		curr_outfit = composite_sprites.outfit_spriteSheet.size() - 1
	outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
	if curr_outfit < outfit_attack_array.size():
		attackOutfit.texture = outfit_attack_array[curr_outfit]
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
		if curr_hair < hair_attack_array.size():
			attackHair.texture = hair_attack_array[curr_hair]
		print("Cabelo carregado:", curr_hair)

	if data.has("curr_outfit"):
		curr_outfit = data["curr_outfit"]
		outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
		if curr_outfit < outfit_attack_array.size():
			attackOutfit.texture = outfit_attack_array[curr_outfit]
		print("Roupa carregada:", curr_outfit)

	if data.has("nickname"):
		nickname = data["nickname"]
		print("Nickname carregado:", nickname)

func equip_sword_and_shield() -> void:
	if using_sword:
		unequip_sword_and_shield()
		return

	using_sword = true
	sword_sprite.texture  = load("res://CharacterSprites/Arms/swords/Sword_1.png")
	shield_sprite.texture = load("res://CharacterSprites/Arms/chields/chield_1.png")

	attackSwordArm.texture = load("res://CharacterSprites/Arms/swords/Attack/slash_1.png")
	attackChield.texture   = load("res://CharacterSprites/Arms/chields/attack/slash_1.png")

	sword_sprite.visible  = true
	shield_sprite.visible = true
	_move_speed += 50
	print("Espada e escudo equipados!")

func unequip_sword_and_shield() -> void:
	using_sword = false
	sword_sprite.visible  = false
	shield_sprite.visible = false
	_move_speed -= 50
	print("Espada e escudo removidos!")

func take_damage(damage: int, knockback_force: Vector2 = Vector2.ZERO) -> void:
	current_hp = max(current_hp - damage, 0)
	update_hp_bar()
	
	# Aplica o knockback no Player, se especificado
	if knockback_force != Vector2.ZERO:
		apply_knockback(knockback_force)

	if current_hp <= 0:
		die()

func update_hp_bar() -> void:
	var fraction = float(current_hp) / float(max_hp)
	hp_bar_full.scale.x = fraction

func die() -> void:
	print("Player morreu!")
	# Coloque aqui lógica de morte, respawn ou Game Over
