extends Node2D

signal menu_fechado
@export var distancia_deteccao: float = 200.0

@onready var menu_principal: Control = $Botoes
@onready var lista_armas: Control = $Armas
@onready var lista_construcao: Control = $ContainerItens
@onready var container_itens = $ContainerItens
@onready var especificacao_itens = $EspecificacaoItem
@onready var botao_voltar = $BotaoVoltar
@onready var container_moedas = $Moedas
@onready var botao_iniciar_onda: Button = $Botoes/IniciarOnda
@onready var botao_atualizar: Button = $Botoes/Atualizar
@onready var botao_sair: Button = $Botoes/Sair
@onready var botao_opcao_armas: Button = $Botoes/opcaoArmas
@onready var botao_construir: Button = $Botoes/Construir
@onready var jogador = get_tree().get_root().get_node("cenario/Jogador")
@onready var botao_upgrade: Button = $Atualizar/CliqueUpgrade
var cena_item = preload("res://cenas/item.tscn")
var limites_onda = {
	1: 4,
	2: 9,
	3: 20,
	4: 35
}

# Função genérica para extrair o tipo de arma da chave atual
func obter_tipo_arma_generico(id_arma_atual: String) -> String:
	if id_arma_atual.find("espada_basica") != -1:
		return "espada_basica"
	elif id_arma_atual.find("escudo_basico") != -1:
		return "escudo_basico"
	elif id_arma_atual.find("lanca_basica") != -1:
		return "lanca_basica"
	else:
		return ""

func _ready() -> void:
	
	if jogador and not jogador.is_connected("equipamento_alterado", Callable(self, "_on_equipamento_jogador_alterado")):
		jogador.connect("equipamento_alterado", Callable(self, "_on_equipamento_jogador_alterado"))
	var inventario = get_tree().get_root().get_node("cenario/Jogador/Inventario")
	if inventario:
		inventario.connect("item_selecionado", Callable(self, "_on_item_inventario_selecionado"))

	atualizar_exibicao_moedas()

	var gerenciador_ondas = get_tree().get_root().get_node("cenario/enemySpawner/GerenciadorOndas")
	if gerenciador_ondas and gerenciador_ondas.onda_iniciada:
		hide()
		return

	# Conexões de botões
	if botao_iniciar_onda and not botao_iniciar_onda.is_connected("pressed", Callable(self, "_on_iniciar_onda_pressionado")):
		botao_iniciar_onda.disabled = true
		botao_iniciar_onda.connect("pressed", Callable(self, "_on_iniciar_onda_pressionado"))

	if botao_atualizar and not botao_atualizar.is_connected("pressed", Callable(self, "_on_atualizar_pressionado")):
		botao_atualizar.connect("pressed", Callable(self, "_on_atualizar_pressionado"))

	if botao_opcao_armas and not botao_opcao_armas.is_connected("pressed", Callable(self, "_on_armas_pressionado")):
		botao_opcao_armas.connect("pressed", Callable(self, "_on_armas_pressionado"))

	if has_node("Container/Armas/Espada"):
		var botao_espada = $Container/Armas/Espada
		if botao_espada and not botao_espada.is_connected("pressed", Callable(self, "_on_espada_pressionado")):
			botao_espada.connect("pressed", Callable(self, "_on_espada_pressionado"))

	if has_node("Container/Armas/Lanca"):
		var botao_lanca = $Container/Armas/Lanca
		if botao_lanca:
			if botao_lanca is Button:
				if not botao_lanca.is_connected("pressed", Callable(self, "_on_lanca_pressionado")):
					botao_lanca.connect("pressed", Callable(self, "_on_lanca_pressionado"))
			else:
				if not botao_lanca.is_connected("gui_input", Callable(self, "_on_lanca_gui_input")):
					botao_lanca.connect("gui_input", Callable(self, "_on_lanca_gui_input"))

	# >>> ADICIONE ESTA PARTE PARA O ESCUDO <<<
	if has_node("Container/Armas/Escudo"):
		var botao_escudo = $Container/Armas/Escudo
		if botao_escudo and not botao_escudo.is_connected("pressed", Callable(self, "_on_escudo_pressionado")):
			botao_escudo.connect("pressed", Callable(self, "_on_escudo_pressionado"))

	if botao_construir and not botao_construir.is_connected("pressed", Callable(self, "_on_construir_pressionado")):
		botao_construir.connect("pressed", Callable(self, "_on_construir_pressionado"))

	if botao_voltar and not botao_voltar.is_connected("pressed", Callable(self, "_on_botao_voltar_pressionado")):
		botao_voltar.connect("pressed", Callable(self, "_on_botao_voltar_pressionado"))

	if botao_sair and not botao_sair.is_connected("pressed", Callable(self, "_on_sair_pressionado")):
		botao_sair.connect("pressed", Callable(self, "_on_sair_pressionado"))

	# Verifica se o jogador está usando espada ou lança
	if jogador:
		if jogador.usando_espada:
			botao_iniciar_onda.disabled = false
			$Armas/Braco/espada/Texto.text = "DESEQUIPAR"
		else:
			$Armas/Braco/espada/Texto.text = "EQUIPAR"

		if jogador.usando_lanca:
			$Armas/Lanca/lanca/Texto.text = "DESEQUIPAR"
		else:
			$Armas/Lanca/lanca/Texto.text = "EQUIPAR"

		# (Opcional) Se quiser inicializar o texto do escudo:
		if jogador.usando_escudo:
			$Armas/Escudo/Escudo/Texto.text = "DESEQUIPAR"
		else:
			$Armas/Escudo/Escudo/Texto.text = "EQUIPAR"

		jogador.bloquear_ataques(true)

func _on_item_inventario_selecionado(tipo_item: String, textura: Texture2D) -> void:
	print(textura)
	var instancia_bd_armas = preload("res://Codigos/DadosLocais/Equipamentos.gd").new()
	var jogador = get_tree().get_current_scene().get_node("Jogador")
	var nivel_atual = 0
	var proximo_nivel = 0
	if tipo_item == "espada_basica":
		nivel_atual = jogador.nivel_espada
		proximo_nivel = nivel_atual 
	elif tipo_item == "escudo_basico":
		nivel_atual = jogador.nivel_escudo
		proximo_nivel = nivel_atual

	var dados_proximo = instancia_bd_armas.obter_dados_nivel_arma(jogador.id_arma_atual, proximo_nivel)
	if dados_proximo.size() > 0:
		var onda_necessaria = dados_proximo.get("onda_necessaria", 9999)

func _process(delta: float) -> void:
	var jogador = get_tree().get_current_scene().get_node("Jogador")
	if jogador:
		# Se quiser permitir iniciar a onda se tiver espada, lança ou escudo, mude para:
		botao_iniciar_onda.disabled = not (jogador.usando_espada or jogador.usando_lanca or jogador.usando_escudo)
		botao_atualizar.disabled = not (jogador.usando_espada or jogador.usando_lanca)
		# Se NÃO quiser permitir onda só com escudo, use a linha anterior do original:
		# botao_iniciar_onda.disabled = not (jogador.usando_espada or jogador.usando_lanca)

	if Input.is_action_just_pressed("close_menu"):
		ao_botao_fechar_pressionado()

func _on_botao_pressionado() -> void:
	var jogador = get_tree().get_current_scene().get_node("Jogador")
	if not jogador:
		return
	jogador.equipar_espada()
	if jogador.usando_espada:
		$Armas/Braco/espada/Texto.text = "DESEQUIPAR"
	else:
		$Armas/Braco/espada/Texto.text = "EQUIPAR"
	if botao_iniciar_onda:
		botao_iniciar_onda.disabled = not jogador.usando_espada

func _on_iniciar_onda_pressionado() -> void:
	var jogador = get_tree().get_current_scene().get_node("Jogador")
	print("Iniciar onda pressionado, usando_espada:", jogador.usando_espada)
	if jogador and not (jogador.usando_espada or jogador.usando_lanca or jogador.usando_escudo):
		return
	var gerenciador_ondas = get_tree().get_root().get_node("cenario/enemySpawner/GerenciadorOndas")
	if gerenciador_ondas:
		gerenciador_ondas.iniciar_onda()
	ao_botao_fechar_pressionado()

func ao_botao_fechar_pressionado() -> void:
	var jogador = get_tree().get_current_scene().get_node("Jogador")
	if jogador:
		jogador.desabilitar_todas_acoes(false)
	if jogador:
		jogador.bloquear_ataques(false)
	
	# Reseta a posição do item arrastado
	
	
	# Fecha (oculta) o inventário
	var inventario = get_tree().get_current_scene().get_node("Jogador/Inventario")
	if inventario:
		inventario.fechar()

	emit_signal("menu_fechado")
	hide()

func _on_armas_pressionado() -> void:
	botao_voltar.visible = true
	menu_principal.visible = false
	$Moldura2.visible = true
	lista_armas.visible = true

func _on_construir_pressionado() -> void:
	menu_principal.visible = false
	$Moldura2.visible = true
	lista_armas.visible = false
	lista_construcao.visible = true
	container_itens.visible = true
	botao_voltar.visible = true
	container_moedas.visible = true
	for filho in container_itens.get_children():
		filho.queue_free()
	atualizar_exibicao_moedas()
	for chave in DadosDosItems.itens.keys():
		var dados_item = DadosDosItems.obter_dados_item(chave)
		if dados_item.size() > 0:
			var instancia_item = cena_item.instantiate()
			instancia_item.definir_dados_item(dados_item)
			instancia_item.connect("item_clicado", Callable(self, "_on_item_clicado"))
			container_itens.add_child(instancia_item)

func _on_item_clicado(dados_item_clicado: Dictionary) -> void:
	especificacao_itens.visible = true
	especificacao_itens.definir_dados_item(dados_item_clicado)

func _on_botao_voltar_pressionado() -> void:
	menu_principal.visible = true
	$Moldura2.visible = true
	botao_voltar.visible = false
	$Moldura2.visible = false
	lista_armas.visible = false
	lista_construcao.visible = false
	container_itens.visible = false
	especificacao_itens.visible = false
	container_moedas.visible = false
	$Atualizar.visible = false
	var inventario = get_tree().get_current_scene().get_node("Jogador/Inventario")
	if inventario:
		inventario.fechar()

func atualizar_exibicao_moedas() -> void:
	var rotulo_moedas = container_moedas.get_node("contador")
	if rotulo_moedas and rotulo_moedas is Label:
		rotulo_moedas.text = str(DadosJogo.moedas)

func _on_sair_pressionado() -> void:
	var jogador = get_tree().get_current_scene().get_node("Jogador")
	if jogador:
		jogador.desabilitar_todas_acoes(false) 
	emit_signal("menu_fechado")
	hide()

# Ao clicar no botão de atualizar (bigorna) abre o menu de upgrade
func _on_atualizar_pressionado() -> void:
	mostrar_menu_upgrade()

# Configura e mostra o menu de upgrade
func mostrar_menu_upgrade() -> void:
	$Atualizar.visible = true
	menu_principal.visible = false
	botao_voltar.visible = true
	$Moldura2.visible = true
	lista_armas.visible = false
	lista_construcao.visible = false
	container_itens.visible = false
	especificacao_itens.visible = false
	container_moedas.visible = false
	
	var area_slot = $"Atualizar/Slot/Area2D"
	area_slot.collision_layer = 12
	area_slot.collision_mask = 11
	area_slot.add_to_group("escudo")
	area_slot.add_to_group("espada")

	if not area_slot.is_connected("area_entered", Callable(self, "_on_area_2d_area_entrou")):
		area_slot.connect("area_entered", Callable(self, "_on_area_2d_area_entrou"))
	if not area_slot.is_connected("area_exited", Callable(self, "_on_area_2d_area_saiu")):
		area_slot.connect("area_exited", Callable(self, "_on_area_2d_area_saiu"))
		
	var no_slot = $Atualizar/Slot
	
	# Conectar o sinal do slot para atualizar o botão
	if not no_slot.is_connected("item_alterado", Callable(self, "_on_item_slot_alterado")):
		no_slot.connect("item_alterado", Callable(self, "_on_item_slot_alterado"))
	verificar_estado_botao_upgrade()
	atualizar_texto_botao_upgrade()
	
func _on_item_slot_alterado(tem_item: bool) -> void:
	verificar_estado_botao_upgrade()
	atualizar_texto_botao_upgrade()
	
	# Pega o nó de informações (InfoItemUpdate) e seus componentes
	var info_item_upgrade = $Atualizar/InfoItemUpgrade
	
	# Se não há item no slot, esconde a janela e sai
	if not tem_item:
		info_item_upgrade.visible = false
		return

	info_item_upgrade.visible = true

	# Pega o item que foi colocado no slot
	var no_slot = $Atualizar/Slot
	var item_arrastado = no_slot.item_atual
	if item_arrastado == null:
		info_item_upgrade.visible = false
		return

	# Identifica o tipo de item
	var tipo_item = item_arrastado.obter_tipo_item()
	var jogador = get_tree().get_current_scene().get_node("Jogador")

	# Descobre o nível atual do item no jogador
	var nivel_atual = 0
	match tipo_item:
		"espada_basica":
			nivel_atual = jogador.nivel_espada
		"lanca_basica":
			nivel_atual = jogador.nivel_lanca
		"escudo_basico":
			nivel_atual = jogador.nivel_escudo
		_:
			info_item_upgrade.visible = false
			return

	var proximo_nivel = nivel_atual + 1
	var instancia_bd_armas = preload("res://Codigos/DadosLocais/Equipamentos.gd").new()
	var dados_proximo = instancia_bd_armas.obter_dados_nivel_arma(tipo_item, proximo_nivel)
	if dados_proximo.size() == 0:
		info_item_upgrade.visible = false
		return

	# Assume que há um nó para exibir o nível, ex.: NIVEL
	var rotulo_nivel = $Atualizar/InfoItemUpgrade/ConteudoTextos/NIVEL
	if rotulo_nivel:
		rotulo_nivel.text = "NV → " + str(proximo_nivel)
		rotulo_nivel.visible = true

	# Nós para os stats
	var rotulo_for = $Atualizar/InfoItemUpgrade/ConteudoTextos/FOR
	var rotulo_dan = $Atualizar/InfoItemUpgrade/ConteudoTextos/DAN
	var rotulo_vit = $Atualizar/InfoItemUpgrade/ConteudoTextos/VIT
	var rotulo_def = $Atualizar/InfoItemUpgrade/ConteudoTextos/DEF

	# Inicializa todos como visíveis e depois ajusta conforme o tipo de item
	rotulo_for.visible = true
	rotulo_dan.visible = true
	rotulo_vit.visible = true
	rotulo_def.visible = true

	match tipo_item:
		"espada_basica", "lanca_basica":
			# Para armas, mostramos FOR e DAN
			rotulo_for.text = "FOR → " + str(dados_proximo.get("bonus_forca", 0))
			rotulo_dan.text = "DAN → " + str(dados_proximo.get("dano", 0))
			# Esconde os rótulos não utilizados
			rotulo_vit.visible = false
			rotulo_def.visible = false
		"escudo_basico":
			# Para escudos, mostramos VIT e DEF (usando "bonus_vitalidade" e "bonus_forca" para defesa, por exemplo)
			rotulo_vit.text = "VIT → " + str(dados_proximo.get("bonus_vitalidade", 0))
			rotulo_def.text = "DEF → " + str(dados_proximo.get("bonus_forca", 0))
			# Esconde os rótulos de armas
			rotulo_for.visible = false
			rotulo_dan.visible = false

func verificar_estado_botao_upgrade() -> void:
	var no_slot = $Atualizar/Slot
	var botao_upgrade = $Atualizar/CliqueUpgrade
	
	if no_slot.item_atual == null:
		# Desabilita o botão se não houver item no slot
		botao_upgrade.disabled = true
		botao_upgrade.modulate = Color(1, 1, 1, 0.5)  # Efeito visual de desabilitado
	else:
		# Habilita o botão se houver um item no slot
		botao_upgrade.disabled = false
		botao_upgrade.modulate = Color(1, 1, 1, 1)  # Normal

func _on_clique_upgrade_pressionado() -> void:
	var no_slot = $Atualizar/Slot
	var item_arrastado = no_slot.item_atual
	if item_arrastado == null:
		print("Não há item no slot para atualizar!")
		return

	var gerenciador_ondas = get_tree().get_root().get_node("cenario/enemySpawner/GerenciadorOndas")
	if not gerenciador_ondas:
		hide()
		return

	var jogador = get_tree().get_current_scene().get_node("Jogador")
	var tipo_item = item_arrastado.obter_tipo_item()
	var nivel_atual = 0
	var proximo_nivel = 0
	var dados_proximo = {}

	var instancia_bd_armas = preload("res://Codigos/DadosLocais/Equipamentos.gd").new()

	match tipo_item:
		"espada_basica":
			nivel_atual = jogador.nivel_espada
			proximo_nivel = nivel_atual + 1
			dados_proximo = instancia_bd_armas.obter_dados_nivel_arma(tipo_item, proximo_nivel)
		"escudo_basico":
			nivel_atual = jogador.nivel_escudo
			proximo_nivel = nivel_atual + 1
			dados_proximo = instancia_bd_armas.obter_dados_nivel_arma(tipo_item, proximo_nivel)
		"lanca_basica":
			nivel_atual = jogador.nivel_lanca
			proximo_nivel = nivel_atual + 1
			dados_proximo = instancia_bd_armas.obter_dados_nivel_arma(tipo_item, proximo_nivel)

	if dados_proximo.size() == 0:
		print("Esse item já está no nível máximo ou não existe no BD.")
		hide()
		return

	var onda_necessaria = dados_proximo.get("onda_necessaria", 9999)

	var botao_upgrade = $Atualizar/CliqueUpgrade
	botao_upgrade.text = "UPGRADE NV %d" % proximo_nivel

	if gerenciador_ondas.onda_atual >= onda_necessaria:
		# Inicia a animação de forja
		jogador.iniciar_forja(tipo_item)
	else:
		print("Onda atual ainda não atinge o requisito:", onda_necessaria)

	await get_tree().create_timer(0.1).timeout
	ao_botao_fechar_pressionado()

func atualizar_texto_botao_upgrade() -> void:
	var no_slot = $Atualizar/Slot
	var item_arrastado = no_slot.item_atual
	var botao_upgrade = $Atualizar/CliqueUpgrade
	var jogador = get_tree().get_current_scene().get_node("Jogador")
	var instancia_bd_armas = preload("res://Codigos/DadosLocais/Equipamentos.gd").new()

	if item_arrastado == null:
		botao_upgrade.text = "UPGRADE"
		return

	var tipo_item = item_arrastado.obter_tipo_item()
	var nivel_atual = 0
	
	match tipo_item:
		"espada_basica":
			nivel_atual = jogador.nivel_espada
		"escudo_basico":
			nivel_atual = jogador.nivel_escudo
		"lanca_basica":
			nivel_atual = jogador.nivel_lanca

	var dados_proximo_nivel = instancia_bd_armas.obter_dados_nivel_arma(tipo_item, nivel_atual + 1)
	if dados_proximo_nivel.size() == 0:
		botao_upgrade.text = "NÍVEL MÁXIMO"
		botao_upgrade.disabled = true
	else:
		botao_upgrade.text = "UPGRADE NV %d" % (nivel_atual + 1)
		botao_upgrade.disabled = false

# Botão para a espada
func _on_espada_pressionado() -> void:
	var jogador = get_tree().get_current_scene().get_node("Jogador")
	if not jogador:
		return
		
	if jogador.usando_lanca:
		jogador.desequipar_lanca()
		$Armas/Lanca/lanca/Texto.text = "EQUIPAR"
		$Armas/Escudo/Escudo.disabled = false
		$Armas/Escudo/Escudo.modulate = Color(1, 1, 1, 1)
		
	if jogador.usando_espada:
		jogador.desequipar_espada()
		$Armas/Braco/espada/Texto.text = "EQUIPAR"
	else:
		jogador.equipar_espada()
		$Armas/Braco/espada/Texto.text = "DESEQUIPAR"
	
	# Atualiza o botão da lança
	$Armas/Lanca/lanca/Texto.text = "EQUIPAR"

# Botão para a lança
func _on_lanca_pressionado() -> void:
	var jogador = get_tree().get_current_scene().get_node("Jogador")
	if not jogador:
		return
		
	if jogador.usando_espada:
		jogador.desequipar_espada()
		$Armas/Braco/espada/Texto.text = "EQUIPAR"
		
	if jogador.usando_lanca:
		jogador.desequipar_lanca()
		$Armas/Lanca/lanca/Texto.text = "EQUIPAR"
		$Armas/Escudo/Escudo.disabled = false
		$Armas/Escudo/Escudo.modulate = Color(1, 1, 1, 1)
	else:
		jogador.equipar_lanca()
		$Armas/Lanca/lanca/Texto.text = "DESEQUIPAR"
		$Armas/Escudo/Escudo.disabled = true
		$Armas/Escudo/Escudo/Texto.text = "EQUIPAR"
		$Armas/Escudo/Escudo.modulate = Color(1, 1, 1, 0.5)
	
	# Atualiza o botão da espada
	$Armas/Braco/espada/Texto.text = "EQUIPAR"

func _on_lanca_gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed:
		_on_lanca_pressionado()

# >>> Botão para o escudo <<<
func _on_escudo_pressionado() -> void:
	var jogador = get_tree().get_current_scene().get_node("Jogador")
	if not jogador:
		return

	# Se quiser que o escudo seja independente (pode ter espada/lança + escudo), NÃO desequipe nada.
	# Se quiser que o escudo seja exclusivo, comente ou adapte como nas funções de espada/lança.

	if jogador.usando_escudo:
		jogador.desequipar_escudo()
		$Armas/Escudo/Escudo/Texto.text = "EQUIPAR"
	else:
		jogador.equipar_escudo()
		$Armas/Escudo/Escudo/Texto.text = "DESEQUIPAR"

	# Se quiser permitir onda também só com o escudo, use a linha abaixo:
	botao_iniciar_onda.disabled = not (jogador.usando_espada or jogador.usando_lanca or jogador.usando_escudo)

	# Se NÃO quiser onda só com escudo, mantenha a forma antiga:
	# botao_iniciar_onda.disabled = not (jogador.usando_espada or jogador.usando_lanca)

func _on_fechar_modal_pressionado() -> void:
	ao_botao_fechar_pressionado()

func _on_equipamento_jogador_alterado() -> void:
	# Atualiza a interface quando o equipamento do jogador muda
	pass

func _on_area_2d_area_entrou(area: Area2D) -> void:
	# Lógica quando uma área entra
	pass

func _on_area_2d_area_saiu(area: Area2D) -> void:
	# Lógica quando uma área sai
	pass
