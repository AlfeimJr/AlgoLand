extends CanvasItem  # Se for um TextureRect ou Label

func _ready():
	hide()  # Começa escondido

func show_wave_number(wave: int):
	$WaveLabel.text = str(wave)  # Define o número da wave (caso tenha um Label no meio)
	show()  # Torna visível
	await get_tree().create_timer(2.0).timeout  # Espera 2 segundos
	hide()  # Esconde novamente
