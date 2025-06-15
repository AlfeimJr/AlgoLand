# EstatisticasJogador.gd
# ====================
# Esta classe calcula os atributos derivados (HP, Defesa, etc.) a partir dos atributos básicos.
# Ajustamos a Defesa para ser = vitalidade em vez de vitalidade * 2.

class_name EstatisticasJogador

# Atributos básicos
var forca: int = 5 
var agilidade: int = 5     
var vitalidade: int = 5     
var inteligencia: int = 5   
var sorte: int = 5          

# Atributos de movimento
var velocidade_base_movimento: float = 114.0  # Velocidade base sem bônus
var bonus_velocidade_item: float = 0.0   # Bônus de velocidade adquirido via itens
var velocidade_movimento: float = velocidade_base_movimento

# Atributos derivados
var hp_maximo: int           
var dano_ataque: int    
var chance_critico: float 
var dano_critico: float  
var defesa: int            

func calcular_estatisticas_derivadas(arma_equipada: bool = false):
	# Ajusta HP
	hp_maximo = vitalidade * 20

	# Ajusta dano
	dano_ataque = forca * 2

	# Ajusta crítico
	chance_critico = min(0.05 + sorte * 0.01, 1.0)
	dano_critico = 1.5 + sorte * 0.05

	# Velocidade final (sem alteração aqui)
	velocidade_movimento = velocidade_base_movimento + bonus_velocidade_item + agilidade * 0.5

	# **Mudança principal**: defesa agora = vitalidade (antes era vitalidade * 2)
	defesa = vitalidade

# Função para adicionar bônus de velocidade sem zerar valores anteriores
func adicionar_bonus_velocidade(quantidade: float, arma_equipada: bool = false) -> void:
	bonus_velocidade_item += quantidade
	calcular_estatisticas_derivadas(arma_equipada)
