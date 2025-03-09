class_name PlayerStats

var strength: int = 5 
var agility: int = 5     
var vitality: int = 5     
var intelligence: int = 5   
var luck: int = 5          

var base_move_speed: float = 64.0  # Valor base, sem bônus
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

	# Sempre usa o base_move_speed, sem modificar o valor base
	move_speed = base_move_speed + (50 if is_sword_equipped else 0)
	
	# Por exemplo, a defesa é calculada a partir da vitalidade:
	defense = vitality * 2
