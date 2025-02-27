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

# Sprites padrão do personagem
@onready var bodySprite   = $CompositeSprites/BaseSprites/Body
@onready var hairSprite   = $CompositeSprites/BaseSprites/Hair
@onready var outfit_sprite = $CompositeSprites/BaseSprites/Outfit
@onready var sword_sprite  = $CompositeSprites/BaseSprites/Arm
@onready var shield_sprite = $CompositeSprites/BaseSprites/Child

# Sprites que aparecem durante a animação de ataque (visível quando atacando)
@onready var attackSwordChieldBody = $CompositeSprites/AttackSwordAnimation/SwordChieldBody
@onready var attackSwordArm        = $CompositeSprites/AttackSwordAnimation/SwordArm
@onready var attackChield          = $CompositeSprites/AttackSwordAnimation/Chield
@onready var attackHair            = $CompositeSprites/AttackSwordAnimation/Hair
@onready var attackOutfit          = $CompositeSprites/AttackSwordAnimation/Outfit

@onready var composite_sprites: Composite = Composite.new()
@onready var camera: Camera2D = $Camera2D

# Label de HP
@onready var hp_label = $"/root/cenario/UI/Hp"

# Label de moedas
@onready var coins_label: Label = $"/root/cenario/UI/Coins/count"

# Iniciando com 1000 moedas
var coins: int = 1000

signal customization_finished(hair: int, outfit: int, nickname: String)
signal player_died

@export var isDead = false

@onready var wave_manager = get_node("/root/cenario/enemySpawner/WaveManager")

var nickname: String = ""
var damaged_enemies: Array[Node] = []

var curr_hair: int = 0
var curr_outfit: int = 0
var _state_machine: Object
var _is_attacking: bool = false
var _knockback: Vector2 = Vector2.ZERO
var using_sword: bool = false

var hair_attack_array: Array[Texture2D] = []
var outfit_attack_array: Array[Texture2D] = []

var _attack_direction: Vector2 = Vector2.DOWN

# Vida do Player
@export var max_hp: int = 10
var current_hp: int = max_hp

# Invulnerabilidade após tomar dano
var invulnerable: bool = false
var invul_time: float = 0.5
var invul_timer: float = 0.0

# Barra de vida
@onready var hp_bar_full  = $"/root/cenario/UI/HealthbarFull"
@onready var hp_bar_empty = $"/root/cenario/UI/HealthbarEmpty"

func _ready() -> void:
	if _timer:
		_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))

	# Define algumas texturas iniciais
	bodySprite.texture    = composite_sprites.body_spriteSheet[0]
	hairSprite.texture    = composite_sprites.hair_spriteSheet[curr_hair]
	outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]

	attackSwordChieldBody.texture = load("res://CharacterSprites/Body_sword_chield/body_attack_sword.png")

	# Carrega as texturas de cabelo para a animação de ataque
	for i in range(1, 28):
		var path = "res://CharacterSprites/Hair/Attack/slash_1_sword/hair (" + str(i) + ").png"
		var resource = load(path)
		if resource:
			hair_attack_array.append(resource)
		else:
			return

	# Carrega as texturas de outfit para a animação de ataque
	for i in range(1, 8):
		var outfit_path = "res://CharacterSprites/Outfit/Attack/slash_1_sword/outfit(" + str(i) + ").png"
		var outfit_resource = load(outfit_path)
		if outfit_resource:
			outfit_attack_array.append(outfit_resource)
		else:
			return

	# Se já existirem arrays de ataque, faz o sprite de ataque refletir o cabelo/outfit atuais
	if hair_attack_array.size() > 0:
		attackHair.texture = hair_attack_array[curr_hair]
	if outfit_attack_array.size() > 0:
		attackOutfit.texture = outfit_attack_array[curr_outfit]

	if _animation_tree:
		_state_machine = _animation_tree.get("parameters/playback")

	# Configura o Area2D de ataque
	$AttackArea.collision_layer = 1 << 1
	$AttackArea.collision_mask  = 1 << 2
	$AttackArea.monitoring = false
	$AttackArea.monitorable = false
	connect_signal_if_not_connected($AttackArea, "body_entered", "_on_attack_body_entered")
	connect_signal_if_not_connected($AttackArea, "area_entered", "_on_attack_area_entered")

	# Carrega informações salvas em JSON
	var loaded_data = load_from_json()
	apply_loaded_data(loaded_data)

	# Quando não estiver atacando, esconder sprites de ataque
	_set_sprites_visible(false)
	
	# Atualiza o label de moedas e HP na tela
	update_coins_label()
	update_hp_bar()

func connect_signal_if_not_connected(node: Node, signal_name: String, method: String) -> void:
	if not node.is_connected(signal_name, Callable(self, method)):
		node.connect(signal_name, Callable(self, method))

func _physics_process(delta: float) -> void:
	# Exemplo: debug para sofrer dano
	if Input.is_action_just_pressed("debug_damage"):
		take_damage(1)

	# Contagem regressiva da invulnerabilidade
	if invulnerable:
		invul_timer -= delta
		if invul_timer <= 0:
			invulnerable = false

	# Se tiver knockback, ignora input e decai o knockback
	if _knockback.length() > 1:
		velocity = _knockback
		_knockback = _knockback.lerp(Vector2.ZERO, _knockback_decay)
	else:
		_move(delta)
		_attack()

	move_and_slide()
	_animate()

	# Checa colisões com inimigos (caso não use AttackArea, ou se o inimigo encosta em você)
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("enemy") and not invulnerable:
			var knockback_dir = (position - collider.position).normalized()
			var enemy_damage = 1
			if collider.has_method("get_damage"):
				enemy_damage = collider.get_damage()
			take_damage(enemy_damage, knockback_dir * 300.0)
			invulnerable = true
			invul_timer = invul_time
			break

func _move(delta: float) -> void:
	if _is_attacking:
		velocity.x = lerp(velocity.x, 0.0, _friction)
		velocity.y = lerp(velocity.y, 0.0, _friction)
		return

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
			_animation_tree.set("parameters/idle/blend_position", dir)
			_animation_tree.set("parameters/running/blend_position", dir)
		else:
			_animation_tree.set("parameters/idle/blend_position", dir)
			_animation_tree.set("parameters/run/blend_position", dir)
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
		_set_sprites_visible(true)  # Mostra sprites de ataque
		_animation_tree.set("parameters/AttackSwordSlash_1/blend_position", _attack_direction)

func _animate() -> void:
	if _is_attacking:
		_animation_tree.set("parameters/AttackSwordSlash_1/blend_position", _attack_direction)
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
	_is_attacking = false
	$AttackArea.monitoring = false
	$AttackArea.monitorable = false
	_set_sprites_visible(false)

func _on_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		var knockback_dir = (body.position - position).normalized()
		if body.has_method("take_damage"):
			body.take_damage(_attack_damage, knockback_dir * 150.0)

func _on_attack_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		var knockback_dir = (area.global_position - position).normalized()
		if area.has_method("take_damage"):
			area.take_damage(_attack_damage, knockback_dir * 150.0)

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

# Botões de customização (exemplo)
func _on_change_hair_pressed() -> void:
	curr_hair = (curr_hair + 1) % composite_sprites.hair_spriteSheet.size()
	hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
	if curr_hair < hair_attack_array.size():
		attackHair.texture = hair_attack_array[curr_hair]

func _on_change_hair_back_pressed() -> void:
	curr_hair = (curr_hair - 1) % composite_sprites.hair_spriteSheet.size()
	if curr_hair < 0:
		curr_hair = composite_sprites.hair_spriteSheet.size() - 1
	hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
	if curr_hair < hair_attack_array.size():
		attackHair.texture = hair_attack_array[curr_hair]

func _on_change_outfit_pressed() -> void:
	curr_outfit = (curr_outfit + 1) % composite_sprites.outfit_spriteSheet.size()
	outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
	if curr_outfit < outfit_attack_array.size():
		attackOutfit.texture = outfit_attack_array[curr_outfit]

func _on_change_outfit_back_pressed() -> void:
	curr_outfit = (curr_outfit - 1) % composite_sprites.outfit_spriteSheet.size()
	if curr_outfit < 0:
		curr_outfit = composite_sprites.outfit_spriteSheet.size() - 1
	outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
	if curr_outfit < outfit_attack_array.size():
		attackOutfit.texture = outfit_attack_array[curr_outfit]

func save_customization():
	emit_signal("customization_finished", curr_hair, curr_outfit, nickname)

# Carrega JSON do disco
func load_from_json() -> Dictionary:
	var documents_dir = OS.get_user_data_dir()
	var file_path = documents_dir.path_join("player_config.json")
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_error = json.parse(json_string)
	if parse_error != OK:
		return {}

	return json.get_data()

func apply_loaded_data(data: Dictionary):
	if data.has("curr_hair"):
		curr_hair = data["curr_hair"]
		hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
		if curr_hair < hair_attack_array.size():
			attackHair.texture = hair_attack_array[curr_hair]

	if data.has("curr_outfit"):
		curr_outfit = data["curr_outfit"]
		outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
		if curr_outfit < outfit_attack_array.size():
			attackOutfit.texture = outfit_attack_array[curr_outfit]

	if data.has("nickname"):
		nickname = data["nickname"]

# Métodos de equipar e desequipar espada/escudo
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

func unequip_sword_and_shield() -> void:
	using_sword = false
	sword_sprite.visible  = false
	shield_sprite.visible = false
	_move_speed -= 50

# Sofrer dano
func take_damage(damage: int, knockback_force: Vector2 = Vector2.ZERO) -> void:
	current_hp = max(current_hp - damage, 0)
	update_hp_bar()

	if knockback_force != Vector2.ZERO:
		apply_knockback(knockback_force)

	if current_hp <= 0:
		die()

func update_hp_bar() -> void:
	var fraction = float(current_hp) / float(max_hp)
	hp_bar_full.scale.x = fraction
	hp_label.text = str(current_hp) + "/" + str(max_hp)

func die() -> void:
	isDead = true
	emit_signal("player_died")
	wave_manager.stop_waves()

	# Exemplo: ao "morrer", zera a wave e reseta HP e as moedas
	current_hp = max_hp
	update_hp_bar()
	coins = 1000
	update_coins_label()

func apply_knockback(force: Vector2) -> void:
	_knockback = force
	# Efeito piscante de dano
	for i in range(5):
		modulate.a = 0.2
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout

# Métodos relacionados às moedas:
func add_coins(amount: int) -> void:
	coins += amount
	update_coins_label()

func spend_coins(amount: int) -> void:
	coins = max(coins - amount, 0)
	update_coins_label()

func update_coins_label() -> void:
	if coins_label:
		coins_label.text = str(coins)
