extends CharacterBody2D

# Preload do banco de dados de armas (nome: arms_database)
var arms_database = preload("res://scripts/arms_database.gd")

@onready var stats = preload("res://scripts/player_stats.gd").new()
@export var hair_color: Color = Color(1, 1, 1)  # Branco como padrão
@export_category("Variables")
@export var _friction: float = 0.3
@export var _acceleration: float = 0.3
@export var _knockback_strength: float = 200.0
@export var _knockback_decay: float = 0.1
@export var shield_level: int = 1
var current_shield_id: String = "shield_basic"
var movement_enabled: bool = true

# Variável que controla o nível da arma
@export var sword_level: int = 1
# Identificador da arma equipada – permite trocar para outras armas futuramente
var current_weapon_id: String = "sword_basic"

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

# Arrays exclusivos do Smithing
var smithing_hair_array: Array[Texture2D] = []
var smithing_outfit_array: Array[Texture2D] = []

# ---------------------------
# AttackSwordAnimation
# ---------------------------
@onready var attackSwordChieldBody = $CompositeSprites/AttackSwordAnimation/SwordChieldBody
@onready var attackSwordArm = $CompositeSprites/AttackSwordAnimation/SwordArm
@onready var attackChield = $CompositeSprites/AttackSwordAnimation/Chield
@onready var attackHair = $CompositeSprites/AttackSwordAnimation/Hair
@onready var attackOutfit = $CompositeSprites/AttackSwordAnimation/Outfit

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

@export var using_sword: bool = false

var hair_attack_array: Array[Texture2D] = []
var outfit_attack_array: Array[Texture2D] = []

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
var _slash_1_time: float = 0.3
var _slash_2_time: float = 0.3
var _slash_3_time: float = 0.3
var _combo_window_timer: Timer

# ---------------------------
# SMITHING
# ---------------------------
@onready var smithing_node: Node2D = $CompositeSprites/Smithing
@onready var smithing_body_sprite: Sprite2D = $CompositeSprites/Smithing/Body
@onready var smithing_hair_sprite: Sprite2D = $CompositeSprites/Smithing/Hair
@onready var smithing_outfit_sprite: Sprite2D = $CompositeSprites/Smithing/Outfit

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

	# Carrega arrays de cabelo/outfit para ataques (base e attack)
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

	# Ajusta texturas iniciais
	hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
	outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
	attackSwordChieldBody.texture = load("res://CharacterSprites/Body_sword_chield/body_attack_sword.png")

	if hair_attack_array.size() > 0 and curr_hair < hair_attack_array.size():
		attackHair.texture = hair_attack_array[curr_hair]
		attackHair.modulate = hair_color  # Aplica a cor também no sprite de ataque
	if outfit_attack_array.size() > 0 and curr_outfit < outfit_attack_array.size():
		attackOutfit.texture = outfit_attack_array[curr_outfit]

	if _animation_tree:
		_state_machine = _animation_tree.get("parameters/playback")

	# Configura a área de ataque
	$AttackArea.collision_layer = 1 << 1
	$AttackArea.collision_mask = 1 << 2
	$AttackArea.monitoring = false
	$AttackArea.monitorable = false

	connect_signal_if_not_connected($AttackArea, "body_entered", "_on_attack_body_entered")
	connect_signal_if_not_connected($AttackArea, "area_entered", "_on_attack_area_entered")

	# Carrega dados do JSON para o base 
	var loaded_data = load_from_json()
	apply_loaded_data(loaded_data)

	# Oculta smithing no início
	smithing_node.visible = false

	_set_sprites_visible(false)
	update_coins_label()
	update_hp_bar()

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

		if using_sword:
			_animation_tree.set("parameters/idle/blend_position", dir)
			_animation_tree.set("parameters/running/blend_position", dir)
		else:
			_animation_tree.set("parameters/idle/blend_position", dir)
			_animation_tree.set("parameters/run/blend_position", dir)
	else:
		velocity.x = lerp(velocity.x, 0.0, _friction)
		velocity.y = lerp(velocity.y, 0.0, _friction)

# ---------------------------
# COMBO
# ---------------------------
func _attack_combo_logic() -> void:
	if not using_sword:
		return

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

func start_attack_slash(anim_name: String, slash_time: float) -> void:
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
		if using_sword:
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

func _set_sprites_visible(is_attacking: bool) -> void:
	bodySprite.visible = not is_attacking
	hairSprite.visible = not is_attacking
	outfit_sprite.visible = not is_attacking
	sword_sprite.visible = not is_attacking
	shield_sprite.visible = not is_attacking
	attackSwordChieldBody.visible = is_attacking
	attackSwordArm.visible = is_attacking
	attackChield.visible = is_attacking
	attackHair.visible = is_attacking
	attackOutfit.visible = is_attacking

# ---------------------------
# CUSTOMIZAÇÃO
# ---------------------------
func _on_change_hair_pressed() -> void:
	curr_hair = (curr_hair + 1) % composite_sprites.hair_spriteSheet.size()
	hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
	# Reaplica a cor salva após atualizar a textura
	hairSprite.modulate = hair_color

	if curr_hair < hair_attack_array.size():
		attackHair.texture = hair_attack_array[curr_hair]
		attackHair.modulate = hair_color  # Aplica a modulação no attackHair
	if smithing_hair_sprite and curr_hair < composite_sprites.hair_spriteSheet.size():
		smithing_hair_sprite.texture = composite_sprites.hair_spriteSheet[curr_hair]

func _on_change_hair_back_pressed() -> void:
	curr_hair = (curr_hair - 1) % composite_sprites.hair_spriteSheet.size()
	if curr_hair < 0:
		curr_hair = composite_sprites.hair_spriteSheet.size() - 1
	hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
	hairSprite.modulate = hair_color  # Reaplica a cor

	if curr_hair < hair_attack_array.size():
		attackHair.texture = hair_attack_array[curr_hair]
		attackHair.modulate = hair_color  # Aplica a modulação no attackHair
	if smithing_hair_sprite and curr_hair < composite_sprites.hair_spriteSheet.size():
		smithing_hair_sprite.texture = composite_sprites.hair_spriteSheet[curr_hair]

func _on_change_outfit_pressed() -> void:
	curr_outfit = (curr_outfit + 1) % composite_sprites.outfit_spriteSheet.size()
	outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
	if curr_outfit < outfit_attack_array.size():
		attackOutfit.texture = outfit_attack_array[curr_outfit]
	if smithing_outfit_sprite and curr_outfit < composite_sprites.outfit_spriteSheet.size():
		smithing_outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]

func _on_change_outfit_back_pressed() -> void:
	curr_outfit = (curr_outfit - 1) % composite_sprites.outfit_spriteSheet.size()
	if curr_outfit < 0:
		curr_outfit = composite_sprites.outfit_spriteSheet.size() - 1
	outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
	if curr_outfit < outfit_attack_array.size():
		attackOutfit.texture = outfit_attack_array[curr_outfit]
	if smithing_outfit_sprite and curr_outfit < composite_sprites.outfit_spriteSheet.size():
		smithing_outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]

func save_customization():
	emit_signal("customization_finished", curr_hair, curr_outfit, hair_color, nickname)

# ---------------------------
# MOEDAS / UI
# ---------------------------
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
# EQUIPAR / DESEQUIPAR
# ---------------------------
func equip_sword_and_shield() -> void:
	if using_sword:
		unequip_sword_and_shield()
		return
	using_sword = true

	update_sword_textures()
	update_shield_textures()

	sword_sprite.visible = true
	shield_sprite.visible = true
	stats.move_speed += 50

func unequip_sword_and_shield() -> void:
	using_sword = false
	sword_sprite.visible = false
	shield_sprite.visible = false
	stats.calculate_derived_stats(using_sword)
	
# ---------------------------
# COMPRA DE ITENS
# ---------------------------
func purchase_item(item_id: String) -> void:
	# Aqui alteramos para usar arms_database (assegure-se de que esse método exista no arms_database se for para itens)
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
# DANO E MORTE
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
	for i in range(5):
		modulate.a = 0.2
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout

# ---------------------------
# CARREGAR/SALVAR
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

func apply_loaded_data(data: Dictionary):
	if data.has("curr_hair"):
		curr_hair = data["curr_hair"]
		hairSprite.texture = composite_sprites.hair_spriteSheet[curr_hair]
		if curr_hair < hair_attack_array.size():
			attackHair.texture = hair_attack_array[curr_hair]
			attackHair.modulate = hair_color  # Aplica a modulação também aqui

	if data.has("curr_outfit"):
		curr_outfit = data["curr_outfit"]
		outfit_sprite.texture = composite_sprites.outfit_spriteSheet[curr_outfit]
		if curr_outfit < outfit_attack_array.size():
			attackOutfit.texture = outfit_attack_array[curr_outfit]

	if data.has("nickname"):
		nickname = data["nickname"]

	if data.has("hair_color"):
		# Aqui, data["hair_color"] é um dicionário com as chaves "r", "g", "b" e "a"
		var col_dict = data["hair_color"]
		var saved_hair_color = Color(col_dict["r"], col_dict["g"], col_dict["b"], col_dict["a"])
		hair_color = saved_hair_color
		# Aplica a cor ao sprite do cabelo
		hairSprite.modulate = saved_hair_color
		attackHair.modulate = saved_hair_color  # Aplica a cor também no attackHair

	if data.has("sword_level"):
		sword_level = data["sword_level"]
		# Atualiza a arma consultando o arms_database
		update_sword_textures()
		var new_strength = arms_status.get_strength_for_level(sword_level)
		stats.strength = new_strength
		stats.calculate_derived_stats(using_sword)

	if data.has("using_sword"):
		using_sword = data["using_sword"]
		if using_sword and _state_machine:
			_state_machine.travel("running")

# ---------------------------
# FUNÇÕES ESPECÍFICAS PARA SMITHING
# ---------------------------
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
		smithing_hair_sprite.modulate = hair_color  # Aplica a cor do cabelo no sprite de smithing
	if curr_outfit < smithing_outfit_array.size():
		smithing_outfit_sprite.texture = smithing_outfit_array[curr_outfit]

func start_smithing() -> void:
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
	smithing_timer.connect("timeout", Callable(self, "_on_smithing_finished"))
	smithing_timer.start()

func _on_smithing_finished() -> void:
	smithing_node.visible = false
	$CompositeSprites/BaseSprites.visible = true

	if _animation_tree and _state_machine:
		_state_machine.travel("idle")

	movement_enabled = true

	# Incrementa 1 nível de espada e 1 nível de escudo
	sword_level += 1
	shield_level += 1  # se quiser que o escudo acompanhe a espada

	update_sword_textures()
	update_shield_textures()

	var new_strength = arms_status.get_strength_for_level(sword_level)
	stats.strength = new_strength
	stats.calculate_derived_stats(using_sword)
	emit_signal("smithing_finished")

# ---------------------------
# ATUALIZAÇÃO DAS TEXTURAS DA ARMA
# ---------------------------
func update_sword_textures() -> void:
	# Cria uma instância do arms_database para obter os dados da arma
	var arms_db_instance = preload("res://scripts/arms_database.gd").new()
	var level_data = arms_db_instance.get_weapon_level_data(current_weapon_id, sword_level)
	if level_data.size() > 0 and level_data.has("texture"):
		# Atualiza a textura principal com a do database
		sword_sprite.texture = level_data["texture"]
		# Se houver uma textura para ataque, atualiza; caso contrário, não altera attackSwordArm (para preservar as animações)
		if level_data.has("attack_texture"):
			attackSwordArm.texture = level_data["attack_texture"]
	else:
		# Fallback para o sistema antigo
		if sword_level == 1:
			var base_sword_path = "res://CharacterSprites/Arms/swords/Sword_1.png"
			var attack_sword_path = "res://CharacterSprites/Arms/swords/Attack/slash_1.png"
			if ResourceLoader.exists(base_sword_path):
				sword_sprite.texture = load(base_sword_path)
			if ResourceLoader.exists(attack_sword_path):
				attackSwordArm.texture = load(attack_sword_path)
		else:
			var base_sword_path = "res://CharacterSprites/Arms/swords/swords_upgraded/%d/Sword_1.png" % sword_level
			var attack_sword_path = "res://CharacterSprites/Arms/swords/Attack/swords_upgraded/slash_1/%d/slash_1.png" % sword_level
			print("trocando textura da arma", base_sword_path)
			if ResourceLoader.exists(base_sword_path):
				sword_sprite.texture = load(base_sword_path)
			if ResourceLoader.exists(attack_sword_path):
				attackSwordArm.texture = load(attack_sword_path)
				
func update_shield_textures() -> void:
	var arms_db_instance = preload("res://scripts/arms_database.gd").new()
	var level_data = arms_db_instance.get_weapon_level_data(current_shield_id, shield_level)
	if level_data.size() > 0 and level_data.has("texture"):
		shield_sprite.texture = level_data["texture"]
		if level_data.has("attack_texture"):
			attackChield.texture = level_data["attack_texture"]
	else:
		# Fallback se não achar no database
		if shield_level == 1:
			var base_shield_path = "res://CharacterSprites/Arms/shields/shield_1.png"
			var attack_shield_path = "res://CharacterSprites/Arms/shields/attack/slash_1.png"
			if ResourceLoader.exists(base_shield_path):
				shield_sprite.texture = load(base_shield_path)
			if ResourceLoader.exists(attack_shield_path):
				attackChield.texture = load(attack_shield_path)
		else:
			var base_shield_path = "res://CharacterSprites/Arms/shields/upgraded_shields/%d/shield_1.png" % shield_level
			var attack_shield_path = "res://CharacterSprites/Arms/shields/attack/shields_upgrade/slash_1/%d/slash_1.png" % shield_level
			if ResourceLoader.exists(base_shield_path):
				shield_sprite.texture = load(base_shield_path)
			if ResourceLoader.exists(attack_shield_path):
				attackChield.texture = load(attack_shield_path)
