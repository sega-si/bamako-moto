class_name Ciel
extends RefCounted

## Le jour qui tombe.
##
## Personne ne s'y attend dans un jeu de ce genre : on court, et au bout
## d'un moment le soleil descend, le ciel rougit, puis la nuit tombe et les
## phares s'allument. C'est gratuit — rien que des couleurs qu'on
## interpole — et c'est ce qui recompense une longue partie autrement que
## par un chiffre qui monte.

## Distance a laquelle le soleil commence a descendre, et celle a laquelle
## il fait nuit noire.
const DEBUT := 700.0
const FIN := 1900.0

const JOUR := {
	"haut": Color(0.11, 0.42, 0.88),
	"horizon": Color(0.62, 0.80, 0.94),
	"sol": Color(0.86, 0.55, 0.30),
	"brume": Color(0.72, 0.84, 0.94),
	"soleil": Color(1.0, 0.96, 0.86),
	"puissance": 1.15,
	"ambiance": 1.0,
	"angle": -52.0,
}

const CREPUSCULE := {
	"haut": Color(0.24, 0.26, 0.55),
	"horizon": Color(0.96, 0.52, 0.22),
	"sol": Color(0.58, 0.28, 0.18),
	"brume": Color(0.86, 0.50, 0.30),
	"soleil": Color(1.0, 0.68, 0.40),
	"puissance": 0.95,
	"ambiance": 0.75,
	"angle": -12.0,
}

const NUIT := {
	"haut": Color(0.03, 0.04, 0.13),
	"horizon": Color(0.10, 0.12, 0.26),
	"sol": Color(0.08, 0.06, 0.08),
	"brume": Color(0.07, 0.08, 0.18),
	"soleil": Color(0.55, 0.62, 0.90),
	"puissance": 0.28,
	"ambiance": 0.30,
	"angle": 26.0,
}


## Renvoie l'avancee de la nuit, de 0 (plein jour) a 1 (nuit noire).
static func avancee(distance: float) -> float:
	return clampf((distance - DEBUT) / (FIN - DEBUT), 0.0, 1.0)


static func _melanger(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	var r := {}
	for cle in a:
		if a[cle] is Color:
			r[cle] = (a[cle] as Color).lerp(b[cle], t)
		else:
			r[cle] = lerpf(float(a[cle]), float(b[cle]), t)
	return r


## Applique l'heure qu'il est au ciel, a la brume et au soleil.
static func appliquer(environnement: Environment, soleil: DirectionalLight3D,
		t: float) -> void:
	# Deux etapes : le jour vire au crepuscule, puis le crepuscule a la
	# nuit. Un seul melange du jour vers la nuit sauterait l'orange, qui
	# est justement le plus beau moment.
	var etat: Dictionary
	if t < 0.5:
		etat = _melanger(JOUR, CREPUSCULE, t * 2.0)
	else:
		etat = _melanger(CREPUSCULE, NUIT, (t - 0.5) * 2.0)

	var materiau := environnement.sky.sky_material as ProceduralSkyMaterial
	materiau.sky_top_color = etat["haut"]
	materiau.sky_horizon_color = etat["horizon"]
	materiau.ground_horizon_color = etat["sol"]
	environnement.fog_light_color = etat["brume"]
	environnement.ambient_light_energy = etat["ambiance"]

	soleil.light_color = etat["soleil"]
	soleil.light_energy = etat["puissance"]
	soleil.rotation_degrees.x = etat["angle"]
	# Sous l'horizon, le soleil n'eclaire plus : on coupe ses ombres, qui
	# seraient absurdes et couteuses pour rien.
	soleil.shadow_enabled = t < 0.85
