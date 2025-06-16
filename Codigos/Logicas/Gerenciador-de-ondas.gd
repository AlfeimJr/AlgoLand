extends Node

signal onda_iniciada(onda: int)
signal onda_completada(onda: int)
signal jogo_ganho()
signal sinal_ondas_paradas

@export var onda_inicial: int = 1
@export var max_inimigos: int = 5	
@export var intervalo_onda: float = 15.0
@export var max_ondas: int = 1000
@export var aumento_deteccao_por_onda: float = 0.2
@export var recompensa_ouro_base: int = 100
@onready var comerciante = $"../../Merchant"
const MAX_INIMIGOS_ATIVOS: int = 70
@export var caminho_area_spawn: NodePath = NodePath("/root/cenario/SpawnArea")

var onda_atual: int = 1
var inimigos_vivos: int = 0
var gerador
var area_spawn: Area2D
var ondas_paradas: bool = false

var multiplicador_vida_inimigo: float = 1.0
var multiplicador_dano_inimigo: float = 1.0

var onda_em_andamento: bool = false

@onready var jogador = get_node("/root/cenario/Jogador")
@onready var ui = get_node("/root/cenario/UI")
func _ready() -> void:
	await get_tree().create_timer(0.0).timeout
	onda_atual = onda_inicial
	gerador = get_tree().get_root().get_node("/root/cenario/enemySpawner")
	area_spawn = get_node(caminho_area_spawn)

func iniciar_onda() -> void:
	ondas_paradas = false
	if jogador.estaMorto:
		onda_atual = 1
		jogador.isDead = false
	if ondas_paradas:
		return
	if onda_atual > max_ondas:
		emit_signal("jogo_ganho")
		return
	emit_signal("onda_iniciada", onda_atual)
	comerciante.visible = false
	onda_em_andamento = true
	# Define o total de inimigos para a onda no início
	inimigos_vivos = int(max_inimigos * pow(1.5, onda_atual - 1))
	# Não sobrescreva a contagem no gerador!
	multiplicador_vida_inimigo = 1.0 + (onda_atual * 0.2)
	multiplicador_dano_inimigo = 1.0 + (onda_atual * 0.1)
	var escala_deteccao = 1.0 + (onda_atual - 1) * aumento_deteccao_por_onda
	var banner_onda = get_tree().get_root().get_node("cenario/UI/wave")
	if banner_onda:
		banner_onda.show_wave_number(onda_atual)
	atualizar_ui()
	# Chama o gerador para criar os inimigos
	gerador.spawnar_inimigos(inimigos_vivos, multiplicador_vida_inimigo, multiplicador_dano_inimigo)

func atualizar_ui() -> void:
	if $enemiesCount/enemies_label:
		$enemiesCount/enemies_label.text = "Inimigos: " + str(inimigos_vivos)

func inimigo_morreu() -> void:
	inimigos_vivos -= 1
	atualizar_ui()
	if inimigos_vivos <= 0:
		var recompensa = recompensa_ouro_base * onda_atual
		DadosJogo.adicionar_moedas(recompensa)
		comerciante.visible = true
		var loja = get_tree().get_root().get_node_or_null("cenario/UI/MerchantMenu")
		if loja and loja.is_visible():
			loja.update_coins_display()
		onda_em_andamento = false
		emit_signal("onda_completada", onda_atual)
		onda_atual += 1

func parar_ondas() -> void:
	ondas_paradas = true
	emit_signal("sinal_ondas_paradas")
	comerciante.visible = true
	var lista_inimigos = get_tree().get_nodes_in_group("enemy")
	for inimigo in lista_inimigos:
		inimigo.queue_free()
	onda_atual = 1
	inimigos_vivos = 0
	onda_em_andamento = false
	var ui = get_tree().get_root().get_node("cenario/UI")
	if ui:
		ui.enemies_label.text = "Inimigos"
