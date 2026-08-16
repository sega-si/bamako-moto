extends Area3D

## Une piece a ramasser.
##
## C'est elle qui change la nature du jeu. Sans elle, le joueur n'a qu'une
## consigne — eviter — et il se contente de rester sur la voie la plus
## vide. Les pieces lui donnent une raison d'aller la ou c'est risque.

signal ramassee(position_monde: Vector3)

var vitesse_du_jeu: float = 20.0

var _visuel: Node3D


func _ready() -> void:
	_visuel = Fabrique.piece()
	add_child(_visuel)

	var forme := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	# Genereuse : rater une piece de peu est frustrant sans etre
	# instructif, contrairement a rater un vehicule.
	sphere.radius = 0.85
	forme.shape = sphere
	add_child(forme)

	area_entered.connect(_sur_contact)


func _sur_contact(_autre: Area3D) -> void:
	ramassee.emit(global_position)
	queue_free()


func _process(delta: float) -> void:
	position.z += vitesse_du_jeu * delta
	# Elle tourne sur elle-meme : c'est ce qui l'accroche du coin de l'oeil
	# alors qu'elle ne fait qu'un demi-metre.
	_visuel.rotation_degrees.y += 220.0 * delta

	if position.z > 16.0:
		queue_free()
