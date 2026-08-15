extends Node

## Verification automatique : la moto se jette volontairement sur le
## premier vehicule venu, et on controle que la partie s'arrete.
##
## Une capture d'ecran ne montre pas si une collision fonctionne. Ce test
## le prouve, et il se rejoue apres chaque modification du gabarit des
## vehicules ou des couches de collision.

const DELAI_MAXIMAL := 25.0

var _jeu: Node3D
var _temps := 0.0
var _vise: Node3D = null


func _ready() -> void:
	_jeu = load("res://scenes/jeu.tscn").instantiate()
	add_child(_jeu)


func _process(delta: float) -> void:
	_temps += delta

	if not _jeu.en_cours:
		print("RESULTAT : collision detectee apres %.1f s, distance %d m"
				% [_temps, int(_jeu.distance)])
		get_tree().quit(0)
		return

	if _temps > DELAI_MAXIMAL:
		push_error("ECHEC : aucune collision en %d s alors que la moto "
				% int(DELAI_MAXIMAL) + "s'est placee devant les vehicules.")
		get_tree().quit(1)
		return

	# On vise le vehicule le plus proche encore devant nous, et on aligne
	# la moto sur sa voie.
	var obstacles: Array = _jeu.get_node("Obstacles").get_children()
	if obstacles.is_empty():
		return

	if _vise == null or not is_instance_valid(_vise) or _vise.position.z > 0.0:
		_vise = null
		var plus_proche := -1000.0
		for o in obstacles:
			if o.position.z < -6.0 and o.position.z > plus_proche:
				plus_proche = o.position.z
				_vise = o

	if _vise != null and is_instance_valid(_vise):
		_jeu.get_node("Moto").position.x = _vise.position.x
