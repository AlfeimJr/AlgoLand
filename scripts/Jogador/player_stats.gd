# PlayerStats.gd
# ====================
# Esta classe calcula os atributos derivados (HP, Defesa, etc.) a partir dos atributos básicos.
# Ajustamos a Defesa para ser = vitality em vez de vitality * 2.

class_name PlayerStats

# Atributos básicos
var strength: int = 5 
var agility: int = 5     
var vitality: int = 5     
var intelligence: int = 5   
var luck: int = 5          

# Atributos de movimento
var base_move_speed: float = 114.0  # Velocidade base sem bônus
var speed_item_bonus: float = 0.0   # Bônus de velocidade adquirido via itens
var move_speed: float = base_move_speed

# Atributos derivados
var max_hp: int           
var attack_damage: int    
var critical_chance: float 
var critical_damage: float  
var defense: int            

func calculate_derived_stats(is_weapon_equipped: bool = false):
	# Ajusta HP
	max_hp = vitality * 20

	# Ajusta dano
	attack_damage = strength * 2

	# Ajusta crítico
	critical_chance = min(0.05 + luck * 0.01, 1.0)
	critical_damage = 1.5 + luck * 0.05

	# Velocidade final (sem alteração aqui)
	move_speed = base_move_speed + speed_item_bonus + agility * 0.5

	# **Mudança principal**: defesa agora = vitality (antes era vitality * 2)
	defense = vitality

# Função para adicionar bônus de velocidade sem zerar valores anteriores
func add_speed_bonus(amount: float, is_weapon_equipped: bool = false) -> void:
	speed_item_bonus += amount
	calculate_derived_stats(is_weapon_equipped)
