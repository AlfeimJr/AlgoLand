extends CharacterBody2D

# Preload do banco de dados de armas (nome: arms_database)
var arms_database = preload("res://scripts/arms_database.gd")
signal equipment_changed
@onready var stats = preload("res://scripts/player_stats.gd").new()
var is_two_handed_weapon: bool = false
@export var hair_color: Color = Color(1, 1, 1)  # Branco como padrão
var attacks_blocked: bool = false
@export_category("Variables")
@export var _friction: float = 0.3
@export var _acceleration: float = 0.3
@export var _knockback_strength: float = 200.0
@export var _knockback_decay: float = 0.1
@export var shield_level: int = 1
var is_smithing: bool = false
var current_shield_id: String = "shield_basic"
var movement_enabled: bool = true

@export var current_item_type: String = ""  # "sword", "spear", etc.

# >>> Escudo controlado separadamente <<<
@export var using_shield: bool = false

# Variável que controla o nível da arma (espada)
@export var sword_level: int = 1
var current_weapon_id: String = "sword_basic"
@export var using_sword: bool = false

# Variáveis para controlar a lança
@export var using_spear: bool = false
@export var spear_level: int = 1
var current_spear_id: String = "spear_basic"

@export_category("Objects")
@export var _animation_tree: AnimationTree = null
@export var _timer: Timer = null  # Timer para controlar a duração de cada golpe

signal smithing_finished

# ---------------------------
# BaseSprites
# ---------------------------
@onready var bodySprite = $CompositeSprites/BaseSprites/Body
@onready var hairSprite = $CompositeSprites/BaseSprites/Hair
@onready var outfit_sprite = $CompositeSprites/BaseSprites/Outfit
@onready var sword_sprite = $CompositeSprites/BaseSprites/Arm
@onready var shield_sprite = $CompositeSprites/BaseSprites/Child
@onready var spear_sprite = $CompositeSprites/BaseSprites/spear

# Arrays exclusivos do Smithing
var smithing_hair_array: Array[Texture2D] = []
var smithing_outfit_array: Array[Texture2D] = []

# ---------------------------
# AttackSwordAnimation (espada)
# ---------------------------
@onready var attackSwordChieldBody = $CompositeSprites/AttackSwordAnimation/SwordChieldBody
@onready var attackSwordArm = $CompositeSprites/AttackSwordAnimation/SwordArm
@onready var attackChield = $CompositeSprites/AttackSwordAnimation/Chield
@onready var attackHair = $CompositeSprites/AttackSwordAnimation/Hair
@onready var attackOutfit = $CompositeSprites/AttackSwordAnimation/Outfit

# ---------------------------
# AttackSpearAnimation (lança)
# ---------------------------
@onready var attackSpearChieldBody = $CompositeSprites/AttackSpearAnimation/Body
@onready var attackSpearArm = $CompositeSprites/AttackSpearAnimation/Spear
@onready var attackSpearHair = $CompositeSprites/AttackSpearAnimation/Hair
@onready var attackSpearOutfit = $CompositeSprites/AttackSpearAnimation/Outfit

@onready var composite_sprites: Composite = Composite.new()
@onready var camera: Camera2D = $Camera2D

@onready var hp_label = $"/root/cenario/UI/Hp"
@onready var coins_label: Label = $"/root/cenario/UI/Coins/count"

signal customization_finished(hair: int, outfit: int, hair_color: Color, nickname: String)
signal player_died

@export var isDead = false
@onready var wave_manager = get_node("/root/cenario/enemySpawner/WaveManager")

var nickname: String = ""
var damaged_enemies: Array[Node] = []
var purchased_items: Array[Dictionary] = []

var curr_hair: int = 0
var curr_outfit: int = 0
var _state_machine: Object
var arms_status = preload("res://scripts/Arms_status.gd").new()
var _knockback: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0

var hair_attack_array: Array[Texture2D] = []
var outfit_attack_array: Array[Texture2D] = []

# >>> Arrays de cabelo para spear <<<
var hair_attack_array_spear: Array[Texture2D] = []

# >>> Arrays de outfit para spear <<<
var outfit_attack_array_spear: Array[Texture2D] = []

var _attack_direction: Vector2 = Vector2.DOWN
var current_hp: int

var invulnerable: bool = false
var invul_time: float = 0.5
var invul_timer: float = 0.0

@onready var hp_bar_full = $"/root/cenario/UI/HealthbarFull"
@onready var hp_bar_empty = $"/root/cenario/UI/HealthbarEmpty"

# ---------------------------
# COMBO
# ---------------------------
var _is_attacking: bool = false
var _combo_phase: int = 0
var _can_chain_combo: bool = false
var _max_combo: int = 3

# Tempos para cada slash da espada
var _slash_1_time: float = 0.3
var _slash_2_time: float = 0.3
var _slash_3_time: float = 0.3

# >>> Tempos para a lança (ordem 2 -> 3 -> 1) <<<
var _spear_slash_2_time: float = 0.3
var _spear_slash_3_time: float = 0.3
var _spear_slash_1_time: float = 0.3

var _combo_window_timer: Timer

# ---------------------------
# SMITHING
# ---------------------------
@onready var smithing_node: Node2D = $CompositeSprites/Smithing
@onready var smithing_body_sprite: Sprite2D = $CompositeSprites/Smithing/Body
@onready var smithing_hair_sprite: Sprite2D = $CompositeSprites/Smithing/Hair
@onready var smithing_outfit_sprite: Sprite2D = $CompositeSprites/Smithing/Outfit

@onready var anim_player: AnimationPlayer = $CompositeSprites/Animation/AnimationPlayer

func _ready() -> void:
	stats.calculate_derived_stats(using_sword)
	current_hp = stats.max_hp

	if _timer:
		_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))

	_combo_window_timer = Timer.new()
	_combo_window_timer.one_shot = true
	add_child(_combo_window_timer)
	_combo_window_timer.connect("timeout", Callable(self, "_on_combo_window_timeout"))

	# Ajusta sprite básico do Body
	bodySprite.texture = composite_sprites.body_spriteSheet[0]

	# ---------------------------
	# Carrega arrays (espada)
	# ---------------------------
	for i in range(1, 3):
		var hair_path = "res://CharacterSprites/Hair/Attack/slash_1_sword/hair (%d).png" % i
		var hair_resource = load(hair_path)
		if hair_resource:
			hair_attack_array.append(hair_resource)

	for i in range(1, 8):
		var outfit_path = "res://CharacterSprites/Outfit/Attack/slash_1_sword/outfit(%d).png" % i
		var outfit_resource = load(outfit_path)
		if outfit_resource:
			outfit_attack_array.append(outfit_resource)

	# >>> Arrays de cabelo para spear <<<
	for i in range(1, 3):
		var hair_path_spear = "res://CharacterSprites/Hair/Attack/slash_1_spear/hair (%d).png" % i
		var hair_resource_spear = load(hair_path_spear)
		if hair_resource_spear:
			hair_attack_array_spear.append(hair_resource_spear)

	# >>> Arrays de outfit para spear <<<
	for i in range(1, 8):
		var outfit_path_spear = "res://CharacterSprites/Outfit/Attack/slash_1_spear/outfit (%d).png" % i
		var outfit_resource_spear = load(outfit_path_spear)
		if outfit_resource_spear:
			outfit_attack_array_spear.append(outfit_resource_spear)

	# Ajusta texturas iniciais
	hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
	outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
	attackSwordChieldBody.texture = load("res://CharacterSprites/Body_sword_chield/body_attack_sword.png")

	if hair_attack_array.size() > 0 and curr_hair < hair_attack_array.size():
		attackHair.texture = hair_attack_array[curr_hair]
		attackHair.modulate = hair_color

	if outfit_attack_array.size() > 0 and curr_outfit < outfit_attack_array.size():
		attackOutfit.texture = outfit_attack_array[curr_outfit]

	# Lança
	if hair_attack_array_spear.size() > 0 and curr_hair < hair_attack_array_spear.size():
		attackSpearHair.texture = hair_attack_array_spear[curr_hair]
		attackSpearHair.modulate = hair_color

	if outfit_attack_array_spear.size() > 0 and curr_outfit < outfit_attack_array_spear.size():
		attackSpearOutfit.texture = outfit_attack_array_spear[curr_outfit]
		attackSpearOutfit.modulate = Color(1, 1, 1)

	if _animation_tree:
		_state_machine = _animation_tree.get("parameters/playback")

	# Configura a área de ataque
	$AttackArea.collision_layer = 1 << 1
	$AttackArea.collision_mask = 1 << 2
	$AttackArea.monitoring = false
	$AttackArea.monitorable = false

	connect_signal_if_not_connected($AttackArea, "body_entered", "_on_attack_body_entered")
	connect_signal_if_not_connected($AttackArea, "area_entered", "_on_attack_area_entered")

	var loaded_data = load_from_json()
	apply_loaded_data(loaded_data)

	smithing_node.visible = false
	wave_manager.connect("wave_completed", Callable(self, "_on_wave_completed"))
	_set_sprites_visible(false)
	update_coins_label()
	update_hp_bar()

func _on_wave_completed(wave: int) -> void:
	current_hp = stats.max_hp
	update_hp_bar()

func block_attacks(block: bool) -> void:
	attacks_blocked = block

func connect_signal_if_not_connected(node: Node, signal_name: String, method: String) -> void:
	if not node.is_connected(signal_name, Callable(self, method)):
		node.connect(signal_name, Callable(self, method))

func _physics_process(delta: float) -> void:
	if not movement_enabled:
		return

	if Input.is_action_just_pressed("debug_damage"):
		take_damage(1)

	if invulnerable:
		invul_timer -= delta
		if invul_timer <= 0:
			invulnerable = false

	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = _knockback
		_knockback = _knockback.lerp(Vector2.ZERO, _knockback_decay)
	else:
		_move(delta)
		_attack_combo_logic()

	move_and_slide()
	_animate()

	# Checa colisões com inimigos
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("enemy") and not invulnerable:
			var knockback_dir = (position - collider.position).normalized()
			var enemy_damage = 1
			if collider.has_method("get_damage"):
				enemy_damage = collider.get_damage()
			take_damage(enemy_damage, knockback_dir * _knockback_strength)
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
		velocity.x = lerp(velocity.x, dir.x * stats.move_speed, _acceleration)
		velocity.y = lerp(velocity.y, dir.y * stats.move_speed, _acceleration)
		_attack_direction = dir

		if using_sword or using_spear:
			_animation_tree.set("parameters/idle/blend_position", dir)
			_animation_tree.set("parameters/running/blend_position", dir)
		else:
			_animation_tree.set("parameters/idle/blend_position", dir)
			_animation_tree.set("parameters/run/blend_position", dir)
	else:
		velocity.x = lerp(velocity.x, 0.0, _friction)
		velocity.y = lerp(velocity.y, 0.0, _friction)

# ---------------------------
# COMBO / ATAQUE
# ---------------------------
func _attack_combo_logic() -> void:
	if attacks_blocked or get_viewport().gui_get_focus_owner() != null:
		return

	if using_sword:
		if Input.is_action_just_pressed("attack"):
			if _combo_phase == 0 and not _is_attacking:
				_combo_phase = 1
				start_attack_slash("AttackSwordSlash_1", _slash_1_time)
			elif _combo_phase == 1 and _can_chain_combo:
				_combo_phase = 2
				start_attack_slash("AttackSwordSlash_3", _slash_2_time)
			elif _combo_phase == 2 and _can_chain_combo:
				_combo_phase = 3
				start_attack_slash("AttackSwordSlash_2", _slash_3_time)
	elif using_spear:
		if Input.is_action_just_pressed("attack"):
			if _combo_phase == 0 and not _is_attacking:
				_combo_phase = 1
				start_attack_slash_spear("AttackSpearSlash_2", _spear_slash_2_time)
			elif _combo_phase == 1 and _can_chain_combo:
				_combo_phase = 2
				start_attack_slash_spear("AttackSpearSlash_3", _spear_slash_3_time)
			elif _combo_phase == 2 and _can_chain_combo:
				_combo_phase = 3
				start_attack_slash_spear("AttackSpearSlash_1", _spear_slash_1_time)

func start_attack_slash(anim_name: String, slash_time: float) -> void:
	_is_attacking = true
	$AttackArea.monitoring = true
	$AttackArea.monitorable = true
	_set_sprites_visible(true)
	_animation_tree.set("parameters/%s/blend_position" % anim_name, _attack_direction)
	_state_machine.travel(anim_name)
	_timer.start(slash_time)
	_can_chain_combo = true

func start_attack_slash_spear(anim_name: String, slash_time: float) -> void:
	anim_player.speed_scale = 0.2
	_is_attacking = true
	$AttackArea.monitoring = true
	$AttackArea.monitorable = true
	_set_sprites_visible(true)
	_animation_tree.set("parameters/%s/blend_position" % anim_name, _attack_direction)
	_state_machine.travel(anim_name)
	_timer.start(slash_time)
	_can_chain_combo = true

func _on_attack_timer_timeout() -> void:
	_is_attacking = false
	$AttackArea.monitoring = false
	$AttackArea.monitorable = false
	_set_sprites_visible(false)
	anim_player.speed_scale = 1.0

	if using_sword:
		if _combo_phase in [2, 3]:
			_combo_phase = 0
			_can_chain_combo = false
		else:
			_combo_window_timer.start(0.2)
	elif using_spear:
		if _combo_phase in [2, 3]:
			_combo_phase = 0
			_can_chain_combo = false
		else:
			_combo_window_timer.start(0.2)

func _on_combo_window_timeout() -> void:
	if _combo_phase == 1:
		_combo_phase = 0
	_can_chain_combo = false

# ---------------------------
# Animação
# ---------------------------
func _animate() -> void:
	if _is_attacking:
		return
	if velocity.length() > 2:
		if using_sword or using_spear:
			_state_machine.travel("running")
		else:
			_state_machine.travel("run")
	else:
		_state_machine.travel("idle")

func _on_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		var knockback_dir = (body.position - position).normalized()
		if body.has_method("take_damage"):
			body.take_damage(stats.attack_damage, knockback_dir * 150.0)

func _on_attack_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		var knockback_dir = (area.global_position - position).normalized()
		if area.has_method("take_damage"):
			area.take_damage(stats.attack_damage, knockback_dir * 150.0)

# ---------------------------
# Visibilidade dos sprites
# ---------------------------
func _set_sprites_visible(is_attacking: bool) -> void:
	bodySprite.visible = not is_attacking
	hairSprite.visible = not is_attacking
	outfit_sprite.visible = not is_attacking

	sword_sprite.visible = (not is_attacking) and using_sword
	spear_sprite.visible = (not is_attacking) and using_spear

	# Escudo só aparece se usando escudo E NÃO está atacando e NÃO está usando lança
	shield_sprite.visible = (not is_attacking) and using_shield and not using_spear

	# -- Animação de ataque com espada --
	attackSwordChieldBody.visible = is_attacking and using_sword
	attackSwordArm.visible = is_attacking and using_sword
	attackChield.visible = is_attacking and using_shield and using_sword  # Ajuste aqui
	attackHair.visible = is_attacking and using_sword
	attackOutfit.visible = is_attacking and using_sword

	# -- Animação de ataque com lança --
	attackSpearChieldBody.visible = is_attacking and using_spear
	attackSpearArm.visible = is_attacking and using_spear
	attackSpearHair.visible = is_attacking and using_spear
	attackSpearOutfit.visible = is_attacking and using_spear

# ---------------------------
# CUSTOMIZAÇÃO
# ---------------------------
func _on_change_hair_pressed() -> void:
	curr_hair = (curr_hair + 1) % composite_sprites.hair_spriteSheet.size()
	hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
	hairSprite.modulate = hair_color
	if curr_hair < hair_attack_array.size():
		attackHair.texture = hair_attack_array[curr_hair]
		attackHair.modulate = hair_color
	if curr_hair < hair_attack_array_spear.size():
		attackSpearHair.texture = hair_attack_array_spear[curr_hair]
		attackSpearHair.modulate = hair_color
	if smithing_hair_sprite and curr_hair < composite_sprites.hair_spriteSheet.size():
		smithing_hair_sprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
		smithing_hair_sprite.modulate = hair_color

func _on_change_hair_back_pressed() -> void:
	curr_hair = (curr_hair - 1) % composite_sprites.hair_spriteSheet.size()
	if curr_hair < 0:
		curr_hair = composite_sprites.hair_spriteSheet.size() - 1
	hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
	hairSprite.modulate = hair_color
	if curr_hair < hair_attack_array.size():
		attackHair.texture = hair_attack_array[curr_hair]
		attackHair.modulate = hair_color
	if curr_hair < hair_attack_array_spear.size():
		attackSpearHair.texture = hair_attack_array_spear[curr_hair]
		attackSpearHair.modulate = hair_color
	if smithing_hair_sprite and curr_hair < composite_sprites.hair_spriteSheet.size():
		smithing_hair_sprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
		smithing_hair_sprite.modulate = hair_color

func _on_change_outfit_pressed() -> void:
	curr_outfit = (curr_outfit + 1) % composite_sprites.outfit_spriteSheet.size()
	outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
	if curr_outfit < outfit_attack_array.size():
		attackOutfit.texture = outfit_attack_array[curr_outfit]
	if curr_outfit < outfit_attack_array_spear.size():
		attackSpearOutfit.texture = outfit_attack_array_spear[curr_outfit]
		attackSpearOutfit.modulate = Color(1, 1, 1)
	if smithing_outfit_sprite and curr_outfit < composite_sprites.outfit_spriteSheet.size():
		smithing_outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]

func _on_change_outfit_back_pressed() -> void:
	curr_outfit = (curr_outfit - 1) % composite_sprites.outfit_spriteSheet.size()
	if curr_outfit < 0:
		curr_outfit = composite_sprites.outfit_spriteSheet.size() - 1
	outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
	if curr_outfit < outfit_attack_array.size():
		attackOutfit.texture = outfit_attack_array[curr_outfit]
	if curr_outfit < outfit_attack_array_spear.size():
		attackSpearOutfit.texture = outfit_attack_array_spear[curr_outfit]
		attackSpearOutfit.modulate = Color(1, 1, 1)
	if smithing_outfit_sprite and curr_outfit < composite_sprites.outfit_spriteSheet.size():
		smithing_outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]

func save_customization() -> void:
	emit_signal("customization_finished", curr_hair, curr_outfit, hair_color, nickname)

func add_coins(amount: int) -> void:
	GameData.coins += amount
	update_coins_label()

func spend_coins(amount: int) -> void:
	GameData.coins = max(GameData.coins - amount, 0)
	update_coins_label()

func update_coins_label() -> void:
	if coins_label:
		coins_label.text = str(GameData.coins)

# ---------------------------
# FUNÇÕES DE EQUIPAR/UNEQUIP
# ---------------------------
func equip_sword() -> void:
	# Se já estiver usando espada, remover
	if using_sword:
		unequip_sword()
		return

	# Se estiver usando lança, remover antes
	if using_spear:
		unequip_spear()

	current_item_type = ""
	using_sword = true
	is_two_handed_weapon = false
	update_sword_textures()
	sword_sprite.visible = true
	stats.move_speed += 50
	emit_signal("equipment_changed")

func unequip_sword() -> void:
	using_sword = false
	sword_sprite.visible = false
	stats.calculate_derived_stats(using_sword)
	emit_signal("equipment_changed")

func equip_spear() -> void:
	if using_spear:
		unequip_spear()
		return

	if using_sword:
		unequip_sword()

	if using_shield:
		unequip_shield()

	current_item_type = "spear_basic"
	using_spear = true
	is_two_handed_weapon = true
	stats.calculate_derived_stats(true) # agora lança tem stats próprios
	update_spear_textures()
	spear_sprite.visible = true
	emit_signal("equipment_changed")

func unequip_spear() -> void:
	using_spear = false
	is_two_handed_weapon = false
	spear_sprite.visible = false
	stats.calculate_derived_stats(using_spear)
	emit_signal("equipment_changed")

func equip_shield() -> void:
	if using_shield:
		unequip_shield()
		return
	if is_two_handed_weapon:
		print("Não é possível equipar escudo com arma de duas mãos!")
		return
	using_shield = true
	shield_sprite.visible = true
	update_shield_textures()
	emit_signal("equipment_changed")

func unequip_shield() -> void:
	using_shield = false
	shield_sprite.visible = false
	emit_signal("equipment_changed")

# ---------------------------
# COMPRAS
# ---------------------------
func purchase_item(item_id: String) -> void:
	var item_data = arms_database.get_item_data(item_id)
	if item_data == {}:
		return
	if GameData.coins >= item_data.price:
		spend_coins(item_data.price)
		purchased_items.append(item_data)
		apply_item_effects(item_data)
	else:
		return

func apply_item_effects(item_data: Dictionary) -> void:
	if not item_data.has("effects"):
		return
	for effect_key in item_data.effects.keys():
		var effect_value = item_data.effects[effect_key]
		match effect_key:
			"strength":
				stats.strength += effect_value
			"defense":
				stats.defense += effect_value
			"agility":
				stats.agility += effect_value
			"lifesteal":
				stats.lifesteal += effect_value
			_:
				pass
	stats.calculate_derived_stats(using_sword)

# ---------------------------
# DANO / MORTE
# ---------------------------
func take_damage(damage: int, knockback_force: Vector2 = Vector2.ZERO) -> void:
	damage = max(damage - stats.defense, 0)
	current_hp = max(current_hp - damage, 0)
	update_hp_bar()
	if knockback_force != Vector2.ZERO:
		apply_knockback(knockback_force)
	if current_hp <= 0:
		die()

func update_hp_bar() -> void:
	var fraction = float(current_hp) / float(stats.max_hp)
	if not hp_bar_full:
		return
	hp_bar_full.scale.x = fraction
	hp_label.text = str(current_hp) + "/" + str(stats.max_hp)

func die() -> void:
	isDead = true
	emit_signal("player_died")
	wave_manager.stop_waves()
	current_hp = stats.max_hp
	update_hp_bar()
	GameData.coins = 0
	update_coins_label()

func apply_knockback(force: Vector2) -> void:
	_knockback = force
	knockback_timer = 0.1

	var sprites_to_flash = [
		$CompositeSprites/BaseSprites/Body,
		$CompositeSprites/BaseSprites/Hair,
		$CompositeSprites/BaseSprites/Outfit,
		$CompositeSprites/BaseSprites/Arm,
		$CompositeSprites/BaseSprites/Child,
		$CompositeSprites/BaseSprites/spear,
		$CompositeSprites/AttackSwordAnimation/SwordChieldBody,
		$CompositeSprites/AttackSwordAnimation/SwordArm,
		$CompositeSprites/AttackSwordAnimation/Chield,
		$CompositeSprites/AttackSwordAnimation/Hair,
		$CompositeSprites/AttackSwordAnimation/Outfit,
		$CompositeSprites/AttackSpearAnimation/Body,
		$CompositeSprites/AttackSpearAnimation/Spear,
		$CompositeSprites/AttackSpearAnimation/Hair,
		$CompositeSprites/AttackSpearAnimation/Outfit
	]

	for i in range(5):
		for sprite in sprites_to_flash:
			if sprite:
				sprite.modulate.a = 0.2
		await get_tree().create_timer(0.1).timeout

		for sprite in sprites_to_flash:
			if sprite:
				sprite.modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout

# ---------------------------
# SALVAR / CARREGAR
# ---------------------------
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

func apply_loaded_data(data: Dictionary) -> void:
	if data.has("curr_hair"):
		curr_hair = data["curr_hair"]
		hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
		if curr_hair < hair_attack_array.size():
			attackHair.texture = hair_attack_array[curr_hair]
			attackHair.modulate = hair_color
		if curr_hair < hair_attack_array_spear.size():
			attackSpearHair.texture = hair_attack_array_spear[curr_hair]
			attackSpearHair.modulate = hair_color

	if data.has("curr_outfit"):
		curr_outfit = data["curr_outfit"]
		outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
		if curr_outfit < outfit_attack_array.size():
			attackOutfit.texture = outfit_attack_array[curr_outfit]
		if curr_outfit < outfit_attack_array_spear.size():
			attackSpearOutfit.texture = outfit_attack_array_spear[curr_outfit]
			attackSpearOutfit.modulate = Color(1,1,1)

	if data.has("nickname"):
		nickname = data["nickname"]

	if data.has("hair_color"):
		var col_dict = data["hair_color"]
		var saved_hair_color = Color(col_dict["r"], col_dict["g"], col_dict["b"], col_dict["a"])
		hair_color = saved_hair_color
		hairSprite.modulate = saved_hair_color
		attackHair.modulate = saved_hair_color
		attackSpearHair.modulate = saved_hair_color

	if data.has("sword_level"):
		sword_level = data["sword_level"]
		update_sword_textures()
		var new_strength = arms_status.get_strength_for_level(sword_level)
		stats.strength = new_strength
		stats.calculate_derived_stats(using_sword)

	if data.has("using_sword"):
		using_sword = data["using_sword"]
		if using_sword and _state_machine:
			_state_machine.travel("running")

	if data.has("spear_level"):
		spear_level = data["spear_level"]
		update_spear_textures()

	if data.has("using_spear"):
		using_spear = data["using_spear"]

	# Se quiser salvar/carregar se o escudo estava equipado
	if data.has("using_shield"):
		using_shield = data["using_shield"]

func load_smithing_textures() -> void:
	if smithing_hair_array.size() > 0:
		return
	for i in range(1, 3):
		var hair_path = "res://CharacterSprites/body_smithing/Hair/hair (%d).png" % i
		var hair_tex = load(hair_path)
		if hair_tex:
			smithing_hair_array.append(hair_tex)

	for i in range(1, 8):
		var outfit_path = "res://CharacterSprites/body_smithing/Outfit/outfit (%d).png" % i
		var outfit_tex = load(outfit_path)
		if outfit_tex:
			smithing_outfit_array.append(outfit_tex)

func apply_smithing_data() -> void:
	if curr_hair < smithing_hair_array.size():
		smithing_hair_sprite.texture = smithing_hair_array[curr_hair]
		smithing_hair_sprite.modulate = hair_color

	if curr_outfit < smithing_outfit_array.size():
		smithing_outfit_sprite.texture = smithing_outfit_array[curr_outfit]

func start_smithing(item_type: String) -> void:
	is_smithing = true
	load_smithing_textures()
	var loaded_data = load_from_json()
	if loaded_data:
		if loaded_data.has("curr_hair"):
			curr_hair = loaded_data["curr_hair"]
		if loaded_data.has("curr_outfit"):
			curr_outfit = loaded_data["curr_outfit"]

	apply_smithing_data()
	movement_enabled = false
	smithing_node.visible = true
	$CompositeSprites/BaseSprites.visible = false

	if _animation_tree and _state_machine:
		_state_machine.travel("smithing")

	var smithing_timer = Timer.new()
	smithing_timer.wait_time = 5.0
	smithing_timer.one_shot = true
	add_child(smithing_timer)
	smithing_timer.connect("timeout", Callable(self, "_on_smithing_finished").bind(item_type))
	smithing_timer.start()

func _on_smithing_finished(item_type: String) -> void:
	is_smithing = false
	smithing_node.visible = false
	$CompositeSprites/BaseSprites.visible = true
	if _animation_tree and _state_machine:
		_state_machine.travel("idle")
	movement_enabled = true
	
	match item_type:
		"sword_basic":
			sword_level += 1
			update_sword_textures()
			stats.strength = arms_status.get_strength_for_level(sword_level)
			stats.calculate_derived_stats(using_sword)
		"shield_basic":
			shield_level += 1
			update_shield_textures()
			stats.defense = arms_status.get_defense_for_level(shield_level)
			stats.calculate_derived_stats(using_sword or using_spear)
		"spear_basic":
			spear_level += 1
			update_spear_textures()
			stats.strength = arms_status.get_strength_for_level(spear_level)
			stats.calculate_derived_stats(using_spear)

	update_weapon_appearance() # Garante atualização visual correta
	emit_signal("smithing_finished")

# ---------------------------
# ATUALIZAÇÃO DAS TEXTURAS
# ---------------------------
func update_sword_textures() -> void:
	var arms_db_instance = preload("res://scripts/arms_database.gd").new()
	var level_data = arms_db_instance.get_weapon_level_data(current_weapon_id, sword_level)
	if level_data.size() > 0 and level_data.has("texture"):
		sword_sprite.texture = level_data["texture"]
		if level_data.has("attack_texture"):
			attackSwordArm.texture = level_data["attack_texture"]
	else:
		if sword_level == 1:
			var base_sword_path = "res://CharacterSprites/Arms/swords/Sword_1.png"
			var attack_sword_path = "res://CharacterSprites/Arms/swords/Attack/slash_1.png"
			if ResourceLoader.exists(base_sword_path):
				sword_sprite.texture = load(base_sword_path)
			if ResourceLoader.exists(attack_sword_path):
				attackSwordArm.texture = load(attack_sword_path)
		else:
			var base_sword_path2 = "res://CharacterSprites/Arms/swords/swords_upgraded/%d/Sword_1.png" % sword_level
			var attack_sword_path2 = "res://CharacterSprites/Arms/swords/Attack/swords_upgraded/slash_1/%d/slash_1.png" % sword_level
			if ResourceLoader.exists(base_sword_path2):
				sword_sprite.texture = load(base_sword_path2)
			if ResourceLoader.exists(attack_sword_path2):
				attackSwordArm.texture = load(attack_sword_path2)

func update_spear_textures() -> void:
	var arms_db_instance = preload("res://scripts/arms_database.gd").new()
	var level_data = arms_db_instance.get_weapon_level_data(current_spear_id, spear_level)
	if level_data.size() > 0:
		if level_data.has("texture") and level_data["texture"] is Texture2D:
			spear_sprite.texture = level_data["texture"]
		if level_data.has("attack_texture") and level_data["attack_texture"] is Texture2D:
			attackSpearArm.texture = level_data["attack_texture"]
	else:
		var base_spear_path = ""
		var attack_spear_path = ""

		if spear_level == 1:
			base_spear_path = "res://CharacterSprites/Arms/spears/spear_1.png"
			attack_spear_path = "res://CharacterSprites/Arms/spears/Attack/slash_1.png"
		else:
			base_spear_path = "res://CharacterSprites/Arms/spears/spears_upgraded/%d/spear_1.png" % spear_level
			attack_spear_path = "res://CharacterSprites/Arms/spears/Attack/spears_upgraded/%d/slash_1.png" % spear_level

		if ResourceLoader.exists(base_spear_path):
			spear_sprite.texture = load(base_spear_path)
		else:
			print("Erro: Textura não encontrada:", base_spear_path)

		if ResourceLoader.exists(attack_spear_path):
			attackSpearArm.texture = load(attack_spear_path)
		else:
			print("Erro: Textura não encontrada:", attack_spear_path)

func update_shield_textures() -> void:
	var arms_db_instance = preload("res://scripts/arms_database.gd").new()
	var level_data = arms_db_instance.get_weapon_level_data(current_shield_id, shield_level)
	if level_data.size() > 0 and level_data.has("texture"):
		shield_sprite.texture = level_data["texture"]
		if level_data.has("attack_texture"):
			attackChield.texture = level_data["attack_texture"]
	else:
		if shield_level == 1:
			var base_shield_path = "res://CharacterSprites/Arms/shields/shield_1.png"
			var attack_shield_path = "res://CharacterSprites/Arms/shields/attack/slash_1.png"
			if ResourceLoader.exists(base_shield_path):
				shield_sprite.texture = load(base_shield_path)
			if ResourceLoader.exists(attack_shield_path):
				attackChield.texture = load(attack_shield_path)
		else:
			var base_shield_path2 = "res://CharacterSprites/Arms/shields/upgraded_shields/%d/shield_1.png" % shield_level
			var attack_shield_path2 = "res://CharacterSprites/Arms/shields/attack/shields_upgrade/slash_1/%d/slash_1.png" % shield_level
			if ResourceLoader.exists(base_shield_path2):
				shield_sprite.texture = load(base_shield_path2)
			if ResourceLoader.exists(attack_shield_path2):
				attackChield.texture = load(attack_shield_path2)

func update_weapon_appearance() -> void:
	if using_sword:
		update_sword_textures()
	elif using_spear:
		update_spear_textures()
	elif using_shield:
		update_shield_textures()
func disable_all_actions(disable: bool) -> void:
	# Se estiver em smithing, não permite reativar as ações
	if is_smithing:
		attacks_blocked = true
		movement_enabled = false
		return
		
	# Código original
	attacks_blocked = disable
	movement_enabled = !disable
	
	if disable and _state_machine:
		_state_machine.travel("idle")
		velocity = Vector2.ZERO
