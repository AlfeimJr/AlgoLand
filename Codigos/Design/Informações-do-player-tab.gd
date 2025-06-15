extends CanvasLayer

func _ready() -> void:
	$InformacaoPersonagem.visible = false

func _process(_delta: float) -> void:
	if Input.is_action_pressed("show_stats"):
		$InformacaoPersonagem.visible = true
		atualizar_menu()
	else:
		$InformacaoPersonagem.visible = false

func atualizar_menu() -> void:
	var jogador = get_tree().get_root().get_node("cenario/Jogador")
	if jogador == null:
		return

	# --- Atualizar Estatísticas do Jogador (em um GridContainer) ---
	for filho in $InformacaoPersonagem/StatusJogador.get_children():
		filho.queue_free()

	var array_estatisticas = [
		"FOR: " + str(jogador.stats.forca),
		"AGI: " + str(jogador.stats.agilidade),
		"VIT: " + str(jogador.stats.vitalidade),
		"INT: " + str(jogador.stats.inteligencia),
		"SOR: " + str(jogador.stats.sorte),
		"DEF: " + str(jogador.stats.defesa),
		"DAN: " + str(jogador.stats.dano_ataque)
	]

	var arquivo_fonte: FontFile = load("res://UI/Planes_ValMore.ttf") as FontFile

	for linha_estatistica in array_estatisticas:
		var rotulo = Label.new()
		rotulo.text = linha_estatistica
		
		rotulo.add_theme_font_override("font", arquivo_fonte)
		rotulo.add_theme_font_size_override("font_size", 8)  # Tamanho definido aqui
		rotulo.add_theme_color_override("font_color", Color.WHITE)
		rotulo.add_theme_constant_override("line_spacing", 3)
		
		rotulo.add_theme_color_override("shadow_color", Color.BLACK)
		rotulo.add_theme_constant_override("shadow_size", 1)
		rotulo.add_theme_constant_override("shadow_offset_x", 1)
		rotulo.add_theme_constant_override("shadow_offset_y", 1)
		
		$InformacaoPersonagem/StatusJogador.add_child(rotulo)

	# --- Atualizar Itens Comprados (em outro GridContainer) ---
	for filho in $InformacaoPersonagem/FundoItensComprados/ItensComprados.get_children():
		filho.queue_free()

	if jogador.itens_comprados.size() > 0:
		var cena_item = preload("res://cenas/item.tscn")
		for dados_item in jogador.itens_comprados:
			var instancia_item = cena_item.instantiate()
			instancia_item.definir_dados_item(dados_item)
			$InformacaoPersonagem/FundoItensComprados/ItensComprados.add_child(instancia_item)
	else:
		var rotulo_vazio = Label.new()
		rotulo_vazio.text = "NENHUM ITEM COMPRADO"
		rotulo_vazio.add_theme_font_override("font", arquivo_fonte)
		rotulo_vazio.add_theme_font_size_override("font_size", 8)  # Adicione aqui também
		rotulo_vazio.add_theme_color_override("font_color", Color.WHITE)
		$InformacaoPersonagem/FundoItensComprados/ItensComprados.add_child(rotulo_vazio)
