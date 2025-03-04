# Arquivo PlayerStats.gd
class_name PlayerStats

var strength: int = 5       # Força
var agility: int = 5        # Velocidade
var vitality: int = 5       # Vitalidade
var intelligence: int = 5   # Inteligência
var luck: int = 5           # Sorte
var player = preload("res://cenas/player2.tscn")
var player_instance = player.instantiate()
var max_hp: int             # Calculado com base na vitalidade
var attack_damage: int      # Calculado com base na força
var critical_chance: float  # Calculado com base na sorte
var critical_damage: float  # Multiplicador crítico
var move_speed: float       # Calculado com base na agilidade
var defense: int            # Defesa física/mágica

func calculate_derived_stats():
	max_hp = vitality * 20
	attack_damage = strength * 2
	print()
	critical_chance = min(0.05 + luck * 0.01, 1.0)  # Máximo de 100%
	critical_damage = 1.5 + luck * 0.05             # Aumenta com sorte
	move_speed = 64.0 + agility * 2.0
	defense = intelligence * 2
	if player_instance.using_sword:
		move_speed += 50
		print("caiu aq")
