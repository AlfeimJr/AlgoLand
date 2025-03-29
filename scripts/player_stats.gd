class_name PlayerStats

var strength: int = 5 
var agility: int = 5     
var vitality: int = 5     
var intelligence: int = 5   
var luck: int = 5          

var base_move_speed: float = 114.0  # Velocidade base sem bônus
var speed_item_bonus: float = 0.0   # Bônus de velocidade adquirido via itens
var move_speed: float = base_move_speed

var max_hp: int           
var attack_damage: int    
var critical_chance: float 
var critical_damage: float  
var defense: int            

# Agora o parâmetro é genérico para qualquer arma
func calculate_derived_stats(is_weapon_equipped: bool = false):
	max_hp = vitality * 20
	attack_damage = strength * 2
	critical_chance = min(0.05 + luck * 0.01, 1.0)
	critical_damage = 1.5 + luck * 0.05

	# Aplica o bônus de movimento se qualquer arma estiver equipada
	move_speed = base_move_speed  + speed_item_bonus + agility * 0.5
	defense = vitality * 2

# Função para adicionar bônus via itens sem zerar os bônus já adquiridos
func add_speed_bonus(amount: float, is_weapon_equipped: bool = false) -> void:
	speed_item_bonus += amount
	calculate_derived_stats(is_weapon_equipped)
