class_name PlayerStats

var strength: int = 5 
var agility: int = 5     
var vitality: int = 5     
var intelligence: int = 5   
var luck: int = 5          

var base_move_speed: float = 64.0  # Velocidade base sem bônus
var speed_item_bonus: float = 0.0   # Bônus de velocidade adquirido via itens
var move_speed: float = base_move_speed

var max_hp: int           
var attack_damage: int    
var critical_chance: float 
var critical_damage: float  
var defense: int            

func calculate_derived_stats(is_sword_equipped: bool = false):
	max_hp = vitality * 20
	attack_damage = strength * 2
	critical_chance = min(0.05 + luck * 0.01, 1.0)
	critical_damage = 1.5 + luck * 0.05

	# O move_speed é calculado a partir da velocidade base, mais bônus da arma (se equipada)
	# e mais o bônus de itens que você adicionou
	move_speed = base_move_speed + (50 if is_sword_equipped else 0) + speed_item_bonus
	
	defense = vitality * 2

# Função para adicionar bônus de velocidade via itens, sem resetar o que já foi adquirido
func add_speed_bonus(amount: float, is_sword_equipped: bool = false) -> void:
	speed_item_bonus += amount
	# Recalcula os stats passando o status de "espada equipada" que vem de fora
	calculate_derived_stats(is_sword_equipped)
