class_name PlayerStats

var strength: int = 5 
var agility: int = 5     
var vitality: int = 5     
var intelligence: int = 5   
var luck: int = 5          
var player = preload("res://cenas/player2.tscn")
var player_instance = player.instantiate()
var max_hp: int           
var attack_damage: int    
var critical_chance: float 
var critical_damage: float  
var move_speed: float      
var defense: int            

func calculate_derived_stats():
	max_hp = vitality * 20
	attack_damage = strength * 2
	critical_chance = min(0.05 + luck * 0.01, 1.0)
	critical_damage = 1.5 + luck * 0.05
	move_speed = 64.0 + agility * 2.0
	# Agora a defesa é calculada a partir da vitalidade, e não mais da inteligência:
	defense = vitality * 2
	if player_instance.using_sword:
		move_speed += 50
