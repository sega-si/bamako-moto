extends Area3D

## Un bidon d'essence a ramasser.
##
## Il donne une charge de turbo. C'est la recompense la plus satisfaisante
## qu'un jeu de ce genre puisse offrir : pendant quelques secondes on ne
## craint plus rien et on traverse la circulation au lieu de l'eviter.

signal ramasse

var vitesse_du_jeu: float = 20.0

var _visuel: Node3D
var _temps: float = 0.0


func _ready() -> void:
	_visuel = Fabrique.bidon()
	add_child(_visuel)

	var forme := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.95
	forme.shape = sphere
	add_child(forme)

	area_entered.connect(func(_a: Area3D) -> void:
		ramasse.emit()
		queue_free())


func _process(delta: float) -> void:
	position.z += vitesse_du_jeu * delta
	_temps += delta
	# Il tourne et flotte : deux mouvements valent mieux qu'un pour
	# accrocher l'oeil au milieu d'une route qui defile.
	_visuel.rotation_degrees.y += 150.0 * delta
	_visuel.position.y = sin(_temps * 3.0) * 0.18

	if position.z > 16.0:
		queue_free()
